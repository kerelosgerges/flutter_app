import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
// 👈 ضروري عشان الـ Float32List السريعة

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WeedScreen extends StatefulWidget {
  const WeedScreen({super.key});

  @override
  State<WeedScreen> createState() => _WeedScreenState();
}

class _WeedScreenState extends State<WeedScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _radarController;

  CameraController? _cameraController;
  Interpreter? _interpreter;

  bool _isCameraActive = false;
  bool _isDetecting = false;
  DateTime _lastInferenceTime = DateTime.fromMillisecondsSinceEpoch(0);

  String? _detectedWeedId;
  Map<String, dynamic>? _detectedWeedProtocol;
  List<dynamic> _weedsDatabase = [];

  List<Map<String, dynamic>> _recognitions = [];
  int _imageHeight = 0;
  int _imageWidth = 0;

  int _modelInputSize = 640;
  List<int> _outputShape = [1, 300, 6];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    try {
      final String response = await rootBundle.loadString('assets/weeds.json');
      final data = json.decode(response);
      _weedsDatabase = data['weeds_protocols'] ?? [];

      // 👈 تفعيل الـ Turbo (استخدام 4 أنوية لتسريع الموديل)
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/weed_detector_float16.tflite',
        options: options,
      );

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;

      if (inputShape.length == 4) {
        if (inputShape[1] == 3) {
          _modelInputSize = inputShape[2];
        } else {
          _modelInputSize = inputShape[1];
        }
      }

      debugPrint('✅ تم تحميل الموديل بنجاح');
      debugPrint(
          'Input shape: ${inputTensor.shape}, type: ${inputTensor.type}');
      debugPrint(
          'Output shape: ${outputTensor.shape}, type: ${outputTensor.type}');
    } catch (e) {
      debugPrint('❌ خطأ في التحميل: $e');
    }
  }

  Future<void> _startCamera() async {
    HapticFeedback.mediumImpact();

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint('❌ لا توجد كاميرا متاحة');
        return;
      }

      setState(() {
        _isCameraActive = true;
        _recognitions = [];
        _detectedWeedId = null;
        _detectedWeedProtocol = null;
      });

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low, // 👈 الجودة المنخفضة لتسريع المعالجة
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {});

      await _cameraController!.startImageStream((CameraImage image) {
        final now = DateTime.now();

        // 👈 الفرامل: استراحة 600 ملي ثانية بين كل فريم لعدم تجميد الواجهة
        if (_isDetecting ||
            now.difference(_lastInferenceTime).inMilliseconds < 600) {
          return;
        }

        _lastInferenceTime = now;
        _isDetecting = true;
        _runInference(image);
      });
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الكاميرا: $e');

      if (!mounted) return;
      setState(() {
        _isCameraActive = false;
        _recognitions = [];
        _detectedWeedId = null;
        _detectedWeedProtocol = null;
      });
    }
  }

  Future<void> _runInference(CameraImage image) async {
    if (_interpreter == null) {
      _isDetecting = false;
      return;
    }

    try {
      // 👈 استخدام الـ Float32List السريعة بدلاً من المصفوفات المعقدة
      final Float32List flatInput =
          await _preprocessCameraImage(image, _modelInputSize);
      final inputTensor =
          flatInput.reshape([1, _modelInputSize, _modelInputSize, 3]);
      final outputTensor = _createOutputBuffer(_outputShape);

      _interpreter!.run(inputTensor, outputTensor);

      final recognitions = _parseYoloOutput(
        outputTensor: outputTensor,
        cameraImageWidth: image.width,
        cameraImageHeight: image.height,
        inputSize: _modelInputSize,
      );

      _updateDetections(recognitions, image.height, image.width);
    } catch (e) {
      debugPrint('Error in inference: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _isDetecting = false;
        }
      });
    }
  }

  Future<Float32List> _preprocessCameraImage(
    CameraImage image,
    int inputSize,
  ) async {
    if (Platform.isAndroid) {
      return compute(_androidYuv420ToModelInput, {
        'width': image.width,
        'height': image.height,
        'y': image.planes[0].bytes,
        'u': image.planes[1].bytes,
        'v': image.planes[2].bytes,
        'yRowStride': image.planes[0].bytesPerRow,
        'yPixelStride': image.planes[0].bytesPerPixel ?? 1,
        'uvRowStride': image.planes[1].bytesPerRow,
        'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
        'inputSize': inputSize,
      });
    }

    return compute(_bgra8888ToModelInput, {
      'width': image.width,
      'height': image.height,
      'bytes': image.planes[0].bytes,
      'bytesPerRow': image.planes[0].bytesPerRow,
      'inputSize': inputSize,
    });
  }

  dynamic _createOutputBuffer(List<int> shape) {
    dynamic build(int depth) {
      final length = shape[depth];

      if (depth == shape.length - 1) {
        return List<double>.filled(length, 0.0);
      }

      return List.generate(length, (_) => build(depth + 1));
    }

    return build(0);
  }

  List<Map<String, dynamic>> _parseYoloOutput({
    required dynamic outputTensor,
    required int cameraImageWidth,
    required int cameraImageHeight,
    required int inputSize,
  }) {
    final List<Map<String, dynamic>> recognitions = [];

    dynamic detections = outputTensor;

    if (detections is List && detections.length == 1) {
      detections = detections[0];
    }

    if (detections is! List || detections.isEmpty) {
      return recognitions;
    }

    // Expected: [300, 6] => xMin, yMin, xMax, yMax, confidence, classId
    if (detections.first is List && (detections.first as List).length >= 6) {
      for (final row in detections) {
        if (row is! List || row.length < 6) continue;

        _addDetectionIfValid(
          recognitions: recognitions,
          row: row,
          cameraImageWidth: cameraImageWidth,
          cameraImageHeight: cameraImageHeight,
          inputSize: inputSize,
        );
      }
    } else if (detections.length >= 6 && detections[0] is List) {
      final int count = (detections[0] as List).length;

      for (int i = 0; i < count; i++) {
        final row = [
          detections[0][i],
          detections[1][i],
          detections[2][i],
          detections[3][i],
          detections[4][i],
          detections[5][i],
        ];

        _addDetectionIfValid(
          recognitions: recognitions,
          row: row,
          cameraImageWidth: cameraImageWidth,
          cameraImageHeight: cameraImageHeight,
          inputSize: inputSize,
        );
      }
    }

    recognitions.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    return recognitions.take(10).toList();
  }

  void _addDetectionIfValid({
    required List<Map<String, dynamic>> recognitions,
    required List<dynamic> row,
    required int cameraImageWidth,
    required int cameraImageHeight,
    required int inputSize,
  }) {
    final double rawX1 = _toDouble(row[0]);
    final double rawY1 = _toDouble(row[1]);
    final double rawX2 = _toDouble(row[2]);
    final double rawY2 = _toDouble(row[3]);
    final double confidence = _toDouble(row[4]);
    final int classId = _toDouble(row[5]).round();

    if (confidence < 0.50) return;
    if (classId < 0 || classId > 5) return;

    final double maxCoordinate = [
      rawX1,
      rawY1,
      rawX2,
      rawY2,
    ].map((value) => value.abs()).reduce(math.max);

    final bool normalized = maxCoordinate <= 1.5;

    final double xScale =
        normalized ? cameraImageWidth.toDouble() : cameraImageWidth / inputSize;
    final double yScale = normalized
        ? cameraImageHeight.toDouble()
        : cameraImageHeight / inputSize;

    double left = rawX1 * xScale;
    double top = rawY1 * yScale;
    double right = rawX2 * xScale;
    double bottom = rawY2 * yScale;

    if (right < left) {
      final temp = left;
      left = right;
      right = temp;
    }

    if (bottom < top) {
      final temp = top;
      top = bottom;
      bottom = temp;
    }

    left = left.clamp(0.0, cameraImageWidth.toDouble());
    right = right.clamp(0.0, cameraImageWidth.toDouble());
    top = top.clamp(0.0, cameraImageHeight.toDouble());
    bottom = bottom.clamp(0.0, cameraImageHeight.toDouble());

    if ((right - left) < 4 || (bottom - top) < 4) return;

    recognitions.add({
      'rect': Rect.fromLTRB(left, top, right, bottom),
      'confidence': confidence,
      'classLabel': _getClassName(classId),
      'displayName': _getDisplayName(classId),
    });
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _updateDetections(
      List<Map<String, dynamic>> recognitions, int h, int w) {
    if (!mounted) return;

    setState(() {
      _recognitions = recognitions;
      _imageHeight = h;
      _imageWidth = w;

      if (recognitions.isEmpty) {
        _detectedWeedId = null;
        _detectedWeedProtocol = null;
      }
    });

    if (recognitions.isEmpty) return;

    final bestDetection = recognitions.reduce(
      (curr, next) => curr['confidence'] > next['confidence'] ? curr : next,
    );

    if (bestDetection['confidence'] > 0.60) {
      _onWeedDetected(bestDetection['classLabel']);
    }
  }

  void _onWeedDetected(String yoloClassName) {
    if (_detectedWeedId == yoloClassName) return;

    Map<String, dynamic>? protocol;

    for (final weed in _weedsDatabase) {
      if (weed is Map && weed['class_name'] == yoloClassName) {
        protocol = Map<String, dynamic>.from(weed);
        break;
      }
    }

    if (protocol != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _detectedWeedId = yoloClassName;
        _detectedWeedProtocol = protocol;
      });
    }
  }

  String _getClassName(int id) {
    switch (id) {
      case 0:
        return 'weed: taraxacum officinale';
      case 1:
        return 'weed: erigeron bonariensis';
      case 2:
        return 'weed: sonchus oleraceus';
      case 3:
        return 'weed: lolium rigidum';
      case 4:
        return 'weed: rapistrum rugosum';
      case 5:
        return 'weed: raphanus raphanistrum';
      default:
        return 'Unknown';
    }
  }

  String _getDisplayName(int id) {
    switch (id) {
      case 0:
        return 'الهندباء البرية';
      case 1:
        return 'السعدانة البوناري';
      case 2:
        return 'الجعضيض';
      case 3:
        return 'الزوان الصلب';
      case 4:
        return 'اللفت البري';
      case 5:
        return 'الفجل البري';
      default:
        return 'حشيشة غير معروفة';
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _radarController.dispose();

    try {
      _cameraController?.stopImageStream();
    } catch (_) {}

    _cameraController?.dispose();
    _interpreter?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/soil_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha:0.5),
                  Colors.black.withValues(alpha:0.3),
                  Colors.black.withValues(alpha:0.6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                const Spacer(),
                if (!_isCameraActive)
                  _buildCenterContent()
                else
                  _buildCameraView(),
                const Spacer(),
                if (!_isCameraActive) _buildActionButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isCameraActive && _detectedWeedProtocol != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _showTreatmentProtocol(
                  context,
                  _detectedWeedProtocol!,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha:0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم كشف: ${_detectedWeedProtocol!['name_ar']}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'عرض بروتوكول الإبادة',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .slideY(
                    begin: 1,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'كشف الحشائش',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha:0.2), width: 2),
          ),
          child: const Icon(Icons.radar_rounded, size: 64, color: Colors.white),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'كشف الحشائش',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 10),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'وجّه الكاميرا نحو الحقل\nوسنكتشف الحشائش الموجودة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.white.withValues(alpha:0.85),
              height: 1.6,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 6),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE65100)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.85,
      height: size.height * 0.55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha:0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            if (_recognitions.isNotEmpty)
              CustomPaint(
                painter: BoundingBoxPainter(
                  recognitions: _recognitions,
                  imageHeight: _imageHeight,
                  imageWidth: _imageWidth,
                ),
              ),
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Positioned(
                  top: _radarController.value * (size.height * 0.53),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFFE65100),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withValues(alpha:0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _startCamera,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatController.value * 6),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6F00), Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha:0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'افتح الكاميرا',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  void _showTreatmentProtocol(
      BuildContext context, Map<String, dynamic> protocol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1F0D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    protocol['name_ar'],
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    protocol['growth_cycle'],
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: const Color(0xFF81C784),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE53935).withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(
                          Icons.dangerous_rounded,
                          color: Color(0xFFE53935),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            protocol['warning'],
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  Text(
                    'أساليب المكافحة',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (protocol['treatment']['selective_herbicide'] != null)
                    _buildTreatmentCard(
                      'مبيدات اختيارية',
                      Icons.science_rounded,
                      const Color(0xFF4CAF50),
                      protocol['treatment']['selective_herbicide'],
                    ).animate().slideX(begin: 0.2, end: 0, delay: 300.ms),
                  if (protocol['treatment']['selective_herbicide_for_wheat'] !=
                      null)
                    _buildTreatmentCard(
                      'مبيدات لمحصول القمح',
                      Icons.grass_rounded,
                      const Color(0xFF4CAF50),
                      protocol['treatment']['selective_herbicide_for_wheat'],
                    ).animate().slideX(begin: 0.2, end: 0, delay: 350.ms),
                  if (protocol['treatment']['non_selective_herbicide'] != null)
                    _buildTreatmentCard(
                      'مبيدات غير اختيارية',
                      Icons.warning_amber_rounded,
                      Colors.orange,
                      protocol['treatment']['non_selective_herbicide'],
                    ).animate().slideX(begin: 0.2, end: 0, delay: 400.ms),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      '⏱️ التوقيت الأمثل', protocol['treatment']['timing']),
                  const Divider(color: Colors.white24, height: 24),
                  _buildInfoRow('🧑‍🌾 المكافحة اليدوية',
                      protocol['treatment']['manual_control']),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTreatmentCard(
    String title,
    IconData icon,
    Color color,
    List<dynamic> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Expanded(
                    child: RichText(
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '${item['ingredient']} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF81C784),
                            ),
                          ),
                          TextSpan(
                            text: '(${item['commercial_name']}): ',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          TextSpan(text: item['usage']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final int imageHeight;
  final int imageWidth;

  BoundingBoxPainter({
    required this.recognitions,
    required this.imageHeight,
    required this.imageWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final paintBox = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final paintBg = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha:0.8)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final recognition in recognitions) {
      final rect = recognition['rect'] as Rect;
      final confidence = recognition['confidence'] as double;
      final label = recognition['displayName'] ?? recognition['classLabel'];

      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, paintBox);

      final textSpan = TextSpan(
        text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: size.width);

      final labelLeft =
          scaledRect.left.clamp(0.0, size.width - textPainter.width - 8);
      final labelTop = math.max(0.0, scaledRect.top - 22);

      final bgRect = Rect.fromLTWH(
        labelLeft,
        labelTop,
        textPainter.width + 8,
        22,
      );

      canvas.drawRect(bgRect, paintBg);
      textPainter.paint(canvas, Offset(labelLeft + 4, labelTop + 1));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return true;
  }
}

// ═══════════════════════════════════════════════════
// دوال المعالجة السريعة المنفصلة (خارج الكلاس)
// ═══════════════════════════════════════════════════

Float32List _androidYuv420ToModelInput(
  Map<String, dynamic> args,
) {
  final int width = args['width'];
  final int height = args['height'];
  final int inputSize = args['inputSize'];

  final Uint8List yBuffer = args['y'];
  final Uint8List uBuffer = args['u'];
  final Uint8List vBuffer = args['v'];

  final int yRowStride = args['yRowStride'];
  final int yPixelStride = args['yPixelStride'];
  final int uvRowStride = args['uvRowStride'];
  final int uvPixelStride = args['uvPixelStride'];

  final rgbImage = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    final int uvRow = y >> 1;

    for (int x = 0; x < width; x++) {
      final int uvCol = x >> 1;

      final int yIndex = y * yRowStride + x * yPixelStride;
      final int uvIndex = uvRow * uvRowStride + uvCol * uvPixelStride;

      final int yValue = yBuffer[yIndex] & 0xff;
      final int uValue = uBuffer[uvIndex] & 0xff;
      final int vValue = vBuffer[uvIndex] & 0xff;

      final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
      final int g =
          (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
              .round()
              .clamp(0, 255);
      final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

      rgbImage.setPixelRgb(x, y, r, g, b);
    }
  }

  final resized = img.copyResize(
    rgbImage,
    width: inputSize,
    height: inputSize,
    interpolation: img.Interpolation.linear,
  );

  return _imageToNormalizedTensor(resized, inputSize);
}

Float32List _bgra8888ToModelInput(
  Map<String, dynamic> args,
) {
  final int width = args['width'];
  final int height = args['height'];
  final int inputSize = args['inputSize'];
  final int bytesPerRow = args['bytesPerRow'];
  final Uint8List bytes = args['bytes'];

  final rgbImage = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int index = y * bytesPerRow + x * 4;

      final int b = bytes[index] & 0xff;
      final int g = bytes[index + 1] & 0xff;
      final int r = bytes[index + 2] & 0xff;

      rgbImage.setPixelRgb(x, y, r, g, b);
    }
  }

  final resized = img.copyResize(
    rgbImage,
    width: inputSize,
    height: inputSize,
    interpolation: img.Interpolation.linear,
  );

  return _imageToNormalizedTensor(resized, inputSize);
}

Float32List _imageToNormalizedTensor(
  img.Image image,
  int inputSize,
) {
  final Float32List flatList = Float32List(1 * inputSize * inputSize * 3);
  int index = 0;
  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      final pixel = image.getPixel(x, y);

      flatList[index++] = pixel.r / 255.0;
      flatList[index++] = pixel.g / 255.0;
      flatList[index++] = pixel.b / 255.0;
    }
  }
  return flatList;
}
