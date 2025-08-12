import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class JsonCache {
  static const _boxName = 'hublee_cache';
  static Box<String>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  static Future<void> putJson(String key, Map<String, dynamic> value) async {
    await _box!.put(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final raw = _box!.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clear() async => _box?.clear();
}
