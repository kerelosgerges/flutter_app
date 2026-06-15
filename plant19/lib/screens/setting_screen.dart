import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'plant_details_screen.dart';
import 'smart_reminder_screen.dart'; // 👈 عشان نفتح شاشة إضافة المنبه
import '../main.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final Color darkGreen = const Color(0xFF0A2E1A);
  final Color vibrantGreen = const Color(0xFF4CAF50);
  final Color dangerRed = const Color(0xFFD32F2F);
  final Color warningOrange = const Color(0xFFFF8C00);

  late bool _isDarkMode;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _bookmarks = [];

  Color get bgColor =>
      _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9F6);
  Color get cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get textColor => _isDarkMode ? Colors.white : darkGreen;
  Color get subtitleTextColor =>
      _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _isDarkMode = DatabaseService.isDarkMode();
    _loadData();
  }

  Future<void> _deleteAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف جميع المنبهات',
          style:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, color: textColor),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد؟ سيتم حذف جميع منبهات الري والتسميد نهائياً.',
          style: GoogleFonts.cairo(color: subtitleTextColor, height: 1.5),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: darkGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف الكل', style: GoogleFonts.cairo(color: dangerRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // إلغاء جميع الإشعارات النشطة
      for (var r in _reminders) {
        final id = r['reminder_id'] as int? ?? 0;
        await NotificationService.cancelReminder(id);
      }

      // تفريغ صندوق Hive بالكامل
      final box = Hive.box('reminders_box');
      await box.clear();

      await _loadData(); // تحديث الواجهة
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    var rawReminders = DatabaseService.getAllReminders();

    // فرز: ري أولاً ثم تسميد، داخل كل نوع حسب created_at (الأقدم أولاً)
    rawReminders.sort((a, b) {
      final typeA = a['type'] as String? ?? '';
      final typeB = b['type'] as String? ?? '';
      if (typeA != typeB) {
        return typeA == 'watering' ? -1 : 1;
      }
      // نفس النوع: قارن تواريخ الإضافة
      final createdA = a['created_at'] as String? ?? '';
      final createdB = b['created_at'] as String? ?? '';
      final dateA = DateTime.tryParse(createdA) ?? DateTime(2100);
      final dateB = DateTime.tryParse(createdB) ?? DateTime(2100);
      return dateA.compareTo(dateB); // تصاعدي
    });

    _reminders = rawReminders;
    _bookmarks = DatabaseService.getAllBookmarks();
    setState(() => _isLoading = false);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.day} ${months[date.month - 1]} ${date.year} - $displayHour:$minute $period';
    } catch (e) {
      return isoDate;
    }
  }

  String _getReminderTypeLabel(String type) {
    return type == 'watering' ? '💧 ري' : '🌱 تسميد';
  }

  Future<void> _completeReminder(int reminderId) async {
    HapticFeedback.lightImpact();
    await DatabaseService.markReminderDone(reminderId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم الإكمال ✅',
            style: GoogleFonts.cairo(fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: vibrantGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteReminder(int reminderId) async {
    HapticFeedback.mediumImpact();
    await NotificationService.cancelReminder(reminderId);
    final box = Hive.box('reminders_box');
    await box.delete(reminderId);
    _loadData();
  }

  Future<void> _removeBookmark(Map<String, dynamic> plantData) async {
    HapticFeedback.mediumImpact();
    await DatabaseService.toggleBookmark(plantData);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم الإزالة من المحفوظات ❌',
            style: GoogleFonts.cairo(fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.grey.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmation(int reminderId, String cropName) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.delete_forever_rounded,
                      color: dangerRed, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'حذف المنبه',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'هل تريد حذف منبه "$cropName"؟',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: subtitleTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: darkGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteReminder(reminderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'حذف',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'اختر اللغة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('العربية', '🇸🇦', true),
              const SizedBox(height: 12),
              _buildLanguageOption('English', '🇬🇧', false),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String label, String flag, bool isSelected) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم اختيار $label',
              style: GoogleFonts.cairo(fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: darkGreen,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? vibrantGreen.withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? vibrantGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: vibrantGreen),
          ],
        ),
      ),
    );
  }

  void _showAboutBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vibrantGreen.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: vibrantGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Green Sight',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الإصدار ١.٠.٠',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: subtitleTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: vibrantGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تطوير: فريق Green Sight',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: subtitleTextColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الإعدادات',
            style: GoogleFonts.cairo(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildRemindersSection(),
                  const SizedBox(height: 24),
                  _buildBookmarksSection(),
                  const SizedBox(height: 24),
                  _buildGeneralSettingsSection(),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: vibrantGreen, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha:0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: subtitleTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ زرار إضافة منبه جديد
  Widget _buildAddReminderButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SmartReminderScreen(),
          ),
        ).then((_) => _loadData()); // 👈 لما يرجع من إضافة المنبه نحدث القائمة
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vibrantGreen.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_circle_rounded,
                color: vibrantGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'إضافة منبه جديد',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: vibrantGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // القسم الأول — منبهاتي 🔔
  // ═══════════════════════════════════════════════════
  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('منبهاتي', Icons.notifications_rounded),
        _buildCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_reminders.isEmpty)
                _buildEmptyState(
                  Icons.notifications_off_rounded,
                  'لا توجد منبهات مسجلة',
                )
              else
                ..._reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  final int reminderId = reminder['reminder_id'] ?? 0;
                  final String baseName =
                      reminder['crop_name'] ?? 'نبات غير معروف';
                  final int instance = reminder['instance_number'] as int? ?? 1;
                  final String cropName =
                      instance > 1 ? '$baseName $instance' : baseName;
                  final String type = reminder['type'] ?? 'watering';
                  final String dateStr = reminder['scheduled_date'] ?? '';
                  final bool isCompleted = reminder['is_completed'] ?? false;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.grey.shade200,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: vibrantGreen.withValues(alpha:0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_rounded,
                                color: vibrantGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    cropName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getReminderTypeLabel(type)} • ${_formatDate(dateStr)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: subtitleTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: isCompleted
                                        ? Colors.grey.shade400
                                        : vibrantGreen,
                                    size: 26,
                                  ),
                                  onPressed: isCompleted
                                      ? null
                                      : () => _completeReminder(reminderId),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_rounded,
                                    color: dangerRed,
                                    size: 22,
                                  ),
                                  onPressed: () => _showDeleteConfirmation(
                                    reminderId,
                                    cropName,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              // ✅ Divider قبل الزرار لو فيه منبهات
              if (_reminders.isNotEmpty)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
              // ✅ زرار الإضافة موجود دايماً
              _buildAddReminderButton(), // ✅ زرار الإضافة موجود دايما

              // 🗑️ زر حذف الكل (يظهر فقط إذا وُجدت منبهات)
              if (_reminders.isNotEmpty) ...[
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
                InkWell(
                  onTap: _deleteAllReminders,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dangerRed.withValues(alpha:0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            color: dangerRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'حذف جميع المنبهات',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  // ═══════════════════════════════════════════════════
  // القسم التاني — نباتاتي المحفوظة 🌿
  // ═══════════════════════════════════════════════════
  Widget _buildBookmarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('نباتاتي المحفوظة', Icons.bookmark_rounded),
        _buildCard(
          child: _bookmarks.isEmpty
              ? _buildEmptyState(
                  Icons.eco_rounded,
                  'لم تقم بحفظ أي نبات بعد',
                )
              : Column(
                  children: _bookmarks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plant = entry.value;
                    final String plantName = plant['name_ar'] ??
                        plant['crop_name_ar'] ??
                        'نبات غير معروف';
                    final String? imagePath = plant['image_path'];

                    return Column(
                      children: [
                        if (index > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.grey.shade200,
                          ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlantDetailsScreen(crop: plant),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      vibrantGreen.withValues(alpha:0.1),
                                  backgroundImage: imagePath != null
                                      ? AssetImage(imagePath)
                                      : null,
                                  child: imagePath == null
                                      ? Icon(
                                          Icons.eco_rounded,
                                          color: vibrantGreen,
                                          size: 24,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        plantName,
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'اضغط للتفاصيل',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: subtitleTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.bookmark_rounded,
                                    color: vibrantGreen,
                                    size: 24,
                                  ),
                                  onPressed: () => _removeBookmark(plant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  // ═══════════════════════════════════════════════════
  // القسم التالت — الإعدادات العامة ⚙️
  // ═══════════════════════════════════════════════════
  Widget _buildGeneralSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('الإعدادات العامة', Icons.settings_rounded),
        _buildCard(
          child: Column(
            children: [
              // الوضع الليلي
              _buildSettingTile(
                icon: Icons.dark_mode_rounded,
                iconColor: Colors.indigo,
                title: 'الوضع الليلي',
                trailing: Switch.adaptive(
                  value: _isDarkMode,
                  onChanged: (val) async {
                    setState(() => _isDarkMode = val);
                    await DatabaseService.setDarkMode(val);
                    darkModeNotifier.value = val;
                  },
                  activeThumbColor: vibrantGreen,
                  activeTrackColor: vibrantGreen.withValues(alpha:0.3),
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade200,
              ),
              // اللغة
              _buildSettingTile(
                icon: Icons.language_rounded,
                iconColor: Colors.blue,
                title: 'اللغة',
                trailing: GestureDetector(
                  onTap: _showLanguageBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: vibrantGreen.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'العربية',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: vibrantGreen,
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade200,
              ),
              // عن التطبيق
              _buildSettingTile(
                icon: Icons.info_rounded,
                iconColor: Colors.teal,
                title: 'عن التطبيق',
                trailing: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: subtitleTextColor,
                  size: 16,
                ),
                onTap: _showAboutBottomSheet,
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
