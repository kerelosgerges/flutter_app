import 'package:hive_flutter/hive_flutter.dart';
import 'notification_service.dart';

class DatabaseService {
  static Box? _myCropsBox;
  static Box? _bookmarksBox;
  static Box? _remindersBox;
  static Box? _settingsBox;

  // ✅ لازم تتصل أولاً في main.dart
  static Future<void> init() async {
    await Hive.initFlutter();
    _myCropsBox = await Hive.openBox('my_crops_box');
    _bookmarksBox = await Hive.openBox('bookmarks_box');
    _remindersBox = await Hive.openBox('reminders_box');
    _settingsBox = await Hive.openBox('settings_box');
    await NotificationService.init();
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _settingsBox?.put('isDarkMode', isDark);
  }

  // ✅ دالة لقراءة حالة الوضع الليلي (القيمة الافتراضية false)
  static bool isDarkMode() {
    return _settingsBox?.get('isDarkMode', defaultValue: false) ?? false;
  }
  // ══════════════════════════════════════════
  // 1. عمليات صندوق محاصيلي (My Crops)
  // ══════════════════════════════════════════

  static Future<void> saveCrop(Map<String, dynamic> cropData) async {
    if (_myCropsBox == null) return;
    await _myCropsBox!.put(cropData['crop_id'], cropData);
  }

  static List<Map<String, dynamic>> getAllSavedCrops() {
    if (_myCropsBox == null) return [];
    final data = _myCropsBox!.values.toList();
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> deleteCrop(String cropId) async {
    if (_myCropsBox == null) return;
    await _myCropsBox!.delete(cropId);
  }

  // ══════════════════════════════════════════
  // 2. عمليات صندوق المحفوظات (Bookmarks)
  // ══════════════════════════════════════════

  static Future<void> toggleBookmark(Map<String, dynamic> plantData) async {
    if (_bookmarksBox == null) return;
    final plantId = plantData['id'] ?? plantData['crop_id'];
    if (plantId == null) return;

    if (_bookmarksBox!.containsKey(plantId)) {
      await _bookmarksBox!.delete(plantId);
    } else {
      await _bookmarksBox!.put(plantId, plantData);
    }
  }

  static bool isBookmarked(String plantId) {
    if (_bookmarksBox == null) return false;
    return _bookmarksBox!.containsKey(plantId);
  }

  static List<Map<String, dynamic>> getAllBookmarks() {
    if (_bookmarksBox == null) return [];
    final data = _bookmarksBox!.values.toList();
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ══════════════════════════════════════════
  // 3. عمليات المنبهات (Reminders) - جديد
  // ══════════════════════════════════════════

  static Future<void> saveReminders({
    required String cropId,
    required String cropName,
    required DateTime plantingDate,
    required String notificationTime,
    required List<Map<String, dynamic>> schedule,
  }) async {
    final timeParts = _parseNotificationTime(notificationTime);
    final hour = timeParts['hour']!;
    final minute = timeParts['minute']!;

    // 1. حساب أعلى رقم نسخة موجود للمحصول
    final existing = getRemindersForCrop(cropId);
    int maxInstance = 0;
    for (var r in existing) {
      final inst = r['instance_number'] as int? ?? 0;
      if (inst > maxInstance) maxInstance = inst;
    }
    final instanceNumber = maxInstance + 1;
    final nowIso = DateTime.now().toIso8601String();

    // 2. إنشاء منبه لكل بند في الجدول
    for (var item in schedule) {
      final day = item['day'] as int;
      final type = item['type'] as String;
      final note = item['note'] as String;
      final quantity = item['quantity']?.toString();
      final fertilizerType = item['fertilizer_type']?.toString();

      final scheduledDate = DateTime(
        plantingDate.year,
        plantingDate.month,
        plantingDate.day + day,
        hour,
        minute,
      );

      final reminderId = '${cropId}_${type}_${day}_${instanceNumber}'.hashCode;

      final reminderData = {
        'reminder_id': reminderId,
        'crop_id': cropId,
        'crop_name': cropName,
        'instance_number': instanceNumber,
        'created_at': nowIso,
        'type': type,
        'day_from_planting': day,
        'scheduled_date': scheduledDate.toIso8601String(),
        'quantity': quantity,
        'fertilizer_type': fertilizerType,
        'note': note,
        'is_completed': false,
      };

      if (scheduledDate.isAfter(DateTime.now())) {
        final title = type == 'watering'
            ? '💧 وقت الري - $cropName'
            : '🌱 وقت التسميد - $cropName';
        final body = quantity != null
            ? '$note (${quantity}لتر)'
            : '$note ($fertilizerType)';

        await NotificationService.scheduleReminder(
          id: reminderId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: cropId,
        );
      }

      await _remindersBox!.put(reminderId, reminderData);
    }
  }

  static List<Map<String, dynamic>> getAllReminders() {
    if (_remindersBox == null) return [];
    final data = _remindersBox!.values.toList();
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> getRemindersForCrop(String cropId) {
    if (_remindersBox == null) return [];
    return getAllReminders().where((r) => r['crop_id'] == cropId).toList();
  }

  static Future<void> markReminderDone(int reminderId) async {
    if (_remindersBox == null) return;
    final reminder = _remindersBox!.get(reminderId);
    if (reminder != null) {
      final updated = Map<String, dynamic>.from(reminder);
      updated['is_completed'] = true;
      updated['completed_date'] = DateTime.now().toIso8601String();
      await _remindersBox!.put(reminderId, updated);
    }
  }

  // ══════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════

  static Map<String, int> _parseNotificationTime(String time) {
    if (time.contains(':')) {
      final parts = time.split(':');
      return {
        'hour': int.parse(parts[0]),
        'minute': int.parse(parts[1]),
      };
    }
    switch (time) {
      case '6 صباحاً':
        return {'hour': 6, 'minute': 0};
      case '7 صباحاً':
        return {'hour': 7, 'minute': 0};
      case '8 صباحاً':
        return {'hour': 8, 'minute': 0};
      default: // مخصص
        return {'hour': 7, 'minute': 0};
    }
  }
}
