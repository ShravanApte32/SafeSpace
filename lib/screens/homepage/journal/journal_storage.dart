import 'dart:convert';

import 'package:hereforyou/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalStorage {
  static const _key = 'journal_entries_v1';

  static Future<List<JournalEntry>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = sp.getString(_key);
    if (jsonStr == null) return [];
    final List list = json.decode(jsonStr) as List;
    final entries = list.map((e) => JournalEntry.fromMap(e)).toList();
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  static Future<void> saveAll(List<JournalEntry> entries) async {
    final sp = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toMap()).toList();
    await sp.setString(_key, json.encode(list));
  }

  static Future<void> add(JournalEntry entry) async {
    final list = await getAll();
    list.insert(0, entry);
    await saveAll(list);
  }

  static Future<void> update(JournalEntry entry) async {
    final list = await getAll();
    final i = list.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      list[i] = entry;
      list.sort((a, b) => b.at.compareTo(a.at));
      await saveAll(list);
    }
  }

  static Future<void> remove(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }
}
