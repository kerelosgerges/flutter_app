import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart'; // 👈 إضافة الخدمة الحقيقية
import 'services/encyclopedia_service.dart';

// عرف متغير global
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

void main() async {
  // ✅ لازم WidgetsFlutterBinding.ensureInitialized()
  WidgetsFlutterBinding.ensureInitialized();
  await EncyclopediaService.load(); // تحميل البيانات مسبقاً
  // ✅ Initialize Database + Notifications
  await DatabaseService.init();
  darkModeNotifier.value = DatabaseService.isDarkMode(); // حمل القيمة المحفوظة

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Plant Doctor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Cairo',
            primarySwatch: Colors.green,
            // حافظتلك على اللون الأسود اللي إنت مختاره للسقالة
            scaffoldBackgroundColor: Colors.black,
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          darkTheme: ThemeData.dark(), // أو ثيمك الخاص
          // البداية هتكون من شاشة الـ Splash اللي عملناها سوا
          home: const SplashScreen(),
        );
      },
    );
  }
}
