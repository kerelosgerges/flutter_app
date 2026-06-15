import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/analyzing_screen.dart';
// تم حذف الـ Mock غير المستخدم لتبسيط التست وضمان عمله
void main() {
  // ✅ ضروري للتعامل مع الـ Assets والملفات في التيست
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyzingScreen Tests', () {
    // إنشاء ملف وهمي (Dummy File) للاختبار
    final testImage = File('assets/images/soil_background.jpg');

    testWidgets('should display analyzing UI correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyzingScreen(imageFile: testImage),
        ),
      );

      // ✅ تصحيح: نستخدم pump() وليس pumpAndSettle() لتجنب الـ Timeout بسبب الأنيميشن
      await tester.pump();

      // تحقق من وجود عناصر التحليل الأساسية
      expect(find.text('جاري تحليل النبات...'), findsOneWidget);
      expect(find.text('جاري فحص الورقة'), findsOneWidget);
    });

    testWidgets('should display progress percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyzingScreen(imageFile: testImage),
        ),
      );

      await tester.pump();
      
      // التحقق من وجود نص النسبة المئوية (على الأقل وجود علامة %)
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('should show image preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyzingScreen(imageFile: testImage),
        ),
      );

      await tester.pump();

      // التحقق من وجود ويدجت الصورة
      expect(find.byType(Image) , findsWidgets);
    });

    testWidgets('should have all analysis steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyzingScreen(imageFile: testImage),
        ),
      );

      await tester.pump();

      // التأكد من ظهور خطوات التحليل
      expect(find.text('جاري فحص الورقة'), findsOneWidget);
      expect(find.text('تحليل الألوان والأنماط'), findsOneWidget);
      expect(find.text('البحث عن علامات المرض'), findsOneWidget);
      expect(find.text('إعداد التقرير النهائي'), findsOneWidget);
    });

    testWidgets('should show progress indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyzingScreen(imageFile: testImage),
        ),
      );

      await tester.pump();

      // التحقق من وجود مؤشر التحميل (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
