import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/billing_line.dart';

class BillingLocalStore {
  BillingLocalStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _linesKey = 'facturation.lines.v1';

  final SharedPreferencesAsync _preferences;

  Future<List<BillingLine>?> loadLines() async {
    final raw = await _preferences.getString(_linesKey);
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;

    return decoded
        .whereType<Map>()
        .map((item) => BillingLine.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveLines(List<BillingLine> lines) async {
    final encoded = jsonEncode(lines.map((line) => line.toJson()).toList());
    await _preferences.setString(_linesKey, encoded);
  }

  Future<void> clear() async {
    await _preferences.remove(_linesKey);
  }
}
