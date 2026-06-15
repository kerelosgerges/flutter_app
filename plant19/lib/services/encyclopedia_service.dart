import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class EncyclopediaService {
  static List<dynamic>? _crops;

  static Future<void> load() async {
    // ✅ إذا كانت البيانات محملة بالفعل، لا تفعل شيئاً
    if (_crops != null) return;

    try {
      final jsonStr =
          await rootBundle.loadString('assets/crop_encyclopedia.json');
      final data = await compute(jsonDecode, jsonStr);
      _crops = data['crop_encyclopedia'] as List;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل ملف الموسوعة: $e');
      _crops = [];
    }
  }

  static List<dynamic> getAll() => _crops ?? [];

  static dynamic getById(String id) {
    return _crops?.firstWhere((crop) => crop['id'] == id, orElse: () => null) ??
        {};
  }

  static List<dynamic> search(String query) {
    if (_crops == null) return [];
    final q = query.toLowerCase();
    return _crops!
        .where((c) =>
            c['name_ar'].toLowerCase().contains(q) ||
            c['id'].toLowerCase().contains(q))
        .toList();
  }
}
