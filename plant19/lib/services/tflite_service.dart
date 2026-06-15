import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/diagnosis_result.dart';
import 'package:flutter/material.dart';
class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _plantInterpreter;
  Interpreter? _diseaseInterpreter;
  List<String> _labels = [];

  bool get isInitialized =>
      _plantInterpreter != null && _diseaseInterpreter != null;

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      debugPrint('🔄 جاري تحميل الموديلات...');
      _plantInterpreter =
          await Interpreter.fromAsset('assets/models/plant_classifier.tflite');
      _diseaseInterpreter =
          await Interpreter.fromAsset('assets/models/disease_detector.tflite');

      // تحميل الـ labels
      final labelsContent = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();

      debugPrint('✅ تم تحميل ${_labels.length} تصنيف بنجاح.');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الموديلات أو الليبلز: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // الموديل الأول: هل ده نبات؟ (مُصحح لـ [1, 1])
  // ═══════════════════════════════════════════════════
  Future<DiagnosisResult> checkIfPlant(File imageFile) async {
    if (_plantInterpreter == null)
      throw Exception('Plant classifier not initialized');

    final input = await _preprocessImage(imageFile, size: 224);

    // ← التصحيح الجوهري: الموديل بيرجع output shape [1, 1] مش [1, 2]
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _plantInterpreter!.run(input, output);

    final plantProb = output[0][0];
    final isPlant = plantProb >= 0.5;

    debugPrint(
        '🌱 موديل النبات: prob=${plantProb.toStringAsFixed(2)}, isPlant=$isPlant');

    return DiagnosisResult(
      isPlant: isPlant,
      plantConfidence: plantProb,
    );
  }

  // ═══════════════════════════════════════════════════
  // الموديل التاني: التشخيص (38 كلاس)
  // ═══════════════════════════════════════════════════
  Future<DiagnosisResult> diagnoseDisease(File imageFile) async {
    if (_diseaseInterpreter == null)
      throw Exception('Disease detector not initialized');

    final input = await _preprocessImage(imageFile, size: 224);
    final output = List.filled(1 * 38, 0.0).reshape([1, 38]);

    _diseaseInterpreter!.run(input, output);

    final probs = output[0] as List<double>;
    int maxIndex = 0;
    double maxProb = probs[0];

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    final className = _labels[maxIndex];
    final isHealthy = className.toLowerCase().contains('healthy');
    final parts = className.split('___');
    final plantName = _translatePlantName(parts[0]);
    final diseaseName = isHealthy ? 'سليم' : parts[1].replaceAll('_', ' ');

    debugPrint(
        '🦠 موديل الأمراض: class=$className, conf=${(maxProb * 100).toStringAsFixed(2)}%');

    return DiagnosisResult(
      isPlant: true,
      plantConfidence: 1.0,
      diseaseClass: className,
      diseaseConfidence: maxProb,
      isHealthy: isHealthy,
      plantName: plantName,
      diseaseName: diseaseName,
    );
  }

  // ═══════════════════════════════════════════════════
  // معالجة الصورة (Null-Safe + Normalization [-1, 1])
  // ═══════════════════════════════════════════════════
  Future<List<List<List<List<double>>>>> _preprocessImage(
    File imageFile, {
    required int size,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) throw Exception('Failed to decode image');

    img.Image image = decoded;

    // إزالة قناة الشفافية (Alpha)
    if (image.hasAlpha) {
      final rgbImage = img.Image(width: image.width, height: image.height);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          rgbImage.setPixelRgb(x, y, p.r, p.g, p.b);
        }
      }
      image = rgbImage;
    }

    // Resize عالي الجودة
    image = img.copyResize(
      image,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );

    // تحويل لـ Tensor [1][224][224][3] + Normalization [-1, 1]
    // ⚠️ لو الموديل متدرب على [0, 1] غيّر المعادلة لـ: p.r / 255.0
    final input = List.generate(
      1,
      (_) => List.generate(
        size,
        (y) => List.generate(
          size,
          (x) {
            final p = image.getPixel(x, y);
            return [
              (p.r / 127.5) - 1,
              (p.g / 127.5) - 1,
              (p.b / 127.5) - 1,
            ];
          },
        ),
      ),
    );

    return input;
  }

  String _translatePlantName(String english) {
    final map = {
      'Apple': 'تفاح',
      'Blueberry': 'توت أزرق',
      'Cherry_(including_sour)': 'كرز',
      'Corn_(maize)': 'ذرة',
      'Grape': 'عنب',
      'Orange': 'برتقال',
      'Peach': 'خوخ',
      'Pepper,_bell': 'فلفل رومي',
      'Potato': 'بطاطس',
      'Raspberry': 'توت العليق',
      'Soybean': 'فول صويا',
      'Squash': 'قرع',
      'Strawberry': 'فراولة',
      'Tomato': 'طماطم',
    };
    return map[english] ?? english;
  }

  void dispose() {
    _plantInterpreter?.close();
    _diseaseInterpreter?.close();
  }
}
