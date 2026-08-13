import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin JSON-over-SharedPreferences wrapper, mirroring the AsyncStorage +
/// JSON pattern the original prototype used for local persistence.
class LocalStore {
  const LocalStore();

  Future<Map<String, dynamic>?> readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore and treat as absent.
    }

    return null;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
