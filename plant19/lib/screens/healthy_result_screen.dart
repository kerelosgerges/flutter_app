import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class HealthyResultScreen extends StatefulWidget {
  final String plantName;
  final double confidence;
  final File imageFile;
  const HealthyResultScreen(
      {super.key,
      required this.plantName,
      required this.confidence,
      required this.imageFile});

  @override
  State<HealthyResultScreen> createState() => _HealthyResultScreenState();
}

class _HealthyResultScreenState extends State<HealthyResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _percentController;
  late Animation<double> _percentAnimation;
  int _displayedPercent = 0;

  @override
  void initState() {
    super.initState();
    final target = (widget.confidence * 100).toInt();
    _percentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _percentAnimation = Tween<double>(begin: 0, end: target.toDouble()).animate(
        CurvedAnimation(parent: _percentController, curve: Curves.easeOut));
    _percentController.addListener(() {
      if (mounted)
        setState(() => _displayedPercent = _percentAnimation.value.toInt());
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _percentController.forward();
    });
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _shareResult() async {
    await Share.share(
        '🌿 نتيجة فحص نباتك:\n✅ النبات: ${widget.plantName}\n💚 الحالة: سليم بنسبة ${_displayedPercent}%\n\nتطبيق "Green Sight" 🌾',
        subject: 'نتيجة فحص نبات');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _buildConfetti(),
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
                      value: 1,
                      strokeWidth: 18,
                      backgroundColor: Color.fromRGBO(255, 255, 255, 0.12),
                      valueColor: AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _percentController,
                    builder: (_, __) => SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _percentAnimation.value / 100,
                        strokeWidth: 18,
                        backgroundColor: Colors.transparent,
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$_displayedPercent%',
                        style: GoogleFonts.cairo(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50))),
                    const SizedBox(height: 6),
                    Text('نسبة السلامة',
                        style: GoogleFonts.cairo(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    const Icon(Icons.eco_rounded,
                        color: Color(0xFF4CAF50), size: 24),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('نباتك بصحة ممتازة 🎉',
                style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF81C784))),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha:0.1))),
              child: Column(children: [
                _buildDetailRow(
                    'اسم النبات', widget.plantName, Icons.eco_outlined),
                const Divider(color: Colors.white12),
                _buildDetailRow(
                    'حالة الأوراق', 'سليمة ✅', Icons.check_circle_outline),
                const Divider(color: Colors.white12),
                _buildDetailRow('التوصية', 'استمر في العناية المنتظمة',
                    Icons.lightbulb_outline),
              ]),
            ),
            const Spacer(),
            _buildButton(
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              gradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              icon: Icons.camera_alt,
              label: 'فحص نبات آخر',
            ),
            const SizedBox(height: 12),
            _buildButton(
              onTap: _shareResult,
              gradient: null,
              icon: Icons.share_outlined,
              label: 'مشاركة النتيجة',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    // أنيميشن مستقر من غير flutter_animate لتجنب Duplicate GlobalKeys
    return SizedBox(
        height: 100,
        child: Stack(
            children: List.generate(20, (i) {
          final r = i * 137.5;
          return _ConfettiParticle(index: i, startX: r % 360, startY: r % 100);
        })));
  }

  Widget _buildButton(
      {required VoidCallback onTap,
      List<Color>? gradient,
      required IconData icon,
      required String label}) {
    final isOutlined = gradient == null;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: EdgeInsets.symmetric(vertical: isOutlined ? 14 : 16),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : LinearGradient(colors: gradient),
          color: isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: Colors.white.withValues(alpha:0.3))
              : null,
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon,
                  color: isOutlined
                      ? Colors.white.withValues(alpha:0.7)
                      : Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: isOutlined ? 15 : 16,
                      fontWeight:
                          isOutlined ? FontWeight.w600 : FontWeight.bold,
                      color: Colors.white)),
            ]),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(textDirection: TextDirection.rtl, children: [
          Icon(icon, color: Colors.white.withValues(alpha:0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.white.withValues(alpha:0.5))),
                Text(value,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha:0.9))),
              ])),
        ]));
  }
}

class _ConfettiParticle extends StatefulWidget {
  final int index;
  final double startX, startY;
  const _ConfettiParticle(
      {required this.index, required this.startX, required this.startY});

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + widget.index * 200))
      ..repeat();
    _anim = Tween<double>(begin: widget.startY - 50, end: widget.startY + 150)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(
            () {}); // Reset position visually if needed, but repeat() handles it
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_anim.value - widget.startY) / 200).clamp(0.0, 1.0);
    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Positioned(
              left: widget.startX,
              top: _anim.value,
              child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color:
                            Color((widget.index * 1000).toInt() | 0xFF4CAF50),
                        shape: BoxShape.circle),
                  )),
            ));
  }
}
