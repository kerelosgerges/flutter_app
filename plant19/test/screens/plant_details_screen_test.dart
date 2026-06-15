import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/plant_details_screen.dart';
import 'package:Greensight/services/database_service.dart';
import 'package:Greensight/services/encyclopedia_service.dart';

void main() {
  group('PlantDetailsScreen Tests', () {
    // بيانات نبات وهمية للاختبار
    final mockCrop = {
      'id': 'tomato',
      'name_ar': 'طماطم',
      'importance_benefits': 'غنية بفيتامين C ومضادات الأكسدة',
      'main_challenges': ['الذبول', 'اللفحة المبكرة', 'نطاطات الأوراق'],
      'common_diseases': ['اللفحة المبكرة', 'اللفحة المتأخرة', 'تبقع الأوراق'],
      'common_pests': ['من', 'تربس', 'ذبابة بيضاء'],
      'climate_soil': 'درجة حرارة 20-25 درجة مئوية، تربة جيدة الصرف',
      'watering': 'ري معتدل كل 3-4 أيام',
      'fertilization': 'سماد متوازن NPK كل أسبوعين',
      'maturity': '90-120 يوم من الزراعة',
      'harvesting_tips': 'يُحصد عند نضج 70% من الثمار',
      'economic_notes': 'يعتبر الطماطم من المحاصيل الاقتصادية الهامة',
    };

    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await EncyclopediaService.load();
      await DatabaseService.init();
    });

    testWidgets('should display plant name correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('طماطم'), findsOneWidget);
    });

    testWidgets('should display tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('نظرة عامة'), findsOneWidget);
      expect(find.text('الأمراض والآفات'), findsOneWidget);
      expect(find.text('الزراعة والري'), findsOneWidget);
      expect(find.text('الإرشادات'), findsOneWidget);
    });

    testWidgets('should display bookmark button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });

    testWidgets('should display diagnose button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('افحص نباتك الآن بالذكاء الاصطناعي'),
        findsOneWidget,
      );
    });

    testWidgets('should display stats cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      // 2 أمراض + آفات
      expect(find.text('2 أمراض'), findsOneWidget);
      expect(find.text('دورة النمو'), findsOneWidget);
      expect(find.text('الري'), findsOneWidget);
    });

    testWidgets('should display overview content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('عن النبات'), findsOneWidget);
      expect(
        find.text('غنية بفيتامين C ومضادات الأكسدة'),
        findsOneWidget,
      );
      expect(find.text('التحديات والمخاطر'), findsOneWidget);
      expect(find.text('الذبول'), findsOneWidget);
      expect(find.text('اللفحة المبكرة'), findsOneWidget);
    });

    testWidgets('should toggle bookmark when pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlantDetailsScreen(crop: mockCrop),
        ),
      );

      await tester.pumpAndSettle();

      // اضغط على زر الحفظ
      final bookmarkButton = find.byIcon(Icons.bookmark_border_rounded);
      await tester.tap(bookmarkButton);
      await tester.pumpAndSettle();

      // يتغير الأيقونة
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });
}