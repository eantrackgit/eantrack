import 'dart:convert';

import 'package:flutter/services.dart';

abstract final class AppVersion {
  static const _assetPath = 'assets/config/version.json';
  static String _current = '0.0.0';

  static String get current => _current;
  static String get label => 'v$_current';

  static Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final version = (jsonMap['version'] as String?)?.trim();
      if (version != null && version.isNotEmpty) {
        _current = version;
      }
    } catch (_) {
      _current = '0.0.0';
    }
  }
}
