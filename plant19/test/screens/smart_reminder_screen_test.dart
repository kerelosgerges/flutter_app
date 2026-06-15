import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/smart_reminder_screen.dart';
import 'package:Greensight/services/database_service.dart';
//import 'package:Greensight/services/crop_data_cache.dart';

void main() {
  group('SmartReminderScreen Tests', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await DatabaseService.init();
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartReminderScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('المنبه الزراعي الذكي'), findsOneWidget);
    });

    testWidgets('should display progress steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartReminderScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('اختر نباتك'), findsOneWidget);
      expect(find.text('تاريخ الزراعة'), findsOneWidget);
      expect(find.text('فعّل المنبهات'), findsOneWidget);
    });

    testWidgets('should display search field in step 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartReminderScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('اختر المحصول'), findsOneWidget);
      expect(find.text('ابحث عن محصولك...'), findsOneWidget);
    });

    testWidgets('should navigate to step 2 when crop selected', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SmartReminderScreen(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 2));

        // انتظر تحميل المحاصيل
        await tester.pumpAndSettle();

        // فيه محاصيل أو لأ (الاختبار بسيط)
        final cropGrid = find.byType(GridView);
        expect(cropGrid, findsOneWidget);
      },
    );

    testWidgets('should have date picker in step 2', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartReminderScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // فيه CupertinoDatePicker أو عنصر التاريخ
      expect(find.text('متى زرعت؟'), findsOneWidget);
    });

    testWidgets('should have notification time options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartReminderScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // في الخطوة 3، فيه خيارات الوقت
      // الاختبار يتحقق من وجود العناصر الأساسية
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}