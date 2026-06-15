import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import 'diagnosis_screen.dart';

class PlantDetailsScreen extends StatefulWidget {
  final dynamic crop;

  const PlantDetailsScreen({super.key, required this.crop});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool get isDark => DatabaseService.isDarkMode();

  Color get bgCream =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F6);
  Color get darkGreen => isDark ? Colors.white : const Color(0xFF0A2E1A);
  Color get detailTextColor => isDark ? Colors.white70 : Colors.black87;
  final Color vibrantGreen = const Color(0xFF4CAF50);
  final Color warningOrange = const Color(0xFFFF8C00);
  final Color dangerRed = const Color(0xFFD32F2F);
  late TabController _tabController;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final plantId = widget.crop['id']?.toString() ?? '';
    setState(() {
      _isBookmarked = DatabaseService.isBookmarked(plantId);
    });
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    await DatabaseService.toggleBookmark(
        Map<String, dynamic>.from(widget.crop));
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'تم الحفظ في المفضلة ✅' : 'تم الإزالة من المفضلة ❌',
          style: GoogleFonts.cairo(fontSize: 14),
          textDirection: TextDirection.rtl,
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isBookmarked ? vibrantGreen : Colors.grey,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String nameAr = widget.crop['name_ar'] ?? 'نبات غير معروف';
    final String nameLat = widget.crop['id'] ?? '';
    final String imagePath =
        widget.crop['image_path'] ?? 'assets/images/soil_background.jpg';

    final List<dynamic> diseases =
        List<dynamic>.from(widget.crop['common_diseases'] ?? []);
    final List<dynamic> pests =
        List<dynamic>.from(widget.crop['common_pests'] ?? []);
    final int totalThreats = diseases.length + pests.length;

    return Scaffold(
      backgroundColor: bgCream,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ✅ زرار افحص بالذكاء الاصطناعي → DiagnosisScreen فاضية
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: vibrantGreen.withValues(alpha:0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              // ✅ يودي على DiagnosisScreen فاضية
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiagnosisScreen(),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            label: Text(
              'افحص نباتك الآن بالذكاء الاصطناعي',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vibrantGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
      ).animate().slideY(
          begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

      body: Directionality(
        textDirection: TextDirection.rtl, // ✅ لضمان إن كل حاجة تبدأ من اليمين
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.40,
                pinned: true,
                stretch: true,
                backgroundColor:
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFF0A2E1A),
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: false,
                actions: [
                  _buildGlassIconButton(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _buildBookmarkButton(),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(imagePath, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.black : const Color(0xFF0A2E1A))
                                  .withValues(alpha:0.9)
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        right: 24,
                        left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // ✅ تعديل: عشان يبدأ من اليمين في الـ RTL
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: vibrantGreen.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: vibrantGreen.withValues(alpha:0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      color: vibrantGreen, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'محصول رئيسي في أسوان',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 8),
                            Text(
                              nameAr,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            )
                                .animate()
                                .slideX(begin: 0.1, end: 0, delay: 300.ms),
                            if (nameLat.isNotEmpty)
                              Text(
                                nameLat,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(Icons.coronavirus_rounded,
                              '$totalThreats أمراض', 'معروفة')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(Icons.calendar_month_rounded,
                              'دورة النمو', 'متوسطة')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              Icons.water_drop_rounded, 'الري', 'دقيق')),
                    ],
                  ).animate().slideY(begin: 0.5, end: 0, duration: 500.ms),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: isDark
                        ? Colors.white
                        : const Color(
                            0xFF0A2E1A), // ✅ تعديل اللون عشان يبان ع الخلفية الفاتحة
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                    indicator: BoxDecoration(
                        color: vibrantGreen.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: vibrantGreen, width: 1.5)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(
                        horizontal: -10, vertical: 6),
                    labelStyle: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: const [
                      Tab(text: 'نظرة عامة'),
                      Tab(text: 'الأمراض والآفات'),
                      Tab(text: 'الزراعة والري'),
                      Tab(text: 'الإرشادات'),
                    ],
                  ),
                  bgCream, // ✅ تعديل: بقت نفس لون خلفية الصفحة
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildOverviewTab(),
              _buildDiseasesTab(diseases, pests),
              _buildCareTab(),
              _buildGuidelinesTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ زر الحفظ (Bookmark) - متصل بـ DatabaseService
  Widget _buildBookmarkButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha:0.2)),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            key: ValueKey<bool>(_isBookmarked),
            color: _isBookmarked ? vibrantGreen : Colors.white,
            size: 20,
          ),
        ),
        onPressed: _toggleBookmark,
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha:0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF0A2E1A))
                  .withValues(alpha:0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: vibrantGreen, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0A2E1A))),
          Text(subtitle,
              style: GoogleFonts.cairo(fontSize: 10, color: detailTextColor)),
        ],
      ),
    );
  }

  // ✅ تعديل دالة التحديات والمخاطر داخل _buildOverviewTab
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSectionTitle('عن النبات', Icons.eco_rounded),
        const SizedBox(height: 12),
        Text(
          widget.crop['importance_benefits'] ?? 'لا توجد معلومات متوفرة.',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
              fontSize: 15, color: detailTextColor, height: 1.6),
        ).animate().fadeIn(),
        const SizedBox(height: 30),
        _buildSectionTitle('التحديات والمخاطر', Icons.warning_amber_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: false, // ✅ تعديل: false عشان الـ RTL بيبدأ من اليمين لوحده
            physics: const BouncingScrollPhysics(),
            itemCount: (widget.crop['main_challenges'] as List?)?.length ?? 0,
            itemBuilder: (context, index) {
              final challenge = widget.crop['main_challenges'][index];
              return Container(
                margin: const EdgeInsets.only(
                    left: 12), // المسافة بقت ع الشمال عشان إحنا بنرص من اليمين
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: dangerRed.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dangerRed.withValues(alpha:0.2)),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.gpp_maybe_rounded, color: dangerRed, size: 18),
                    const SizedBox(width: 8),
                    Text(challenge,
                        style: GoogleFonts.cairo(
                            color: dangerRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: (100 * index).ms)
                  .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              warningOrange.withValues(alpha:0.1),
              warningOrange.withValues(alpha:0.02)
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: warningOrange.withValues(alpha:0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ✅ تعديل: عشان RTL
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.lightbulb_circle_rounded,
                      color: warningOrange, size: 28),
                  const SizedBox(width: 8),
                  Text('نصيحة ذهبية',
                      style: GoogleFonts.cairo(
                          color: warningOrange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.crop['economic_notes'] ?? '',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                    color: detailTextColor, fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildDiseasesTab(List diseases, List pests) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        if (diseases.isNotEmpty) ...[
          _buildSectionTitle('الأمراض الشائعة', Icons.coronavirus_rounded),
          const SizedBox(height: 12),
          ...diseases
              .map((d) => _buildListTile(d, Icons.sick_rounded, dangerRed))
              .toList(),
          const SizedBox(height: 24),
        ],
        if (pests.isNotEmpty) ...[
          _buildSectionTitle('الآفات والحشرات', Icons.bug_report_rounded),
          const SizedBox(height: 12),
          ...pests
              .map((p) =>
                  _buildListTile(p, Icons.pest_control_rounded, warningOrange))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildCareTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildContentCard('التربة والمناخ', widget.crop['climate_soil'],
            Icons.thermostat_rounded, warningOrange),
        const SizedBox(height: 16),
        _buildContentCard('احتياجات الري', widget.crop['watering'],
            Icons.water_drop_rounded, Colors.blue),
        const SizedBox(height: 16),
        _buildContentCard('بروتوكول التسميد', widget.crop['fertilization'],
            Icons.compost_rounded, Colors.brown),
      ],
    );
  }

  Widget _buildGuidelinesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildContentCard('علامات النضج', widget.crop['maturity'],
            Icons.access_time_rounded, vibrantGreen),
        const SizedBox(height: 16),
        _buildContentCard(
            'إرشادات الحصاد',
            widget.crop['harvesting_tips'],
            Icons.agriculture_rounded,
            isDark ? Colors.white : const Color(0xFF0A2E1A)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon,
            color: isDark ? Colors.white : const Color(0xFF0A2E1A), size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0A2E1A))),
      ],
    );
  }

  Widget _buildContentCard(
      String title, String? content, IconData icon, Color color) {
    if (content == null || content.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF0A2E1A))
                  .withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ تعديل: عشان RTL
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0A2E1A))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
                fontSize: 14, color: detailTextColor, height: 1.6),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildListTile(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.1)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0A2E1A)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverAppBarDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.only(top: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
