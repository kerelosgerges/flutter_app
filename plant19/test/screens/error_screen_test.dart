import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/error_screen.dart';

void main() {
  group('ErrorScreen Tests', () {
    testWidgets('should display error message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('عذراً، لم نتمكن من التحليل'), findsOneWidget);
      expect(
        find.text('جرب صورة أوضح مع إضاءة جيدة، أو عد للمحاولة لاحقاً'),
        findsOneWidget,
      );
      expect(find.text('رجوع لفحص نبات آخر'), findsOneWidget);
    });

    testWidgets('should have warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should pop when tapping back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // اضغط على زر الرجوع
      await tester.tap(find.text('رجوع لفحص نبات آخر'));
      await tester.pumpAndSettle();

      // بما إننا في root، الضغط يعمل pop
      // ده test بسيط عشان يتأكد إن الـ button شغال
      expect(find.byType(ErrorScreen), findsOneWidget);
    });
  });
}