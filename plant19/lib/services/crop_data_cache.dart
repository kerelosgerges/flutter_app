import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class CropDataCache {
  // نخزن البيانات هنا عشان ما نحملهاش كل مرة
  static List<dynamic>? _cachedCrops;

  /// دالة مساعدة (top-level) لفك تشفير الـ JSON في Isolate منفصل
  static Map<String, dynamic> _decodeJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// تحميل المحاصيل: أول مرة من الملف و Parsing، بعد كده من الذاكرة
  static Future<List<dynamic>> getCrops() async {
    if (_cachedCrops != null) {
      return _cachedCrops!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/crop_reminders.json');

      // ✅ فك التشفير في Isolate منفصل (مش على Main Thread)
      final Map<String, dynamic> data = await compute(_decodeJson, jsonString);

      _cachedCrops = data['crop_reminders'] ?? [];
      return _cachedCrops!;
    } catch (e) {
      debugPrint('❌ فشل تحميل المحاصيل: $e');
      _cachedCrops = []; // منرجعش null
      return _cachedCrops!;
    }
  }
}
