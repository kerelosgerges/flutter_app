import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/splash_screen.dart';
import 'package:Greensight/services/database_service.dart';
import 'package:Greensight/services/encyclopedia_service.dart';

void main() {
  // Mock services before running tests
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EncyclopediaService.load();
    await DatabaseService.init();
  });

  group('SplashScreen Tests', () {
    testWidgets('should display splash screen correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // انتظر شوية عشان ال animations تشتغل
      await tester.pump(const Duration(milliseconds: 500));

      // تحقق إن الـ logo موجود
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      
      // تحقق إن النص "دكتور النبات" موجود
      expect(find.text('دكتور النبات'), findsOneWidget);
      expect(find.text('صحة نباتك في يدك'), findsOneWidget);
      
      // تحقق إن شريط التحميل موجود
      expect(find.text('جاري تحميل نماذج الذكاء الاصطناعي...'), findsOneWidget);
    });

    testWidgets('should navigate to HomeScreen after loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // انتظر 4 ثواني (زي ما عندك في الكود)
      await tester.pump(const Duration(seconds: 5));

      // بعد 5 ثواني، المفروض يروح للـ HomeScreen
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}