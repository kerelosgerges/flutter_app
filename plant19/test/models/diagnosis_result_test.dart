import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/models/diagnosis_result.dart'; // غير اسم البackage بتاعك

void main() {
  group('DiagnosisResult Model Tests', () {
    
    test('should create Disease Diagnosis Result correctly', () {
      final result = DiagnosisResult(
        isPlant: true,
        plantConfidence: 0.95,
        diseaseClass: 'Tomato___Early_blight',
        diseaseConfidence: 0.87,
        isHealthy: false,
        plantName: 'طماطم',
        diseaseName: 'اللفحة المبكرة',
      );

      expect(result.isPlant, true);
      expect(result.plantConfidence, 0.95);
      expect(result.diseaseClass, 'Tomato___Early_blight');
      expect(result.diseaseConfidence, 0.87);
      expect(result.isHealthy, false);
      expect(result.plantName, 'طماطم');
      expect(result.diseaseName, 'اللفحة المبكرة');
    });

    test('should create Healthy Diagnosis Result correctly', () {
      final result = DiagnosisResult(
        isPlant: true,
        plantConfidence: 0.98,
        isHealthy: true,
        plantName: 'تفاح',
        diseaseName: 'سليم',
      );

      expect(result.isHealthy, true);
      expect(result.plantName, 'تفاح');
      expect(result.diseaseConfidence, null);
      expect(result.diseaseClass, null);
    });

    test('should create Non-Plant Result correctly', () {
      final result = DiagnosisResult(
        isPlant: false,
        plantConfidence: 0.12,
      );

      expect(result.isPlant, false);
      expect(result.plantConfidence, 0.12);
      expect(result.isHealthy, false);
    });
  });
}