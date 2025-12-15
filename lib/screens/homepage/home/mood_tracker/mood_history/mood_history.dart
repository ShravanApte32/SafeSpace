// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hereforyou/utils/colormath.dart';
import 'package:hereforyou/widgets/glass_effect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;
  final List<String> _selectedIds = [];
  bool _selectionMode = false;

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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today • ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday • ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return '${DateFormat('MMM d').format(dateTime)} • ${DateFormat('h:mm a').format(dateTime)}';
    }
  }

  Widget _buildMoodCard(Map<String, dynamic> mood) {
    final color = Color(mood['color_value']);
    final emoji = mood['emoji'];
    final label = mood['label'];
    final createdAt = DateTime.parse(mood['created_at']).toLocal();
    final isSelected = _selectedIds.contains(mood['id'].toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _selectionMode = true;
            _selectedIds.add(mood['id'].toString());
          });
        },
        onTap: () {
          if (_selectionMode) {
            setState(() {
              if (_selectedIds.contains(mood['id'].toString())) {
                _selectedIds.remove(mood['id'].toString());
                if (_selectedIds.isEmpty) _selectionMode = false;
              } else {
                _selectedIds.add(mood['id'].toString());
              }
            });
          }
        },
        child: Glass(
          blur: 20,
          opacity: 0.25,
          borderRadius: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [color.withOpacity(0.25), color.withOpacity(0.15)]
                    : [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.75),
                      ],
              ),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.6)
                    : Colors.white.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Row(
              children: [
                // Selection checkbox
                if (_selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),

                // Emoji with subtle shadow
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),

                const SizedBox(width: 16),

                // Mood details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mood color dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return const SizedBox();

    // Calculate stats
    final totalMoods = moods.length;
    final today = DateTime.now();
    final todayMoods = moods.where((m) {
      final date = DateTime.parse(m['created_at']);
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;

    final mostCommonMood = _getMostCommonMood(moods);

    return Glass(
      blur: 25,
      opacity: 0.3,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F7), Color(0xFFFFF5FA)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[200]!, Colors.pink[400]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Mood Insights",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.pink[900],
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  value: totalMoods.toString(),
                  label: "Total",
                  color: Colors.pink[400]!,
                  icon: Icons.history_rounded,
                ),
                _buildStatItem(
                  value: todayMoods.toString(),
                  label: "Today",
                  color: Colors.purple[400]!,
                  icon: Icons.today_rounded,
                ),
                if (mostCommonMood != null)
                  _buildStatItem(
                    value: mostCommonMood['emoji'],
                    label: "Most Recent Mood",
                    color: Colors.orange[400]!,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _getMostCommonMood(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return null;

    final moodCounts = <String, Map<String, dynamic>>{};
    final moodOccurrences = <String, int>{};

    for (final mood in moods) {
      final label = mood['label'];
      moodOccurrences[label] = (moodOccurrences[label] ?? 0) + 1;
      if (!moodCounts.containsKey(label)) {
        moodCounts[label] = mood;
      }
    }

    if (moodOccurrences.isEmpty) return null;

    final mostCommonLabel = moodOccurrences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return moodCounts[mostCommonLabel];
  }

  Future<void> _deleteSelectedMoods() async {
    if (_selectedIds.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      // Delete moods one by one
      for (final id in _selectedIds) {
        await supabase
            .from('mood_logs')
            .delete()
            .eq('id', int.parse(id))
            .eq('user_id', userId);
      }

      if (!mounted) return;

      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
        _future = _fetchUserMoods();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_selectedIds.length} mood(s) deleted'),
          backgroundColor: Colors.pink[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error deleting moods: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete moods'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAllMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      await supabase.from('mood_logs').delete().eq('user_id', userId);

      if (!mounted) return;

      setState(() {
        _future = Future.value([]);
        _selectedIds.clear();
        _selectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ All moods cleared'),
          backgroundColor: Colors.pink[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error clearing moods: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to clear moods'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      body: SafeArea(
        child: Column(
          children: [
            // Elegant App Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.pink[400],
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Mood History",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.pink[900],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (_selectionMode)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIds.clear();
                          _selectionMode = false;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.pink[400]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Loading your journey...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.pink[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final moods = snapshot.data ?? [];
                  if (moods.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sentiment_neutral_rounded,
                                size: 48,
                                color: Colors.pink[300],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "No moods tracked yet",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.pink[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Your emotional journey starts here.\nTrack your first mood on the home page!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.pink[600],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _future = _fetchUserMoods();
                      });
                    },
                    color: Colors.pink[400],
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Stats Card
                        _buildStatsCard(moods),
                        const SizedBox(height: 24),

                        // Title
                        if (!_selectionMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.pink[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Your Mood Timeline",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.pink[900],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "(${moods.length})",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.pink[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!_selectionMode) const SizedBox(height: 16),

                        // Mood List
                        ...moods.map((mood) => _buildMoodCard(mood)).toList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: _selectionMode && _selectedIds.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.pink[400]!],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[400]!.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _deleteSelectedMoods,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                label: Text(
                  "Delete ${_selectedIds.length}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                if (isLoading || !hasData) return const SizedBox();

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFFF50057)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink[400]!.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _showClearConfirmationDialog(),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: const Text(
                      "Clear All",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showClearConfirmationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              Glass(
                blur: 30,
                opacity: 0.25,
                borderRadius: 24,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.95),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.pink[400],
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Clear All Mood History?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.pink[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "This will permanently delete all your recorded moods. This action cannot be undone.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearAllMoods();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Clear All",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
