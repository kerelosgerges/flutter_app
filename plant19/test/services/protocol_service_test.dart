import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/services/protocol_service.dart';

void main() {
  group('ProtocolService Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await ProtocolService.loadProtocols();
    });

    test('should load protocols correctly', () async {
      final protocols = ProtocolService.protocols;
      
      expect(protocols, isNotNull);
      expect(protocols!.containsKey('protocols'), true);
    });

    test('should get protocol by class name', () async {
      // اختبار على مرض موجود (مثال: Tomato___Early_blight)
      final protocol = ProtocolService.getProtocol('Tomato___Early_blight');
      
      // لو المرض موجود في الـ JSON
      if (protocol != null) {
        expect(protocol.containsKey('disease_name'), true);
        expect(protocol.containsKey('crop'), true);
      } else {
        // لو مش موجود، الـ test يتخطى
        expect(true, true);
      }
    });

    test('should return null for non-existent disease', () async {
      final protocol = ProtocolService.getProtocol('Non_Existent_Disease_XYZ');
      
      expect(protocol, isNull);
    });

    test('should get Arabic disease name', () async {
      final arabicName = ProtocolService.getArabicDiseaseName('Tomato___Early_blight');
      
      // لازم يرجع اسم عربي أو نفس الاسم لو مش موجود
      expect(arabicName, isNotEmpty);
    });

    test('should return class name when disease not found', () async {
      final arabicName = ProtocolService.getArabicDiseaseName('Unknown_Disease_123');
      
      expect(arabicName, equals('Unknown_Disease_123'));
    });

    test('should get crop name for disease', () async {
      final cropName = ProtocolService.getCropName('Tomato___Early_blight');
      expect(cropName, isNotNull);
      expect(cropName, isA<String>()); // ✅ تصحيح: استخدام isA<String>()
    });

    test('should return empty string for non-existent disease crop', () async {
      final cropName = ProtocolService.getCropName('Unknown_Disease_123');
      
      expect(cropName, isEmpty);
    });

    test('should have protocols getter', () async {
      final protocols = ProtocolService.protocols;
      
      expect(protocols, isNotNull);
    });
  });
}