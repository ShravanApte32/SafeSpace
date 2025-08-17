// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hereforyou/models/mood_logs.dart';
import 'package:hereforyou/screens/homepage/home/mood_carousel/mood_storage.dart';

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
  late Future<List<MoodLog>> _future;

  @override
  void initState() {
    super.initState();
    _future = MoodStorage.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mood History")),
      body: FutureBuilder<List<MoodLog>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          if (data.isEmpty) {
            return const Center(child: Text("No moods logged yet."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = data[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Color(m.colorValue).withOpacity(0.12),
                leading: Text(m.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(
                  m.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  "${m.at.toLocal()}".split('.').first.replaceFirst('T', ' '),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Clear persistent storage
          await MoodStorage.clear();

          if (!mounted) return;

          // Instant UI clear
          setState(() {
            _future = Future.value([]); // Empty list instantly
          });
        },

        label: const Text("Clear"),
        icon: const Icon(Icons.delete),
      ),
    );
  }
}
