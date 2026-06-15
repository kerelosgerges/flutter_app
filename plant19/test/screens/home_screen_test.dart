import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/home_screen.dart';
import 'package:Greensight/services/database_service.dart';
import 'package:Greensight/services/encyclopedia_service.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EncyclopediaService.load();
    await DatabaseService.init();
  });

  group('HomeScreen Tests', () {
    testWidgets('should display 6 service cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 6 خدمات في الـ grid
      // فحص أمراض النبات، كشف الحشائش، منبه الري، مساعد السماد، موسوعة، إعدادات
      expect(find.text('فحص أمراض النبات'), findsOneWidget);
      expect(find.text('كشف الحشائش'), findsOneWidget);
      expect(find.text('منبه الري والتسميد'), findsOneWidget);
      expect(find.text('مساعد السماد العضوي'), findsOneWidget);
      expect(find.text('موسوعة النباتات'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('should have Green Sight title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Green Sight'), findsOneWidget);
      expect(find.text('مرحباً بك 👋'), findsOneWidget);
      expect(find.text('اختر الخدمة اللي تحتاجها'), findsOneWidget);
    });

    testWidgets('should navigate to DiagnosisScreen when tapping first card', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // اضغط على أول كارت
        await tester.tap(find.text('فحص أمراض النبات'));
        await tester.pumpAndSettle();

        // المفروض يروح لشاشة التشخيص
        expect(find.text('فحص النبات'), findsOneWidget);
      },
    );

    testWidgets('should navigate to EncyclopediaScreen when tapping encyclopedia card', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('موسوعة النباتات'));
        await tester.pumpAndSettle();

        expect(find.text('موسوعة النباتات'), findsOneWidget);
      },
    );
  });
}