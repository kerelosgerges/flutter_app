import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/weed_screen.dart';

void main() {
  group('WeedScreen Tests', () {
    testWidgets('should display weed detection UI when camera is off', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: WeedScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // قبل تشغيل الكاميرا
        expect(find.text('كشف الحشائش'), findsNWidgets(2)); // title و header
        expect(
          find.text('وجّه الكاميرا نحو الحقل\nوسنكتشف الحشائش الموجودة'),
          findsOneWidget,
        );
        expect(find.text('افتح الكاميرا'), findsOneWidget);
      },
    );

    testWidgets('should have radar icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WeedScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radar_rounded), findsOneWidget);
    });

    testWidgets('should have back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WeedScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('should have open camera button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WeedScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('افتح الكاميرا'), findsOneWidget);
    });
  });
}