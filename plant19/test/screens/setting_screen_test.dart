import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Greensight/screens/setting_screen.dart';
import 'package:Greensight/services/database_service.dart';

void main() {
  group('SettingScreen Tests', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await DatabaseService.init();
    });

    testWidgets('should display settings title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('should display reminders section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('منبهاتي'), findsOneWidget);
    });

    testWidgets('should display bookmarks section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('نباتاتي المحفوظة'), findsOneWidget);
    });

    testWidgets('should display general settings section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('الإعدادات العامة'), findsOneWidget);
      expect(find.text('الوضع الليلي'), findsOneWidget);
      expect(find.text('اللغة'), findsOneWidget);
      expect(find.text('عن التطبيق'), findsOneWidget);
    });

    testWidgets('should have dark mode switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should have add reminder button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('إضافة منبه جديد'), findsOneWidget);
    });

    testWidgets('should have back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });
}