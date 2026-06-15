import 'dart:convert';
import 'package:flutter/services.dart';

class ProtocolService {
  static Map<String, dynamic>? _protocols;
  static Map<String, dynamic>? get protocols => _protocols;

  static Future<void> loadProtocols() async {
    final jsonString = await rootBundle.loadString('assets/protocols.json');
    _protocols = json.decode(jsonString);
  }

  static Map<String, dynamic>? getProtocol(String className) {
    if (_protocols == null) return null;

    final protocols = _protocols!['protocols'] as List;
    for (final protocol in protocols) {
      if (protocol['class_name'] == className) {
        return protocol;
      }
    }
    return null;
  }

  static String getArabicDiseaseName(String className) {
    final protocol = getProtocol(className);
    return protocol?['disease_name'] ?? className;
  }

  static String getCropName(String className) {
    final protocol = getProtocol(className);
    return protocol?['crop'] ?? '';
  }
}
