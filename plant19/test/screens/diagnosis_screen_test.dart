import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/diagnosis_screen.dart';

void main() {
  group('DiagnosisScreen Tests', () {
    testWidgets('should display diagnosis options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiagnosisScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // تحقق من وجود العناصر
      expect(find.text('فحص النبات'), findsOneWidget);
      expect(find.text('فحص أمراض النبات'), findsOneWidget);
      expect(find.text('صوّر ورقة النبات وسنقوم بتحليلها'), findsOneWidget);
      expect(find.text('التقط صورة'), findsOneWidget);
      expect(find.text('اختر من المعرض'), findsOneWidget);
    });

    testWidgets('should have camera and gallery buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiagnosisScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final cameraButton = find.text('التقط صورة');
      final galleryButton = find.text('اختر من المعرض');

      expect(cameraButton, findsOneWidget);
      expect(galleryButton, findsOneWidget);
    });

    testWidgets('should show back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DiagnosisScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // البحث عن زر الرجوع (Arrow forward لأن الـ RTL)
      final backButton = find.byIcon(Icons.arrow_forward_ios_rounded);
      expect(backButton, findsOneWidget);
    });
  });
}