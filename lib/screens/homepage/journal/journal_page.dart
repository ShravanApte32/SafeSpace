// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unnecessary_brace_in_string_interps, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hereforyou/models/journal_entry.dart';
import 'package:hereforyou/screens/homepage/journal/journal_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  List<JournalEntry> _entries = [];
  bool _loading = true;
  bool _private = false;
  String _selectedMood = '😌';
  String _prompt = '';
  final List<String> _prompts = [
    "What are you grateful for today?",
    "What bothered you today and why?",
    "One small win from today?",
    "If you could talk to yourself 5 years ago, what would you say?",
    "Describe your current feeling in three words.",
    "What would make tomorrow a better day?",
  ];
  String _search = '';
  String _filterMood = 'All';
  late AnimationController _saveAnim;
  late AnimationController _streakAnim;
  late AnimationController _fadeAnim;
  final FocusNode _textFieldFocus = FocusNode();
  bool _showComposer = true;

  @override
  void initState() {
    super.initState();
    _saveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _streakAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _load();
    _prompt = _prompts[DateTime.now().day % _prompts.length];
  }

  @override
  void dispose() {
    _controller.dispose();
    _saveAnim.dispose();
    _streakAnim.dispose();
    _fadeAnim.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await JournalStorage.getAll();
      setState(() {
        _entries = data;
        _loading = false;
      });
      _debugHeatmap(); // Add this line
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading journals: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _simpleSentiment(String text) {
    if (text.isEmpty) return 0.0;

    // Enhanced word lists with weights
    final Map<String, double> positiveWords = {
      'excellent': 3.0,
      'amazing': 2.5,
      'wonderful': 2.5,
      'fantastic': 2.5,
      'great': 2.0,
      'good': 1.5,
      'happy': 2.0,
      'joy': 2.0,
      'love': 2.5,
      'calm': 1.5,
      'peaceful': 1.5,
      'relaxed': 1.5,
      'grateful': 2.0,
      'thankful': 2.0,
      'blessed': 2.0,
      'win': 1.5,
      'success': 2.0,
      'achievement': 1.5,
      'progress': 1.0,
      'hope': 1.5,
      'hopeful': 1.5,
      'excited': 2.0,
      'proud': 2.0,
      'confident': 1.5,
      'optimistic': 1.5,
      'better': 1.0,
      'improved': 1.0,
      'nice': 1.0,
      'pleasant': 1.0,
      'beautiful': 1.5,
      'awesome': 2.0,
      'brilliant': 2.0,
      'perfect': 2.5,
      'yay': 1.5,
      'yeah': 1.0,
      'wow': 1.5,
      'smile': 1.0,
      'laughter': 1.5,
    };

    final Map<String, double> negativeWords = {
      'terrible': 3.0,
      'awful': 2.5,
      'horrible': 2.5,
      'hate': 2.5,
      'bad': 2.0,
      'sad': 2.0,
      'angry': 2.0,
      'mad': 2.0,
      'frustrated': 2.0,
      'stress': 2.0,
      'stressed': 2.0,
      'anxious': 2.0,
      'anxiety': 2.0,
      'worried': 1.5,
      'nervous': 1.5,
      'scared': 2.0,
      'afraid': 2.0,
      'tired': 1.5,
      'exhausted': 2.0,
      'depressed': 2.5,
      'depression': 2.5,
      'alone': 2.0,
      'lonely': 2.0,
      'hurt': 2.0,
      'pain': 2.0,
      'suffering': 2.5,
      'failure': 2.0,
      'failed': 2.0,
      'lost': 1.5,
      'confused': 1.5,
      'disappointed': 2.0,
      'upset': 1.5,
      'annoyed': 1.5,
      'irritated': 1.5,
      'ugh': 1.5,
      'sigh': 1.0,
      'cry': 2.0,
      'tears': 2.0,
      'regret': 2.0,
    };

    // Negation words that flip the sentiment of following words
    final negationWords = {
      'not',
      'no',
      'never',
      'nothing',
      'without',
      'cannot',
    };

    final t = text.toLowerCase();
    double score = 0.0;
    final words = t.split(RegExp(r'\s+'));
    final wordCount = words.length;

    bool nextWordNegated = false;

    for (int i = 0; i < words.length; i++) {
      String word = words[i].replaceAll(RegExp(r'[^\w]'), '');

      // Check for negation words
      if (negationWords.contains(word)) {
        nextWordNegated = true;
        continue;
      }

      // Check positive words
      if (positiveWords.containsKey(word)) {
        double wordScore = positiveWords[word]!;
        score += nextWordNegated ? -wordScore : wordScore;
        nextWordNegated = false;
      }

      // Check negative words
      if (negativeWords.containsKey(word)) {
        double wordScore = negativeWords[word]!;
        score += nextWordNegated ? wordScore : -wordScore; // Note the flip here
        nextWordNegated = false;
      }

      // Reset negation after one word (simple approach)
      if (nextWordNegated && !negationWords.contains(word)) {
        nextWordNegated = false;
      }
    }

    // Punctuation analysis
    final exclamationCount = '!'.allMatches(t).length;
    final questionCount = '?'.allMatches(t).length;
    final ellipsisCount = '...'.allMatches(t).length;

    // Exclamation points can amplify sentiment
    if (exclamationCount > 0) {
      final amplification =
          exclamationCount * 0.1 * (score.abs() > 0 ? score.sign : 1);
      score += amplification;
    }

    // Questions might indicate uncertainty
    if (questionCount > 2) {
      score *= 0.8; // Reduce confidence for many questions
    }

    // Ellipsis often indicates hesitation or trailing off
    if (ellipsisCount > 0) {
      score *= 0.7;
    }

    // Capitalized words can indicate strong emotion
    final capitalizedWords = RegExp(r'\b[A-Z][a-z]+\b').allMatches(text).length;
    if (capitalizedWords > 0) {
      final emphasis =
          capitalizedWords * 0.05 * (score.abs() > 0 ? score.sign : 1);
      score += emphasis;
    }

    // Normalize by word count (but don't over-normalize short texts)
    final normalizationFactor = wordCount > 5 ? wordCount : 5.0;
    double normalizedScore = score / normalizationFactor;

    // Apply non-linear scaling to make extreme scores more rare
    if (normalizedScore > 0) {
      normalizedScore = 1.0 - (1.0 / (1.0 + normalizedScore));
    } else if (normalizedScore < 0) {
      normalizedScore = -1.0 + (1.0 / (1.0 - normalizedScore));
    }

    return normalizedScore.clamp(-1.0, 1.0);
  }

  String getSentimentLabel(double sentiment) {
    if (sentiment > 0.3) return 'Very Positive';
    if (sentiment > 0.1) return 'Positive';
    if (sentiment > -0.1) return 'Neutral';
    if (sentiment > -0.3) return 'Negative';
    return 'Very Negative';
  }

  Future<void> _save({String? editId}) async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Write something to save.")));
      return;
    }

    final sentiment = _simpleSentiment(txt);

    try {
      if (editId == null) {
        final entry = JournalEntry(
          id: '0', // Temporary ID, will be replaced by database
          text: txt,
          at: DateTime.now(),
          mood: _selectedMood,
          sentiment: sentiment,
          isPrivate: _private,
        );
        await JournalStorage.add(entry);
        await _load(); // Reload to get all entries with proper IDs
      } else {
        final i = _entries.indexWhere((e) => e.id == editId);
        if (i >= 0) {
          // Create a new entry object with updated values instead of mutating fields
          final updated = JournalEntry(
            id: _entries[i].id,
            text: txt,
            at: DateTime.now(),
            mood: _selectedMood,
            sentiment: sentiment,
            isPrivate: _private,
          );
          _entries[i] = updated;
          await JournalStorage.update(updated);
          await _load(); // Reload to refresh the list
        }
      }

      _controller.clear();
      _saveAnim.forward(from: 0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text("Entry saved successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving entry: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _delete(String id) async {
    final deletedEntry = _entries.firstWhere((e) => e.id == id);
    final deletedIndex = _entries.indexWhere((e) => e.id == id);

    // Remove from local state only
    setState(() => _entries.removeWhere((e) => e.id == id));

    // Show undo snackbar
    final snackBar = SnackBar(
      content: const Text("Entry deleted"),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () {
          // Restore to local state - database was never touched
          setState(() {
            _entries.insert(deletedIndex, deletedEntry);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entry restored"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Wait for the snackbar duration to see if user clicks undo
    await Future.delayed(const Duration(seconds: 5));

    // If we get here and the entry is still not in the list, delete from database
    if (mounted && !_entries.any((e) => e.id == id)) {
      await JournalStorage.remove(id);
      print("Entry permanently deleted from database");
    }
  }

  int _calcStreak() {
    if (_entries.isEmpty) return 0;

    // Get unique dates (just year-month-day) when entries were made
    final entryDates = _entries
        .map((e) => DateTime(e.at.year, e.at.month, e.at.day))
        .toSet()
        .toList();

    // Sort dates in descending order (most recent first)
    entryDates.sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final latestEntryDate = entryDates.first;
    final isToday = _isSameDay(latestEntryDate, today);
    final isYesterday = _isSameDay(latestEntryDate, yesterday);

    // If latest entry is neither today nor yesterday, streak is broken
    if (!isToday && !isYesterday) return 0;

    // Start counting from the latest entry day
    int streak = 1; // Count the latest entry day
    DateTime currentDay = isToday ? today : yesterday;

    // Check consecutive days backwards starting from day before latest entry
    currentDay = currentDay.subtract(const Duration(days: 1));

    while (true) {
      // Check if there's an entry for this previous day
      final hasEntryForDay = entryDates.any(
        (date) => _isSameDay(date, currentDay),
      );

      if (hasEntryForDay) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  // Helper method to compare if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<DateTime, int> _heatMapCounts() {
    final Map<DateTime, int> map = {};
    final now = DateTime.now();

    // Get the first day of current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    // Get the last day of current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Initialize all dates in current month with 0
    DateTime currentDate = firstDayOfMonth;
    while (currentDate.isBefore(lastDayOfMonth) ||
        _isSameDay(currentDate, lastDayOfMonth)) {
      map[DateTime(currentDate.year, currentDate.month, currentDate.day)] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Count entries
    for (final entry in _entries) {
      final entryDate = DateTime(entry.at.year, entry.at.month, entry.at.day);
      if (map.containsKey(entryDate)) {
        map[entryDate] = map[entryDate]! + 1;
      }
    }

    return map;
  }

  void _debugHeatmap() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    print('=== HEATMAP DEBUG ===');
    print('Today: ${DateFormat('EEEE, MMM d, yyyy').format(now)}');
    print('Month: ${DateFormat('MMMM yyyy').format(now)}');
    print(
      'Month range: ${DateFormat('MMM d').format(firstDayOfMonth)} - ${DateFormat('MMM d').format(lastDayOfMonth)}',
    );
    print('Today has entry: ${_entries.any((e) => _isSameDay(e.at, now))}');

    // Debug: Check if today is in the heatmap
    final heatmap = _heatMapCounts();
    print('Today in heatmap: ${heatmap.containsKey(today)}');
    print('Today count: ${heatmap[today]}');

    // Count total entries in heatmap
    final totalEntriesInHeatmap = heatmap.values
        .where((count) => count > 0)
        .length;
    print('Total days with entries this month: $totalEntriesInHeatmap');
  }

  void _pickPromptRandom() {
    setState(() => _prompt = (_prompts..shuffle()).first);
  }

  List<JournalEntry> get _visibleEntries {
    var list = _entries;
    if (_filterMood != 'All') {
      list = list.where((e) => e.mood == _filterMood).toList();
    }
    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((e) => e.text.toLowerCase().contains(s)).toList();
    }
    return list;
  }

  Future<void> _openEdit(JournalEntry e) async {
    _controller.text = e.text;
    _selectedMood = e.mood;

    // Animate opening the editor
    setState(() => _showComposer = false);
    await Future.delayed(const Duration(milliseconds: 200));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Entry',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _moodList().map((m) {
                            final isSel = m == _selectedMood;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? _moodColor(m).withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel
                                        ? _moodColor(m)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: _moodColor(m),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        maxLines: 6,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText: 'Update your thoughts...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _save(editId: e.id);
                                Navigator.pop(ctx);
                                setState(() => _showComposer = true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => setState(() => _showComposer = true));
  }

  List<String> _moodList() => ['😄', '🙂', '😌', '😐', '😢', '😡', '😴'];

  Color _moodColor(String mood) {
    switch (mood) {
      case '😄':
        return Colors.green;
      case '🙂':
        return Colors.lightGreen;
      case '😌':
        return Colors.blue;
      case '😐':
        return Colors.grey;
      case '😢':
        return Colors.indigo;
      case '😡':
        return Colors.red;
      case '😴':
        return Colors.deepPurple;
      default:
        return Colors.pink;
    }
  }

  Color _heatColorForCount(int count) {
    if (count <= 0) return Colors.grey.shade200;
    if (count == 1) return const Color(0xFFFFB6C1); // Light pink
    if (count == 2) return const Color(0xFFFF91A4); // Medium light pink
    if (count == 3) return const Color(0xFFFF6B8B); // Medium pink
    if (count == 4) return const Color(0xFFFF4777); // Pink
    return const Color(0xFFFF2D62); // Deep pink
  }

  Widget _buildHeader() {
    final streak = _calcStreak();
    final last = _entries.isNotEmpty
        ? DateFormat('EEE, MMM d').format(_entries.first.at)
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last entry: $last',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _streakAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + _streakAnim.value * 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade300, Colors.pink.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade200.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Streak',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$streak 🔥',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _prompt,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _pickPromptRandom,
                    icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: // Replace the mood selection section with:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Select Mood:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moodList().map((m) {
                        final selected = m == _selectedMood;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _moodColor(m).withOpacity(0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? _moodColor(m)
                                    : Colors.transparent,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 24,
                                color: _moodColor(m),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showComposer
          ? Container(
              key: const ValueKey('composer'),
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _textFieldFocus,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write freely. Your journal is private.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      // suffixIcon: IconButton(
                      //   tooltip: 'Use prompt',
                      //   icon: Icon(
                      //     Icons.lightbulb_outline,
                      //     color: Colors.amber.shade600,
                      //   ),
                      //   onPressed: () {
                      //     _controller.text =
                      //         (_controller.text.isEmpty
                      //             ? ''
                      //             : _controller.text + '\n\n') +
                      //         _prompt;
                      //     _controller.selection = TextSelection.fromPosition(
                      //       TextPosition(offset: _controller.text.length),
                      //     );
                      //   },
                      // ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Word count
                      Expanded(
                        child: Text(
                          '${_controller.text.trim().split(RegExp(r"\s+")).where((w) => w.isNotEmpty).length} words',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Toggle privacy',
                        onPressed: () => setState(() => _private = !_private),
                        icon: Icon(
                          _private ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.08).animate(
                          CurvedAnimation(
                            parent: _saveAnim,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _controller.text.trim().isEmpty
                              ? null
                              : _save,
                          icon: const Icon(Icons.save_alt, size: 20),
                          label: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox(key: ValueKey('empty-composer')),
    );
  }

  Widget _buildHeatMap() {
    final map = _heatMapCounts();
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Writing Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMMM yyyy').format(now),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // REMOVED the duplicate month title here
              // Calendar grid
              _buildCalendarGrid(map, now),
              const SizedBox(height: 12),
              // Legend
              _buildSimpleLegend(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, int> map, DateTime now) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final gridRows = <Widget>[];
    final today = DateTime(now.year, now.month, now.day);

    // Get first day of month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    // Find the Monday of the week containing the first day
    final daysFromMonday = (firstDayOfMonth.weekday - 1) % 7;
    final calendarStart = firstDayOfMonth.subtract(
      Duration(days: daysFromMonday),
    );

    // Get last day of month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    // Find the Sunday of the week containing the last day
    final daysToSunday = (7 - lastDayOfMonth.weekday) % 7;
    final calendarEnd = lastDayOfMonth.add(Duration(days: daysToSunday));

    // Build weekday headers
    final headerRow = <Widget>[];
    for (final weekday in weekdays) {
      headerRow.add(
        Expanded(
          child: Text(
            weekday,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    gridRows.add(Row(children: headerRow));
    gridRows.add(const SizedBox(height: 8));

    // Build calendar rows
    DateTime currentDate = calendarStart;
    while (currentDate.isBefore(calendarEnd) ||
        _isSameDay(currentDate, calendarEnd)) {
      final weekCells = <Widget>[];

      // Build one week (7 days)
      for (int i = 0; i < 7; i++) {
        final count =
            map[DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
            )] ??
            0;
        final isToday = _isSameDay(currentDate, today);
        final isCurrentMonth = currentDate.month == now.month;

        weekCells.add(
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(1),
              height: 20,
              child: Tooltip(
                message: isCurrentMonth
                    ? '${DateFormat('EEE, MMM d').format(currentDate)}\n${count} entr${count == 1 ? 'y' : 'ies'}'
                    : DateFormat('MMM d').format(currentDate),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth
                        ? _heatColorForCount(count)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(2),
                    border: isToday
                        ? Border.all(color: Colors.pink.shade400, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      currentDate.day.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentMonth
                            ? (count > 0 ? Colors.white : Colors.grey.shade700)
                            : Colors.grey.shade400,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }

      gridRows.add(Row(children: weekCells));
      gridRows.add(const SizedBox(height: 4));
    }

    return Column(children: gridRows);
  }

  Widget _buildSimpleLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        for (int i = 0; i <= 4; i++) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _heatColorForCount(i),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i < 4) const SizedBox(width: 2),
        ],
        const SizedBox(width: 8),
        Text(
          'More',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              hintText: 'Search entries...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Filter by mood:',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _filterMood,
                  items: ['All', ..._moodList()]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _filterMood = v ?? 'All'),
                  style: const TextStyle(fontSize: 16),
                  borderRadius: BorderRadius.circular(12),
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry e, int index) {
    final df = DateFormat('MMM d, h:mm a');
    final sentimentLabel = getSentimentLabel(e.sentiment);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _fadeAnim,
                curve: Interval(
                  (0.1 * index).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (!e.isPrivate) _openEdit(e);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _moodColor(e.mood).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.mood,
                            style: TextStyle(
                              fontSize: 20,
                              color: _moodColor(e.mood),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            df.format(e.at),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        // 👇 Hide the 3-dot menu if private
                        if (!e.isPrivate)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey.shade600,
                            ),
                            onSelected: (val) {
                              if (val == 'edit') _openEdit(e);
                              if (val == 'delete') _delete(e.id);
                              if (val == 'share') {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: '${df.format(e.at)}\n\n${e.text}',
                                  ),
                                ).then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Entry copied to clipboard',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                });
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 20),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 👇 Private / Visible logic
                    e.isPrivate
                        ? GestureDetector(
                            onTap: () async {
                              // Reveal the entry
                              await Supabase.instance.client
                                  .from('journals')
                                  .update({'is_private': false})
                                  .eq('id', e.id);
                              setState(() {
                                e.isPrivate = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.lock, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Private - tap to reveal',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GestureDetector(
                            onLongPress: () async {
                              // Hide again
                              await Supabase.instance.client
                                  .from('journals')
                                  .update({'is_private': true})
                                  .eq('id', e.id);
                              setState(() {
                                e.isPrivate = true;
                              });
                            },
                            child: Text(
                              e.text,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              e.sentiment > 0.05
                                  ? Icons.sentiment_satisfied
                                  : (e.sentiment < -0.05
                                        ? Icons.sentiment_dissatisfied
                                        : Icons.sentiment_neutral),
                              size: 18,
                              color: e.sentiment > 0.05
                                  ? Colors.green
                                  : (e.sentiment < -0.05
                                        ? Colors.red
                                        : Colors.grey),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sentimentLabel,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Text(
                          '${e.text.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).length} words',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Center(child: const Text('My Journal')),
        backgroundColor: Colors.pink.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('About this Journal'),
                content: const Text(
                  'Your journal entries are securely stored in your personal space. '
                  'All data is private to you and helps track your mood, thoughts, and writing patterns over time. '
                  'Your privacy and data security are our top priorities.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                color: Colors.pink,
                backgroundColor: Colors.white,
                displacement: 40,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildComposer(),
                      const SizedBox(height: 16),
                      _buildHeatMap(),
                      const SizedBox(height: 16),
                      _buildControls(),
                      const SizedBox(height: 16),
                      if (_visibleEntries.isEmpty)
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 40),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No entries yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Write what's on your mind to get started",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _textFieldFocus.requestFocus();
                                    setState(() => _controller.text = _prompt);
                                  },
                                  icon: const Icon(Icons.lightbulb),
                                  label: const Text('Use today\'s prompt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Your Entries (${_visibleEntries.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            ...List.generate(_visibleEntries.length, (i) {
                              return _buildEntryCard(_visibleEntries[i], i);
                            }),
                            const SizedBox(height: 40),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _textFieldFocus.requestFocus();
      //     // Scroll to composer
      //     Scrollable.ensureVisible(
      //       context,
      //       duration: const Duration(milliseconds: 300),
      //       curve: Curves.easeOut,
      //     );
      //   },
      //   backgroundColor: Colors.pink,
      //   foregroundColor: Colors.white,
      //   elevation: 4,
      //   child: const Icon(Icons.edit),
      // ),
    );
  }
}
