import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/disease_result_screen.dart';

void main() {
  group('DiseaseResultScreen Tests', () {
    final testImage = File('assets/images/soil_background.jpg');
    final mockProtocol = {
      'diagnosis': {
        'leaves': 'بقع بنية على الأوراق',
        'fruits': 'تشوه في الثمار',
      },
      'prevention': ['زراعة أصناف مقاومة', 'تباعد النباتات'],
      'treatment_pesticides': [
        {
          'active_ingredient': 'مانكوزيب',
          'commercial_example': 'ريدوميل',
          'dosage': '2 جرام/لتر',
        }
      ],
      'application_timing': {
        'start': 'عند ظهور الأعراض الأولى',
        'frequency': 'كل 7 أيام',
        'safety_period': '14 يوم قبل الحصاد',
      },
    };

    testWidgets('should display disease information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseResultScreen(
            plantName: 'طماطم',
            diseaseName: 'اللفحة المبكرة',
            diseaseClass: 'Tomato___Early_blight',
            confidence: 0.87,
            imageFile: testImage,
            protocol: mockProtocol,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // تحقق من ظهور بيانات المرض
      expect(find.text('تم اكتشاف مرض'), findsOneWidget);
      expect(find.text('اللفحة المبكرة'), findsOneWidget);
      expect(find.text('Tomato___Early_blight'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget); // نسبة الإصابة
      expect(find.text('نسبة الإصابة'), findsOneWidget);
    });

    testWidgets('should display severity based on confidence', (tester) async {
      // حالة عالية (> 0.8)
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseResultScreen(
            plantName: 'طماطم',
            diseaseName: 'اللفحة المتأخرة',
            diseaseClass: 'Tomato___Late_blight',
            confidence: 0.92,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('مرتفع'), findsOneWidget);

      // حالة متوسطة (0.5 - 0.8)
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseResultScreen(
            plantName: 'طماطم',
            diseaseName: 'تبقع ورقي',
            diseaseClass: 'Tomato___Leaf_spot',
            confidence: 0.65,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('متوسط'), findsOneWidget);
    });

    testWidgets('should display protocol button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseResultScreen(
            plantName: 'طماطم',
            diseaseName: 'اللفحة المبكرة',
            diseaseClass: 'Tomato___Early_blight',
            confidence: 0.87,
            imageFile: testImage,
            protocol: mockProtocol,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('بروتوكول العلاج الكامل'), findsOneWidget);
      expect(find.text('فحص نبات آخر'), findsOneWidget);
    });

    testWidgets('should display immediate treatment steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DiseaseResultScreen(
            plantName: 'طماطم',
            diseaseName: 'اللفحة المبكرة',
            diseaseClass: 'Tomato___Early_blight',
            confidence: 0.87,
            imageFile: testImage,
            protocol: mockProtocol,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('خطوات العلاج الفورية'), findsOneWidget);
      expect(
        find.text('عزل النبات المصاب عن النباتات السليمة فوراً'),
        findsOneWidget,
      );
    });
  });
}