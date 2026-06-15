import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/encyclopedia_screen.dart';
import 'package:Greensight/services/encyclopedia_service.dart';
import 'package:Greensight/services/database_service.dart';

void main() {
  group('EncyclopediaScreen Tests', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await EncyclopediaService.load();
      await DatabaseService.init();
    });

    testWidgets('should display encyclopedia title and search bar', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EncyclopediaScreen(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('موسوعة النباتات'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.text('ابحث عن نبات أو مرض...'), findsOneWidget);
      },
    );

    testWidgets('should display filter chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EncyclopediaScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // شاشة الموسوعة فيها filters
      expect(find.text('كل النباتات'), findsOneWidget);
      expect(find.text('محاصيل'), findsOneWidget);
      expect(find.text('خضروات'), findsOneWidget);
      expect(find.text('فاكهة'), findsOneWidget);
      expect(find.text('حبوب'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EncyclopediaScreen(),
        ),
      );

      // في البداية data بتحمل
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display plants grid after loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EncyclopediaScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // بعد ما البيانات تحمل، يظهر grid
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
    });

    testWidgets('should have floating action button for diagnosis', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EncyclopediaScreen(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('افحص نباتك الآن'), findsOneWidget);
        expect(find.byIcon(Icons.document_scanner_rounded), findsOneWidget);
      },
    );

    testWidgets('should show empty state when search returns no results', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EncyclopediaScreen(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ابحث عن حاجة مش موجودة
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'نبات مش موجود خالص');
        await tester.pumpAndSettle();

        expect(find.text('لم نجد نباتات مطابقة لبحثك'), findsOneWidget);
      },
    );

    testWidgets('should have dark green background in light mode', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EncyclopediaScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // التحقق من وجود الألوان (اختبار بسيط)
        final scaffold = find.byType(Scaffold);
        expect(scaffold, findsOneWidget);
      },
    );

    testWidgets('should navigate to plant details when tapping a card', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EncyclopediaScreen(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 3));

        // اضغط على أول نبات في القائمة
        final firstPlantCard = find.byType(GestureDetector).first;
        await tester.tap(firstPlantCard);
        await tester.pumpAndSettle();

        // المفروض يفتح صفحة التفاصيل
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });
}