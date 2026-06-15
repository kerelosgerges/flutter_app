import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/tflite_service.dart';
import '../services/protocol_service.dart';
import '../models/diagnosis_result.dart';
import 'error_screen.dart';
import 'healthy_result_screen.dart';
import 'disease_result_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final File imageFile;
  const AnalyzingScreen({super.key, required this.imageFile});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  int _currentStep = 0;
  int _progress = 0;
  final List<String> _steps = [
    'جاري فحص الورقة',
    'تحليل الألوان والأنماط',
    'البحث عن علامات المرض',
    'إعداد التقرير النهائي',
  ];
  // ✅ FIX: شيلنا _stepIcons — كان unused field وبيعمل warning

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startAnalysis();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final tflite = TFLiteService();
    try {
      if (!tflite.isInitialized) await tflite.initialize();
      if (ProtocolService.protocols == null)
        await ProtocolService.loadProtocols();

      for (int i = 0; i < 4; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() => _currentStep = i);
        for (int p = 0; p <= 25; p++) {
          await Future.delayed(const Duration(milliseconds: 30));
          if (!mounted) return;
          setState(() => _progress = (i * 25) + p);
        }
      }

      final plantRes = await tflite.checkIfPlant(widget.imageFile);
      if (!mounted) return;
      if (!plantRes.isPlant || plantRes.plantConfidence < 0.5) {
        _goToError();
        return;
      }

      final diseaseRes = await tflite.diagnoseDisease(widget.imageFile);
      if (!mounted) return;
      if (diseaseRes.diseaseConfidence! < 0.30) {
        _goToError();
        return;
      }

      if (!mounted) return;
      diseaseRes.isHealthy
          ? _goToHealthy(diseaseRes)
          : _goToDisease(diseaseRes);
    } catch (e) {
      debugPrint('❌ تحليل فشل: $e');
      if (mounted) _goToError();
    }
  }

  void _goToError() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ErrorScreen()),
      );

  void _goToHealthy(DiagnosisResult r) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HealthyResultScreen(
            plantName: r.plantName ?? 'نبات',
            confidence: r.diseaseConfidence ?? 0.0,
            imageFile: widget.imageFile,
          ),
        ),
      );

  void _goToDisease(DiagnosisResult r) {
    final proto = ProtocolService.getProtocol(r.diseaseClass!);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DiseaseResultScreen(
          plantName: r.plantName ?? 'نبات',
          diseaseName: r.diseaseName ?? 'مرض',
          diseaseClass: r.diseaseClass ?? '',
          confidence: r.diseaseConfidence ?? 0.0,
          imageFile: widget.imageFile,
          protocol: proto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // صورة مع خط المسح
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(widget.imageFile, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // ✅ FIX: withOpacity → withValues
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (_, __) => Positioned(
                      top: _scanController.value * 277,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF4CAF50),
                              Colors.transparent
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0xFF4CAF50),
                                blurRadius: 10,
                                spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'جاري تحليل النبات...',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // خطوات التحليل
            ...List.generate(
                4,
                (i) => Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 0, end: 40, top: 6, bottom: 6),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // ✅ FIX: withOpacity → withValues
                              color: i < _currentStep
                                  ? const Color(0xFF4CAF50)
                                  : i == _currentStep
                                      ? const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                // ✅ FIX: withOpacity → withValues
                                color: i == _currentStep
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: i < _currentStep
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : i == _currentStep
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      )
                                    : const SizedBox(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _steps[i],
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              // ✅ FIX: withOpacity → withValues
                              color: i < _currentStep
                                  ? const Color(0xFF4CAF50)
                                  : i == _currentStep
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                              fontWeight: i == _currentStep
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    )),

            const Spacer(),

            // نسبة التقدم
            Text(
              '$_progress%',
              style: GoogleFonts.cairo(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
              ),
            ),

            const SizedBox(height: 8),

            // شريط التقدم
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 60),
              height: 4,
              decoration: BoxDecoration(
                // ✅ FIX: withOpacity → withValues
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
