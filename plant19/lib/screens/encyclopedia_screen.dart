//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/encyclopedia_service.dart';
import 'plant_details_screen.dart'; // 👈 استدعاء الشاشة الجديدة
import '../services/database_service.dart'; // 👈 استدعاء خدمة الداتابيز لقراءة الوضع الليلي

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  // ✅ تعريف الألوان بناءً على الوضع الحالي
  bool get isDark => DatabaseService.isDarkMode();
  Color get darkGreen => const Color(0xFF0A2E1A);
  Color get midGreen => const Color(0xFF4CAF50);
  Color get creamBg =>
      isDark ? const Color(0xFF121212) : const Color(0xFFFDFCF7);
  Color get textColor => isDark ? Colors.white : const Color(0xFF0A2E1A);
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final Color cardCream = const Color(0xFFF5F5DC);
  final Color warningOrange = const Color(0xFFFF8C00);
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'كل النباتات',
    'محاصيل',
    'خضروات',
    'فاكهة',
    'حبوب'
  ];
  int _selectedFilterIndex = 0;

  bool _isLoading = true;
  List<dynamic> _displayedCrops = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await EncyclopediaService.load();
    if (mounted) {
      setState(() {
        _displayedCrops = EncyclopediaService.getAll();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedCrops = EncyclopediaService.getAll();
      } else {
        _displayedCrops = EncyclopediaService.search(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg, // 👈 اللون أصبح متغيراً
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
        },
        backgroundColor: midGreen,
        elevation: 4,
        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
        label: Text(
          'افحص نباتك الآن',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      )
          .animate()
          .scale(delay: 800.ms, duration: 500.ms, curve: Curves.easeOutBack),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: midGreen))
                  : _displayedCrops.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 20,
                            right: 20,
                            bottom: 100,
                          ),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _displayedCrops.length,
                          itemBuilder: (context, index) {
                            final crop = _displayedCrops[index];
                            return _buildPlantCard(crop, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.eco_rounded,
                      color: isDark ? midGreen : darkGreen, size: 28)
                  .animate()
                  .shake(duration: 500.ms),
              const SizedBox(width: 10),
              Text(
                'موسوعة النباتات',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textColor, // 👈 يتغير مع الوضع
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
            ],
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: isDark ? midGreen : darkGreen, size: 18),
            ),
          ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha:0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(fontSize: 15, color: textColor),
          decoration: InputDecoration(
            hintText: 'ابحث عن نبات أو مرض...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 14, color: textColor.withValues(alpha:0.4)),
            prefixIcon: Icon(Icons.search_rounded, color: midGreen),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: 200.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        reverse: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilterIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? midGreen : darkGreen) : cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? midGreen : darkGreen)
                        : cardCream,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: (isDark ? midGreen : darkGreen)
                                  .withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color:
                        isSelected ? Colors.white : textColor.withValues(alpha:0.6),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildPlantCard(dynamic crop, int index) {
    final String nameAr = crop['name_ar'] ?? 'نبات';
    final String nameLat = crop['id'] ?? 'Unknown';
    final bool isHealthy = index % 2 == 0;

    // Safely cast the list and get its length
    final List<dynamic>? diseasesList =
        crop['common_diseases'] as List<dynamic>?;
    final int diseasesCount = diseasesList?.length ?? 0;

    final String imagePath = 'assets/images/soil_background.jpg';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // فتح شاشة التفاصيل وتمرير بيانات النبات (crop)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailsScreen(crop: crop),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha:0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        darkGreen.withValues(alpha:0.2),
                        darkGreen.withValues(alpha:0.9),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHealthy ? midGreen : warningOrange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isHealthy ? 'صحي' : 'عرضة للأمراض',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isHealthy
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nameAr,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      nameLat,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha:0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.coronavirus_rounded,
                            color: cardCream, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$diseasesCount أمراض مسجلة',
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cardCream,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 20 * index))
          .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 80, color: textColor.withValues(alpha:0.2)),
          const SizedBox(height: 16),
          Text(
            'لم نجد نباتات مطابقة لبحثك',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
