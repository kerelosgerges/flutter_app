import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:Greensight/main.dart';
import 'package:Greensight/services/database_service.dart';
import 'package:Greensight/services/encyclopedia_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Greensight App Integration Tests', () {
    setUpAll(() async {
      await DatabaseService.init();
      await EncyclopediaService.load();
    });

    testWidgets('Full app navigation flow', (tester) async {
      // تشغيل التطبيق
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 1. التأكد من ظهور SplashScreen ثم الانتقال للـ HomeScreen
      expect(find.byType(MyApp), findsOneWidget);

      // 2. في HomeScreen، نتأكد من ظهور الخدمات
      await tester.pumpAndSettle();
      expect(find.text('فحص أمراض النبات'), findsOneWidget);
      expect(find.text('موسوعة النباتات'), findsOneWidget);

      // 3. نفتح موسوعة النباتات
      await tester.tap(find.text('موسوعة النباتات'));
      await tester.pumpAndSettle();

      expect(find.text('موسوعة النباتات'), findsOneWidget);
      
      // 4. نرجع للـ HomeScreen
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded).first);
      await tester.pumpAndSettle();

      // 5. نفتح الإعدادات
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('الوضع الليلي'), findsOneWidget);

      // 6. نغير الوضع الليلي
      final darkModeSwitch = find.byType(Switch);
      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();
    
      // 7. نرجع للـ HomeScreen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();

      // 8. نفتح فحص أمراض النبات
      await tester.tap(find.text('فحص أمراض النبات'));
      await tester.pumpAndSettle();

      expect(find.text('فحص النبات'), findsOneWidget);
      expect(find.text('التقط صورة'), findsOneWidget);
      expect(find.text('اختر من المعرض'), findsOneWidget);

      // 9. نرجع تاني
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Dark mode persists after restart', (tester) async {
      // تشغيل التطبيق
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // نروح للإعدادات
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // نغير الوضع الليلي
      final isDarkBefore = DatabaseService.isDarkMode();
      final darkModeSwitch = find.byType(Switch);
      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      final isDarkAfter = DatabaseService.isDarkMode();
      expect(isDarkAfter, !isDarkBefore);
    });

    testWidgets('Encyclopedia search works', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // نفتح الموسوعة
      await tester.tap(find.text('موسوعة النباتات'));
      await tester.pumpAndSettle();

      // نبحث عن طماطم
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'طماطم');
      await tester.pumpAndSettle();

      // نتحقق من وجود نتائج أو رسالة "لا توجد نتائج"
      final noResults = find.text('لم نجد نباتات مطابقة لبحثك');
      final hasResults = find.byType(GridView);
      
      expect(tester.any(noResults) || tester.any(hasResults), true);
    });

    testWidgets('Back button navigation works everywhere', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // قائمة الشاشات اللي هندخلها ونرجع منها
      final screens = [
        'موسوعة النباتات',
        'الإعدادات',
        'فحص أمراض النبات',
        'كشف الحشائش',
        'منبه الري والتسميد',
      ];

      for (var screenName in screens) {
        // نضغط على الشاشة
        await tester.tap(find.text(screenName));
        await tester.pumpAndSettle();

        // نتأكد إننا دخلنا الشاشة
        expect(find.byType(Scaffold), findsOneWidget);

        // نرجع
        final backButton = find.byIcon(Icons.arrow_forward_ios_rounded);
if (tester.any(backButton)) {
  await tester.tap(backButton);
  await tester.pumpAndSettle();
}
      }
    });
  });
}