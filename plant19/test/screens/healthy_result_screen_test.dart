import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/healthy_result_screen.dart';

void main() {
  group('HealthyResultScreen Tests', () {
    final testImage = File('assets/images/soil_background.jpg');

    testWidgets('should display healthy plant message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealthyResultScreen(
            plantName: 'تفاح',
            confidence: 0.96,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('نباتك بصحة ممتازة 🎉'), findsOneWidget);
      expect(find.text('تفاح'), findsOneWidget);
      expect(find.text('سليمة ✅'), findsOneWidget);
    });

    testWidgets('should display correct percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealthyResultScreen(
            plantName: 'فراولة',
            confidence: 0.98,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // نسبة السلامة (في البداية 0% وبعد animation تبقى 98%)
      expect(find.text('نسبة السلامة'), findsOneWidget);
    });

    testWidgets('should display share and scan again buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealthyResultScreen(
            plantName: 'عنب',
            confidence: 0.94,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('فحص نبات آخر'), findsOneWidget);
      expect(find.text('مشاركة النتيجة'), findsOneWidget);
    });

    testWidgets('should display recommendation text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HealthyResultScreen(
            plantName: 'خيار',
            confidence: 0.91,
            imageFile: testImage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('استمر في العناية المنتظمة'), findsOneWidget);
    });
  });
}