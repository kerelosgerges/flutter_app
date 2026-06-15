import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// تأكد من استدعاء شاشة الهوم عشان ننتقل ليها بعد التحميل
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // 1. أنيميشن اليرقات المضيئة (Fireflies)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // توليد 40 جزيء مضيء
    for (int i = 0; i < 40; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.2 + _random.nextDouble() * 0.5,
        size: 1.0 + _random.nextDouble() * 3.0,
      ));
    }

    // 2. أنيميشن شريط التحميل (الساق اللي بتنمو)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // التحميل هياخد 4 ثواني
    )..forward().then((_) {
        // بعد انتهاء التحميل، ننتقل للشاشة الرئيسية
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });

    // 3. أنيميشن النبض (Glow/Breathing) للوجو
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إخفاء شريط الحالة (Status Bar) لشاشة سينمائية كاملة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2E1A), // Dark deep green
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ═══════════════════════════════════════
          // 1. الخلفية العضوية (Organic Vignette/Texture)
          // ═══════════════════════════════════════
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  const Color(0xFF0F4225), // Lighter green at center
                  const Color(0xFF0A2E1A), // Deep green at edges
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // ═══════════════════════════════════════
          // 2. الجزيئات المضيئة المتطايرة (Fireflies)
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              for (var particle in _particles) {
                particle.update();
              }
              return CustomPaint(
                painter: ParticlePainter(particles: _particles),
                size: Size(size.width, size.height),
              );
            },
          ),

          // ═══════════════════════════════════════
          // 3. المحتوى المركزي (اللوجو + النصوص)
          // ═══════════════════════════════════════
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // اللوجو (ورقة شجر + سماعة طبيب + توهج)
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(
                              alpha: 0.3 + (_glowController.value * 0.3)),
                          blurRadius: 40 + (_glowController.value * 20),
                          spreadRadius: 10 + (_glowController.value * 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // الورقة في الخلفية
                        Icon(
                          Icons.eco_rounded,
                          size: 90,
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
                        ),
                        // السماعة الطبية ملتفة
                        const Positioned(
                          top: 20,
                          right: 20,
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 45,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack)
                  .fadeIn(),

              const SizedBox(height: 30),

              // اسم التطبيق (تدرج ذهبي/أبيض)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFD700)], // White to Gold
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  'دكتور النبات',
                  style: GoogleFonts.cairo(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().slideY(begin: 0.5, end: 0, duration: 800.ms).fadeIn(),

              const SizedBox(height: 8),

              // السلوجان (Tagline)
              Text(
                'صحة نباتك في يدك',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50), // Vibrant Green
                  letterSpacing: 1.0,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const Spacer(flex: 2),

              // ═══════════════════════════════════════
              // 4. شريط التحميل (Plant Stem)
              // ═══════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            // الخلفية الداكنة للشريط
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // الساق النامية (شريط التحميل)
                            FractionallySizedBox(
                              widthFactor: _progressController.value,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                      Color(0xFF81C784)
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // نص التحميل
                    Text(
                      'جاري تحميل نماذج الذكاء الاصطناعي...',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    )
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .fadeIn(duration: 800.ms)
                        .fadeOut(delay: 800.ms),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// كلاسات مساعدة لرسم الـ Particles (الجزيئات المضيئة)
// ═══════════════════════════════════════════════════

class Particle {
  double x;
  double y;
  double speed;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });

  void update() {
    // حركة للأعلى ببطء
    y -= speed * 0.002;
    // حركة يمين ويسار بسيطة لمحاكاة الرياح
    x += (math.Random().nextDouble() - 0.5) * 0.001;

    // إعادة الجزيء للأسفل إذا خرج من الشاشة
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.4) // لون الجزيئات
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0); // توهج خفيف

    for (var particle in particles) {
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
