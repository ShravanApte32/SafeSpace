// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUserMoods();
  }

  Future<List<Map<String, dynamic>>> _fetchUserMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return [];

      final response = await supabase
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching moods: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mood History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("No moods logged yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = data[i];
              final color = Color(m['color_value']);
              final emoji = m['emoji'];
              final label = m['label'];
              final createdAt = DateTime.parse(m['created_at']).toLocal();

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: color.withOpacity(0.12),
                leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(createdAt.toString().split('.').first),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getInt('user_id');
            if (userId == null) return;

            await supabase.from('mood_logs').delete().eq('user_id', userId);

            if (!mounted) return;

            // ✅ Just clear state — don't return a Future from inside setState
            setState(() {
              _future = Future.value([]); // Clear list in UI
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Mood history cleared.')),
            );
          } catch (e) {
            print('❌ Error clearing moods: $e');
          }
        },

        label: const Text("Clear"),
        icon: const Icon(Icons.delete),
      ),
    );
  }
}
