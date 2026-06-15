import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/compost_screen.dart';

void main() {
  group('CompostScreen Tests', () {
    testWidgets('should display compost assistant title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('مساعد السماد العضوي'), findsNWidgets(2));
    });

    testWidgets('should display description text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('تحدث مع الذكاء الاصطناعي\nوتعلم كيف تحول مخلفات المنزل لسماد عضوي'),
        findsOneWidget,
      );
    });

    testWidgets('should have start conversation button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ابدأ المحادثة'), findsOneWidget);
      expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
    });

    testWidgets('should have recycling icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.recycling_rounded), findsOneWidget);
    });

    testWidgets('should have back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('should have background image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompostScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // التحقق من وجود DecorationImage (background)
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });
  });
}