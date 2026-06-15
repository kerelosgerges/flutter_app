import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await DatabaseService.init();
    });

    test('should initialize Hive boxes', () async {
      // إذا وصلنا هنا من غير أخطاء، يبقى initialization شغال
      expect(true, true);
    });

    test('should set and get dark mode', () async {
      // حفظ الوضع الليلي
      await DatabaseService.setDarkMode(true);
      bool isDark = DatabaseService.isDarkMode();
      expect(isDark, true);

      // تغيير للوضع العادي
      await DatabaseService.setDarkMode(false);
      isDark = DatabaseService.isDarkMode();
      expect(isDark, false);
    });

    test('should save and get crops', () async {
      final testCrop = {
        'crop_id': 'test_crop_123',
        'crop_name_ar': 'محصول اختبار',
      };

      await DatabaseService.saveCrop(testCrop);
      final savedCrops = DatabaseService.getAllSavedCrops();

      expect(savedCrops, isNotEmpty);
    });

    test('should delete crop', () async {
      final testCrop = {
        'crop_id': 'crop_to_delete',
        'crop_name_ar': 'محصول للحذف',
      };

      await DatabaseService.saveCrop(testCrop);
      await DatabaseService.deleteCrop('crop_to_delete');
      
      final crops = DatabaseService.getAllSavedCrops();
      final found = crops.any((c) => c['crop_id'] == 'crop_to_delete');
      
      expect(found, false);
    });

    test('should toggle bookmarks', () async {
      final testPlant = {
        'id': 'bookmark_test_plant',
        'name_ar': 'نبتة اختبار',
      };

      // حفظ bookmark
      await DatabaseService.toggleBookmark(testPlant);
      bool isBookmarked = DatabaseService.isBookmarked('bookmark_test_plant');
      expect(isBookmarked, true);

      // إزالة bookmark
      await DatabaseService.toggleBookmark(testPlant);
      isBookmarked = DatabaseService.isBookmarked('bookmark_test_plant');
      expect(isBookmarked, false);
    });

    test('should get all bookmarks', () async {
      final bookmarks = DatabaseService.getAllBookmarks();
      expect(bookmarks, isList);
    });

    test('should get all reminders', () async {
      final reminders = DatabaseService.getAllReminders();
      expect(reminders, isList);
    });

    test('should have isDarkMode default value', () {
      final isDark = DatabaseService.isDarkMode();
      expect(isDark, isA<bool>()); 
    });
  });
}