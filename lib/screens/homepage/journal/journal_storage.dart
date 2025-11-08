// ignore_for_file: avoid_print

import 'package:hereforyou/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JournalStorage {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _userIdKey = 'user_id';

  static Future<List<JournalEntry>> getAll() async {
    try {
      final userId = await _getUserId();
      print('Fetching journals for user: $userId');

      final response = await _supabase
          .from('journals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Raw response: $response');
      print('Response type: ${response.runtimeType}');

      final entries = (response as List).map((e) {
        print('Mapping entry: $e');
        return JournalEntry.fromMap(e);
      }).toList();

      return entries;
    } catch (e) {
      print('Error fetching journals: $e');
      return [];
    }
  }

  static Future<void> add(JournalEntry entry) async {
    try {
      final userId = await _getUserId();

      print('Preparing to insert journal entry:');
      print('User ID: $userId (type: ${userId.runtimeType})');
      print('Content: ${entry.text}');
      print('Mood: ${entry.mood}');
      print(
        'Sentiment: ${entry.sentiment} (type: ${entry.sentiment.runtimeType})',
      );
      print('Created At: ${entry.at.toUtc().toIso8601String()}');

      final insertData = {
        'user_id': userId,
        'content': entry.text,
        'mood': entry.mood,
        'sentiment_score': entry.sentiment,
        'created_at': entry.at.toUtc().toIso8601String(),
        'is_private': entry.isPrivate,
      };

      print('Insert data: $insertData');

      final response = await _supabase
          .from('journals')
          .insert(insertData)
          .select();

      print('Insert successful: $response');
    } catch (e, stackTrace) {
      print('Error adding journal: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> update(JournalEntry entry) async {
    try {
      final userId = await _getUserId();

      await _supabase
          .from('journals')
          .update({
            'content': entry.text,
            'mood': entry.mood,
            'sentiment_score': entry.sentiment,
            'created_at': entry.at.toUtc().toIso8601String(),
            'is_private': entry.isPrivate,
          })
          .eq('id', int.parse(entry.id))
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating journal: $e');
      rethrow;
    }
  }

  static Future<void> remove(String id) async {
    try {
      final userId = await _getUserId();

      await _supabase
          .from('journals')
          .delete()
          .eq('id', int.parse(id))
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting journal: $e');
      rethrow;
    }
  }

  static Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt(_userIdKey);

    if (userId == null) {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }
      userId = int.parse(user.id.hashCode.toString().substring(0, 8));
      await prefs.setInt(_userIdKey, userId);
    }

    return userId;
  }
}
