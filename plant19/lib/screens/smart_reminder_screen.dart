//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/cupertino.dart'; // عشان الـ DatePicker الشيك
import '../services/database_service.dart';
import '../services/crop_data_cache.dart'; // تأكد من المسار حسب مكان ملفك

class SmartReminderScreen extends StatefulWidget {
  const SmartReminderScreen({super.key});

  @override
  State<SmartReminderScreen> createState() => _SmartReminderScreenState();
}

class _SmartReminderScreenState extends State<SmartReminderScreen>
    with SingleTickerProviderStateMixin {
  // 🎨 الألوان الأساسية
  bool get isDark => DatabaseService.isDarkMode();

  Color get bgCream =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F6);
  Color get darkGreen => isDark ? Colors.white : const Color(0xFF0A2E1A);
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final Color waterBlue = const Color(0xFF1E88E5);
  final Color fertGreen = const Color(0xFF4CAF50);
  final Color warningOrange = const Color(0xFFFF8C00);
  // المتغيرات والتحكم
  final PageController _pageController = PageController();
  int _currentStep = 0;

  List<dynamic> _crops = [];
  dynamic _selectedCrop;
  DateTime _plantingDate = DateTime.now();
  String _searchQuery = '';
  String _selectedTime = '7 صباحاً';

  late TabController _tabController;
  final List<String> _notificationTimes = [
    '6 صباحاً',
    '7 صباحاً',
    '8 صباحاً',
    'مخصص'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final crops = await CropDataCache
          .getCrops(); // ✅ كل الشغل في الـ Cache والـ Isolate
      setState(() {
        _crops = crops;
      });
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المنبهات: $e');
      setState(() {
        _crops = []; // نضمن عدم وجود null
      });
    }
  }

  Future<void> _pickCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() => _selectedTime = '$hour:$minute');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen),
          onPressed: _prevStep,
        ),
        title: Text(
          'المنبه الزراعي الذكي',
          style: GoogleFonts.cairo(
              color: darkGreen, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // نمنع السحب اليدوي عشان نمشي بالترتيب
              children: [
                _buildStep1CropSelection(),
                _buildStep2DateSelection(),
                _buildStep3SchedulePreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // شريط التقدم العلوي (Progress Bar)
  // ═══════════════════════════════════════════════════
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProgressStep(0, 'اختر نباتك'),
          _buildProgressLine(0),
          _buildProgressStep(1, 'تاريخ الزراعة'),
          _buildProgressLine(1),
          _buildProgressStep(2, 'فعّل المنبهات'),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int stepIndex, String title) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.greenAccent : darkGreen)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: darkGreen.withValues(alpha:0.3),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Center(
            child: isActive && _currentStep > stepIndex
                ? Icon(Icons.check_rounded,
                    color: isDark ? Colors.black : Colors.white, size: 18)
                : Text('${stepIndex + 1}',
                    style: GoogleFonts.cairo(
                        color: isActive
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? darkGreen : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int stepIndex) {
    bool isActive = _currentStep > stepIndex;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        height: 3,
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.greenAccent : darkGreen)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // STEP 1: Crop Selection
  // ═══════════════════════════════════════════════════
  Widget _buildStep1CropSelection() {
    List<dynamic> filteredCrops =
        _crops.where((c) => c['crop_name_ar'].contains(_searchQuery)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.spa_rounded,
                  color: isDark ? Colors.greenAccent : darkGreen),
              const SizedBox(width: 8),
              Text('اختر المحصول',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkGreen)),
            ],
          ),
          const SizedBox(height: 16),

          // شريط البحث
          Container(
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.04), blurRadius: 10)
                ]),
            child: TextField(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.cairo(color: darkGreen),
              decoration: InputDecoration(
                hintText: 'ابحث عن محصولك...',
                hintStyle: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                prefixIcon: Icon(Icons.search_rounded,
                    color: isDark ? Colors.grey : darkGreen),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // شبكة النباتات (Grid)
          Expanded(
            child: _crops.isEmpty
                ? Center(child: CircularProgressIndicator(color: fertGreen))
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = filteredCrops[index];
                      bool isSelected = _selectedCrop != null &&
                          _selectedCrop['crop_id'] == crop['crop_id'];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedCrop = crop);
                          Future.delayed(const Duration(milliseconds: 300),
                              _nextStep); // انتقال تلقائي ناعم
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.greenAccent : darkGreen)
                                    : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                                width: isSelected ? 2.5 : 1.5),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: (isDark
                                                ? Colors.greenAccent
                                                : darkGreen)
                                            .withValues(alpha:0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2)
                                  ]
                                : [],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isSelected
                                        ? (isDark
                                            ? Colors.greenAccent
                                                .withValues(alpha:0.2)
                                            : darkGreen.withValues(alpha:0.1))
                                        : (isDark
                                            ? Colors.white10
                                            : Colors.grey.shade100),
                                    child: Icon(Icons.grass_rounded,
                                        color: isSelected
                                            ? (isDark
                                                ? Colors.greenAccent
                                                : darkGreen)
                                            : Colors.grey,
                                        size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    crop['crop_name_ar'],
                                    style: GoogleFonts.cairo(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? (isDark
                                              ? Colors.greenAccent
                                              : darkGreen)
                                          : (isDark
                                              ? Colors.grey
                                              : Colors.grey.shade800),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.greenAccent
                                            : darkGreen,
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.check_rounded,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                        size: 12),
                                  ).animate().scale(
                                      duration: 300.ms,
                                      curve: Curves.easeOutBack),
                                ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // STEP 2: Planting Date
  // ═══════════════════════════════════════════════════
  Widget _buildStep2DateSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.calendar_month_rounded,
                  color: isDark ? Colors.greenAccent : darkGreen),
              const SizedBox(width: 8),
              Text('متى زرعت؟',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkGreen)),
            ],
          ),
          const SizedBox(height: 30),

          // منتقي التاريخ (Cupertino Date Picker)
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20)
              ],
            ),
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: GoogleFonts.cairo(
                        fontSize: 20,
                        color: darkGreen,
                        fontWeight: FontWeight.bold)),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _plantingDate,
                maximumDate: DateTime.now().add(const Duration(days: 1)),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() => _plantingDate = newDate);
                },
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms).fadeIn(),

          const SizedBox(height: 30),

          // كارت المعلومات
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fertGreen.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: fertGreen.withValues(alpha:0.3)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text('📅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'بناءً على تاريخ زراعتك، سنحسب جدول الري والتسميد تلقائياً لمكانك.',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : darkGreen,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const Spacer(),

          // زر المتابعة
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.greenAccent : darkGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('إنشاء الجدول الذكي',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white)),
            ),
          ).animate().slideY(begin: 1, end: 0, delay: 500.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // STEP 3: Auto-Generated Schedule Preview
  // ═══════════════════════════════════════════════════
  Widget _buildStep3SchedulePreview() {
    if (_selectedCrop == null) return const SizedBox();

    List watering = _selectedCrop['watering_schedule'] ?? [];
    List fertilization = _selectedCrop['fertilization_schedule'] ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.auto_awesome_rounded, color: warningOrange),
              const SizedBox(width: 8),
              Text('جدولك الزراعي الذكي',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkGreen)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs (الري | التسميد)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10)
              ]),
          child: TabBar(
            controller: _tabController,
            labelColor: isDark ? Colors.black : Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
                color: isDark ? Colors.greenAccent : darkGreen,
                borderRadius: BorderRadius.circular(20)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: '💧 الري'),
              Tab(text: '🌱 التسميد'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab Views (قوائم التايم لاين)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineList(watering, isWatering: true),
              _buildTimelineList(fertilization, isWatering: false),
            ],
          ),
        ),

        // كارت التلخيص (Smart Summary) ووقت الإشعارات
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : bgCream,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                        left: BorderSide(color: Color(0xFF4CAF50), width: 4))),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('💧 ${watering.length} مواعيد ري',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGreen)),
                        const SizedBox(height: 4),
                        Text('🌱 ${fertilization.length} مواعيد تسميد',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkGreen)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('⏰ أول منبه:',
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: Colors.grey.shade600)),
                        Text('غداً $_selectedTime',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: warningOrange)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notification Selector
              // Notification Selector
              Text('وقت الإشعارات اليومية',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkGreen)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: _notificationTimes.length,
                  itemBuilder: (ctx, i) {
                    final isCustomChip = _notificationTimes[i] == 'مخصص';
                    final bool isSelected = isCustomChip
                        ? !_notificationTimes
                            .sublist(0, 3)
                            .contains(_selectedTime)
                        : _selectedTime == _notificationTimes[i];

                    final displayText = (isCustomChip && isSelected)
                        ? _selectedTime
                        : _notificationTimes[i];

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_notificationTimes[i] == 'مخصص') {
                          _pickCustomTime(); // بيفتح الساعة
                        } else {
                          setState(() => _selectedTime = _notificationTimes[i]);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.greenAccent : darkGreen)
                              : (isDark ? Colors.black12 : bgCream),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.greenAccent : darkGreen)
                                  : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          displayText,
                          style: GoogleFonts.cairo(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // زر التفعيل النهائي
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: (isDark ? Colors.greenAccent : darkGreen)
                            .withValues(alpha:0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();

                    if (_selectedCrop == null) return;

                    try {
                      // ✅ نحضر الجدول من JSON
                      final List watering =
                          _selectedCrop['watering_schedule'] ?? [];
                      final List fertilization =
                          _selectedCrop['fertilization_schedule'] ?? [];

                      // ✅ نحول لـ List<Map> موحدة
                      final List<Map<String, dynamic>> schedule = [];

                      for (var w in watering) {
                        schedule.add({
                          'type': 'watering',
                          'day': w['start_day'] ?? 0,
                          'note': w['note'] ?? 'ري',
                          'quantity': w['quantity_liters'],
                          'fertilizer_type': null,
                        });
                      }

                      for (var f in fertilization) {
                        schedule.add({
                          'type': 'fertilization',
                          'day': f['start_day'] ?? 0,
                          'note': f['note'] ?? 'تسميد',
                          'quantity': null,
                          'fertilizer_type': f['type'],
                        });
                      }

                      // ✅ نحفظ في الداتابيز ونجدول الإشعارات
                      await DatabaseService.saveReminders(
                        cropId: _selectedCrop['crop_id'],
                        cropName: _selectedCrop['crop_name_ar'],
                        plantingDate: _plantingDate,
                        notificationTime: _selectedTime,
                        schedule: schedule,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ تم تفعيل ${schedule.length} منبه بنجاح!',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: darkGreen,
                        ),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      debugPrint('❌ خطأ في تفعيل المنبهات: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '❌ فشل في تفعيل المنبهات: $e',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.greenAccent : darkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    '✅ فعّل جميع المنبهات تلقائياً',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text('يمكنك تعديل أي منبه في أي وقت من الإعدادات',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.grey.shade500))),
            ],
          ),
        ).animate().slideY(begin: 1, end: 0, duration: 600.ms),
      ],
    );
  }

  // بناء قائمة التايم لاين (الري أو التسميد)
  Widget _buildTimelineList(List schedule, {required bool isWatering}) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 20, right: 20, left: 20),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final item = schedule[index];

        // استخراج البيانات بذكاء حسب نوع الجدول
        int startDay = item['start_day'] ?? 0;
        int duration = item['duration_days'] ?? 0;
        int repeat = item['repeat_days'] ?? 0;
        String note = item['note'] ?? '';
        String typeBadge = isWatering
            ? (repeat > 0 ? 'كل $repeat يوم' : 'لمرة واحدة')
            : (item['type'] ?? 'تسميد');

        String dateRange = duration > 0
            ? 'اليوم $startDay — ${startDay + duration}'
            : 'اليوم $startDay';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
                right: BorderSide(
                    color: isWatering ? waterBlue : fertGreen, width: 5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color:
                        (isWatering ? waterBlue : fertGreen).withValues(alpha:0.1),
                    shape: BoxShape.circle),
                child: Icon(
                    isWatering ? Icons.water_drop_rounded : Icons.eco_rounded,
                    color: isWatering ? waterBlue : fertGreen,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateRange,
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGreen)),
                        // Toggle Switch (ديكور حالياً)
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: true,
                            onChanged: (val) {},
                            activeThumbColor:
                                isDark ? Colors.greenAccent : darkGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: (isWatering ? waterBlue : fertGreen)
                              .withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(typeBadge,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isWatering ? waterBlue : fertGreen)),
                    ),
                    const SizedBox(height: 8),
                    Text(note,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            color:
                                isDark ? Colors.white60 : Colors.grey.shade600,
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0);
      },
    );
  }
}
