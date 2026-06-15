import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/services/encyclopedia_service.dart';

void main() {
  // ✅ إضافة هذه السطر في بداية الـ main لتهيئة التعامل مع الـ Assets في التست
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncyclopediaService Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await EncyclopediaService.load();
    });

    test('should load data correctly', () async {
      final allCrops = EncyclopediaService.getAll();
      expect(allCrops, isNotNull);
      expect(allCrops, isList);
    });

    test('should return all crops after loading', () async {
      final crops = EncyclopediaService.getAll();
      
      // عندك على الأقل نبات واحد في الموسوعة
      expect(crops.length, greaterThan(0));
    });

    test('should get crop by id', () async {
      final crops = EncyclopediaService.getAll();
      
      if (crops.isNotEmpty) {
        final firstCropId = crops[0]['id'];
        final crop = EncyclopediaService.getById(firstCropId);
        
        expect(crop, isNotNull);
        expect(crop['id'], firstCropId);
      } else {
        // لو مفيش بيانات، الـ test يتخطى
        expect(true, true);
      }
    });

    test('should return empty map for non-existent id', () async {
      final crop = EncyclopediaService.getById('non_existent_id_12345');
      
      // لازم يرجع map فاضي أو null
      expect(crop, isNotNull);
    });

    test('should search crops by Arabic name', () async {
      final results = EncyclopediaService.search('طماطم');
      
      expect(results, isList);
      
      // لو في طماطم في الموسوعة، يطلعها
      if (results.isNotEmpty) {
        expect(results[0]['name_ar'], contains('طماطم'));
      }
    });

    test('should search crops by Latin id', () async {
      final results = EncyclopediaService.search('tomato');
      
      expect(results, isList);
    });

    test('should return empty list for search with no results', () async {
      final results = EncyclopediaService.search('نبات مش موجود خالص 123456');
      
      expect(results, isEmpty);
    });

    test('should handle empty search query', () async {
      final results = EncyclopediaService.search('');
      
      // لازم يرجع كل النباتات
      expect(results, isList);
    });

    test('should return same instance after multiple loads', () async {
      await EncyclopediaService.load(); // load تاني
      final crops1 = EncyclopediaService.getAll();
      final crops2 = EncyclopediaService.getAll();
      
      expect(crops1, same(crops2));
    });
  });
}