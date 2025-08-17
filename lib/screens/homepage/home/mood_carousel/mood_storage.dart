import 'dart:convert';

import 'package:hereforyou/models/mood_logs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodStorage {
  static const _key = 'mood_logs';

  static Future<List<MoodLog>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    return raw
        .map((s) => MoodLog.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  static Future<void> add(MoodLog log) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    list.add(jsonEncode(log.toMap()));
    await sp.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
