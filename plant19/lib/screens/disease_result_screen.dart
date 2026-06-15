import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ✅ FIX: شيلنا import '../services/protocol_service.dart' — كان unused import

class DiseaseResultScreen extends StatefulWidget {
  final String plantName;
  final String diseaseName;
  final String diseaseClass;
  final double confidence;
  final File imageFile;
  final Map<String, dynamic>? protocol;

  const DiseaseResultScreen({
    super.key,
    required this.plantName,
    required this.diseaseName,
    required this.diseaseClass,
    required this.confidence,
    required this.imageFile,
    this.protocol,
  });

  @override
  State<DiseaseResultScreen> createState() => _DiseaseResultScreenState();
}

class _DiseaseResultScreenState extends State<DiseaseResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _percentController;
  late Animation<double> _percentAnimation;
  int _displayedPercent = 0;
  int _visibleSteps = 0;

  @override
  void initState() {
    super.initState();

    final targetPercent = (widget.confidence * 100).toInt();

    _percentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _percentAnimation = Tween<double>(begin: 0, end: targetPercent.toDouble())
        .animate(
            CurvedAnimation(parent: _percentController, curve: Curves.easeOut));

    _percentController.addListener(() {
      if (mounted) {
        setState(() {
          _displayedPercent = _percentAnimation.value.toInt();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _percentController.forward();
    });

    _showSteps();
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _showSteps() async {
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _visibleSteps = i + 1);
    }
  }

  String get _severity {
    final conf = widget.confidence;
    if (conf > 0.8) return 'مرتفع';
    if (conf > 0.5) return 'متوسط';
    return 'منخفض';
  }

  Color get _severityColor {
    final conf = widget.confidence;
    if (conf > 0.8) return const Color(0xFFE53935);
    if (conf > 0.5) return const Color(0xFFFFA726);
    return const Color(0xFF66BB6A);
  }

  void _showFullProtocol() {
    final protocol = widget.protocol;
    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ عذراً، بروتوكول العلاج غير متاح لهذا المرض حالياً'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1F0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        '📋 بروتوكول علاج: ${widget.diseaseName}',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('🌱 المحصول', widget.plantName),
                      const SizedBox(height: 8),
                      _infoRow('🦠 الكود', widget.diseaseClass),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ FIX: protocol مش null هنا (تأكدنا فوق) — شيلنا ?[ واستبدلناها بـ [
                if (protocol['diagnosis'] != null) ...[
                  _sectionTitle('⚠️ التشخيص السريع'),
                  _buildDiagnosis(protocol['diagnosis'] as Map),
                  const SizedBox(height: 16),
                ],

                if (protocol['prevention'] != null &&
                    (protocol['prevention'] as List).isNotEmpty) ...[
                  _sectionTitle('🛡️ طرق الوقاية'),
                  ..._buildListItems(protocol['prevention'] as List),
                  const SizedBox(height: 16),
                ],

                if (protocol['treatment_pesticides'] != null &&
                    (protocol['treatment_pesticides'] as List).isNotEmpty) ...[
                  _sectionTitle('💊 العلاج والمبيدات المسموحة'),
                  ..._buildPesticidesList(
                      protocol['treatment_pesticides'] as List),
                  const SizedBox(height: 16),
                ],

                if (protocol['application_timing'] != null) ...[
                  _sectionTitle('📅 مواعيد التطبيق والجرعات'),
                  _buildTiming(protocol['application_timing'] as Map),
                  const SizedBox(height: 16),
                ],

                if (protocol['differential_diagnosis'] != null &&
                    (protocol['differential_diagnosis'] as List)
                        .isNotEmpty) ...[
                  _sectionTitle('🔍 التشخيص التفريقي'),
                  ..._buildDiffDiagnosis(
                      protocol['differential_diagnosis'] as List),
                ],

                const SizedBox(height: 20),
                Text(
                  '⚠️ ملاحظة: هذه الإرشادات من وزارة الزراعة المصرية ومنظمة الفاو. استشر مهندس زراعي قبل التطبيق.',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.orange.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF81C784),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.cairo(
                fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosis(Map diagnosis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diagnosis['leaves'] != null)
            _bulletPoint('🍃 الأوراق: ${diagnosis['leaves']}'),
          if (diagnosis['fruits'] != null)
            _bulletPoint('🍅 الثمار: ${diagnosis['fruits']}'),
          if (diagnosis['other_notes'] != null)
            _bulletPoint('💡 ملاحظات: ${diagnosis['other_notes']}'),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              text.length > 2 ? text.substring(2) : text,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('• ',
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildListItems(List items) {
    return items.map<Widget>((item) => _bulletPoint('• $item')).toList();
  }

  List<Widget> _buildPesticidesList(List pesticides) {
    return pesticides.map<Widget>((p) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 ${p['active_ingredient'] ?? ''}',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            if (p['commercial_example'] != null)
              Text(
                '💼 الاسم التجاري: ${p['commercial_example']}',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
              ),
            if (p['dosage'] != null)
              Text(
                '📏 الجرعة: ${p['dosage']}',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
              ),
            if (p['notes'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⚠️ ${p['notes']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.orange.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTiming(Map timing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timing['start'] != null)
            _bulletPoint('🚀 البداية: ${timing['start']}'),
          if (timing['frequency'] != null)
            _bulletPoint('🔄 التكرار: ${timing['frequency']}'),
          if (timing['safety_period'] != null)
            _bulletPoint('⏱️ فترة الأمان: ${timing['safety_period']}'),
          if (timing['note'] != null) _bulletPoint('💡 ${timing['note']}'),
        ],
      ),
    );
  }

  List<Widget> _buildDiffDiagnosis(List diffList) {
    return diffList.map<Widget>((d) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🆚 ${d['similar_disease'] ?? d['similar_condition'] ?? d['similar_pest'] ?? ''}',
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            Text(
              'الفرق: ${d['difference']}',
              style: GoogleFonts.cairo(
                  fontSize: 12, color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFFE53935), width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                  ),
                  ...List.generate(5, (index) {
                    return Positioned(
                      left: 40 + (index * 40).toDouble(),
                      top: 50 + (index % 3) * 60.0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                          .animate(delay: (300 * index).ms)
                          .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1))
                          .fadeIn(),
                    );
                  }),
                ],
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE53935), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'تم اكتشاف مرض',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      widget.diseaseName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.diseaseClass,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 18,
                        backgroundColor: Color.fromRGBO(255, 255, 255, 0.12),
                        valueColor: AlwaysStoppedAnimation(Color(0xFFE53935)),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _percentController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: _percentAnimation.value / 100,
                            strokeWidth: 18,
                            backgroundColor: Colors.transparent,
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFFE53935)),
                            strokeCap: StrokeCap.round,
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_displayedPercent%',
                          style: GoogleFonts.cairo(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'نسبة الإصابة',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('مستوى الخطورة', _severity, _severityColor,
                        Icons.warning_amber_rounded),
                    const Divider(color: Colors.white12),
                    _buildDetailRow(
                      'سرعة الانتشار',
                      widget.confidence > 0.7 ? 'سريعة' : 'متوسطة',
                      Colors.orange,
                      Icons.speed_rounded,
                    ),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('النبات الأكثر تأثراً', widget.plantName,
                        Colors.white70, Icons.eco_outlined),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'خطوات العلاج الفورية',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(4, (index) {
                      final steps = [
                        'عزل النبات المصاب عن النباتات السليمة فوراً',
                        'إزالة الأوراق المصابة بمقص معقم وحرقها',
                        'رش المبيد المناسب على النباتات المجاورة وقائياً',
                        'مراقبة النبات يومياً لمدة أسبوع لمتابعة التطور',
                      ];
                      final isVisible = index < _visibleSteps;
                      return AnimatedOpacity(
                        opacity: isVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isVisible
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isVisible
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : Text(
                                          '${index + 1}',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  steps[index],
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: isVisible
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.3),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showFullProtocol();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'بروتوكول العلاج الكامل',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.7), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'فحص نبات آخر',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, Color valueColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
