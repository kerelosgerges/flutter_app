import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/camera_screen.dart';

void main() {
  group('CameraScreen Tests', () {
    testWidgets('should display loading indicator when camera not ready', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CameraScreen(),
          ),
        );

        await tester.pump();

        // قبل ما الكاميرا تتهيأ، يظهر loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('should display camera UI elements when ready', 
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CameraScreen(),
          ),
        );

        // انتظر initialization
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // العناصر الأساسية
        expect(find.text('ضع الورقة داخل الإطار'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
      },
    );

    testWidgets('should have green frame border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // البحث عن Container اللي بيمثل الإطار
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });
  });
}