import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diagnosis_screen.dart';
import 'weed_screen.dart';
import 'smart_reminder_screen.dart';
import 'compost_screen.dart';
import 'encyclopedia_screen.dart';
import 'setting_screen.dart';
import 'store_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // ✅ FIX: بدل ما نحط Widget instance جاهزة، بنحط builder function
  // ده بيحل مشكلة Duplicate GlobalKeys و _elements.contains(element) crash
  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.biotech_rounded,
      'iconColor': const Color(0xFF81C784),
      'iconBg': const Color(0xFF1B5E20),
      'title': 'فحص أمراض النبات',
      'description':
          'حدد مرض نباتك بدقة تتجاوز 95% — يعمل بدون إنترنت وبنسبة خطأ منخفضة جداً جداً',
      'screenBuilder': () => const DiagnosisScreen(),
    },
    {
      'icon': Icons.grass_rounded,
      'iconColor': const Color(0xFFFFB74D),
      'iconBg': const Color(0xFF6D4C41),
      'title': 'كشف الحشائش',
      'description':
          'افتح الكاميرا وفي أقل من ثانيتين يحدد الذكاء الاصطناعي مواقع الحشائش بدقة عالية',
      'screenBuilder': () => const WeedScreen(),
    },
    {
      'icon': Icons.water_drop_rounded,
      'iconColor': const Color(0xFF4FC3F7),
      'iconBg': const Color(0xFF01579B),
      'title': 'منبه الري والتسميد',
      'description':
          'اضبط مواعيد الري والتسميد وخليك دايماً في الوقت الصح لرعاية نباتاتك بشكل ممتاز',
      'screenBuilder': () => const SmartReminderScreen(),
    },
    {
      'icon': Icons.recycling_rounded,
      'iconColor': const Color(0xFFA5D6A7),
      'iconBg': const Color(0xFF33691E),
      'title': 'مساعد السماد العضوي',
      'description':
          'تحدث مع الذكاء الاصطناعي وتعلم كيف تحول مخلفات المنزل لسماد عضوي بدون أي رائحة',
      'screenBuilder': () => const CompostScreen(),
    },
    {
      'icon': Icons.menu_book_rounded,
      'iconColor': const Color(0xFFBCAAA4),
      'iconBg': const Color(0xFF4E342E),
      'title': 'موسوعة النباتات',
      'description':
          'كل ما تحتاجه قبل الزراعة — أهمية النبات، التحديات، الأمراض، الري، ووقت نضج الثمار',
      'screenBuilder': () => const EncyclopediaScreen(),
    },
        {
      'icon': Icons.storefront_rounded,
      'iconColor': const Color(0xFFFFCA28), // ذهبي دافئ
      'iconBg': const Color(0xFF5D4037),    // بني غامق
      'title': 'السوق',
      'description':
          'تجارة مباشرة تربط المزارعين بالتجار بسهولة وأمان',
      'screenBuilder': () => const StoreScreen(),
    },
    {
      'icon': Icons.settings_rounded,
      'iconColor': const Color(0xFFB0BEC5),
      'iconBg': const Color(0xFF455A64),
      'title': 'الإعدادات',
      'description': 'تحكم في إشعاراتك، بياناتك، وتفضيلات التطبيق بكل سهولة',
      'screenBuilder': () => const SettingScreen(),
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ FIX: الـ navigate دلوقتي بيبني widget جديدة في كل مرة
  void _navigateToScreen(BuildContext context, Widget Function() builder) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => builder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildOverlay(),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(child: _buildHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildServicesGrid(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/soil_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Green Sight',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك 👋',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر الخدمة اللي تحتاجها',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildServicesGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final service = _services[index];
          final isFromRight = index % 2 == 0;
          return _buildServiceCard(
            service: service,
            isFromRight: isFromRight,
            delay: Duration(milliseconds: 100 * index),
          );
        },
        childCount: _services.length,
      ),
    );
  }

  Widget _buildServiceCard({
    required Map<String, dynamic> service,
    required bool isFromRight,
    required Duration delay,
  }) {
    return GestureDetector(
      // ✅ FIX: بنستخدم screenBuilder بدل screen
      onTap: () => _navigateToScreen(
        context,
        service['screenBuilder'] as Widget Function(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (service['iconBg'] as Color).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service['icon'] as IconData,
                color: service['iconColor'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              service['title'] as String,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                service['description'] as String,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.6,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF81C784),
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay)
        .slideX(
          begin: isFromRight ? 0.5 : -0.5,
          end: 0,
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 600.ms,
          delay: delay,
        );
  }
}
