// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hereforyou/screens/homepage/journal_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============ MODELS + STORAGE ============

class MoodLog {
  final String label;
  final String emoji;
  final int colorValue;
  final DateTime at;

  MoodLog({
    required this.label,
    required this.emoji,
    required this.colorValue,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'emoji': emoji,
    'color': colorValue,
    'at': at.toIso8601String(),
  };

  factory MoodLog.fromMap(Map<String, dynamic> m) => MoodLog(
    label: m['label'],
    emoji: m['emoji'],
    colorValue: m['color'],
    at: DateTime.parse(m['at']),
  );
}

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

class JournalEntry {
  final String text;
  final DateTime at;
  JournalEntry({required this.text, required this.at});

  Map<String, dynamic> toMap() => {'text': text, 'at': at.toIso8601String()};

  factory JournalEntry.fromMap(Map<String, dynamic> m) =>
      JournalEntry(text: m['text'], at: DateTime.parse(m['at']));
}

class JournalStorage {
  static const _key = 'journal_entries';

  static Future<List<JournalEntry>> getAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    return raw
        .map((s) => JournalEntry.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  static Future<void> add(JournalEntry e) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    list.add(jsonEncode(e.toMap()));
    await sp.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}

// ============ YOUR HOME PAGE (functional) ============

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final List<_FloatHeart> _hearts;

  // Mood carousel state
  final PageController _moodController = PageController(
    viewportFraction: 0.32,
    initialPage: 2,
  );
  int _currentMood = 2;

  final moods = <Map<String, dynamic>>[
    {'emoji': '😊', 'label': 'Okay', 'color': const Color(0xFF81C784)},
    {'emoji': '😌', 'label': 'Calm', 'color': const Color(0xFF4DB6AC)},
    {'emoji': '😔', 'label': 'Low', 'color': const Color(0xFFEF9A9A)},
    {'emoji': '😣', 'label': 'Anxious', 'color': const Color(0xFFFFB74D)},
    {'emoji': '🥱', 'label': 'Drained', 'color': const Color(0xFF90A4AE)},
  ];

  // Rotating supportive prompts (animated subtly)
  final prompts = const [
    "How’s your heart today?",
    "You don’t have to hold it alone.",
    "Small steps still count.",
    "You deserve kindness — from you.",
  ];
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final rnd = Random();
    _hearts = List.generate(
      16,
      (_) => _FloatHeart(
        startX: rnd.nextDouble(),
        size: rnd.nextDouble() * 22 + 10,
        speed: rnd.nextDouble() * 0.5 + 0.5,
        phase: rnd.nextDouble() * pi * 2,
        hue: rnd.nextInt(3),
      ),
    );

    // Rotate the supportive prompt every few seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      setState(() {
        _promptIndex = (_promptIndex + 1) % prompts.length;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  Color get accentColor => moods[_currentMood]['color'] as Color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _BackgroundGradient(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              const _BackgroundGradient(),
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HeartsPainter(_hearts, _bgController.value),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(),
                      const SizedBox(height: 16),
                      _promptCard(),
                      const SizedBox(height: 20),
                      _moodCarousel(), // now tappable + saves mood
                      const SizedBox(height: 20),
                      _quickActionsRow(),
                      const SizedBox(height: 26),
                      Text(
                        "Your Space",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[400],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _asymmetricFeatures(),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MoodHistoryPage(),
                          ),
                        ),
                        child: _moodTrackerTeaser(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _helpFab(context),
        ),
      ],
    );
  }

  // ————— Sections —————

  Widget _headerCard() {
    return _Glass(
      blur: 18,
      opacity: 0.25,
      borderRadius: 24,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.pink[200]!, Colors.pink[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 34, color: Colors.pink[400]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "${_greeting()}, ${widget.userName} 💖\nWe’re glad you’re here.",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptCard() {
    return _Glass(
      blur: 16,
      opacity: 0.15,
      borderRadius: 18,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.pink[100]!),
          color: Colors.white.withOpacity(0.65),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.pink[400]),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(sizeFactor: anim, child: child),
                ),
                child: Text(
                  prompts[_promptIndex],
                  key: ValueKey(_promptIndex),
                  style: TextStyle(fontSize: 14, color: Colors.pink[900]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodCarousel() {
    return SizedBox(
      height: 96,
      child: PageView.builder(
        controller: _moodController,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: moods.length,
        onPageChanged: (i) => setState(() => _currentMood = i),
        itemBuilder: (context, i) {
          final mood = moods[i];
          final color = mood['color'] as Color;
          final selected = i == _currentMood;
          return AnimatedScale(
            scale: selected ? 1.05 : 0.94,
            duration: const Duration(milliseconds: 220),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: selected
                    ? () {
                        final newMood = MoodLog(
                          label: mood['label'] as String,
                          emoji: mood['emoji'] as String,
                          colorValue: color.value,
                          at: DateTime.now(),
                        );

                        // Instant user feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Logged mood: ${newMood.emoji} ${newMood.label}",
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );

                        // Save to storage in the background
                        MoodStorage.add(newMood);
                      }
                    : null,

                child: _Glass(
                  blur: selected ? 24 : 12,
                  opacity: selected ? 0.28 : 0.18,
                  borderRadius: 20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.35)),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.10),
                          color.withOpacity(0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood['emoji'] as String,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: color.darken(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _quickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _glassAction(
          title: "Journal",
          icon: Icons.edit_note_rounded,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalPage()),
          ),
        ),
        _glassAction(
          title: "Chat",
          icon: Icons.chat_bubble_outline_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatPage()),
          ),
        ),
        _glassAction(
          title: "Breathe",
          icon: Icons.self_improvement_rounded,
          color: Colors.purple,
          onTap: _showBreathSheet,
        ),
        _glassAction(
          title: "Helpline",
          icon: Icons.phone_in_talk_rounded,
          color: Colors.redAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelplinePage()),
          ),
        ),
      ],
    );
  }

  Widget _glassAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: _Glass(
            blur: 22,
            opacity: 0.25,
            borderRadius: 18,
            child: Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.25)),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.10), color.withOpacity(0.18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: color.darken(0.2)),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color.darken(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _asymmetricFeatures() {
    return Column(
      children: [
        _featureBigCard(
          title: "Instant Listener",
          subtitle: "AI or human — your choice.\nWe’re here now.",
          icon: Icons.headset_mic_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatPage()),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _featureSmallCard(
                title: "Community",
                icon: Icons.people_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityPage()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _featureSmallCard(
                title: "Resources",
                icon: Icons.health_and_safety_rounded,
                color: Colors.blueAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResourcesPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureBigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        blur: 24,
        opacity: 0.25,
        borderRadius: 24,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.25)),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.10), color.withOpacity(0.20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color.darken(0.2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color.darken(0.2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureSmallCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        blur: 20,
        opacity: 0.22,
        borderRadius: 20,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25)),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.10), color.withOpacity(0.20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color.darken(0.2)),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodTrackerTeaser() {
    return _Glass(
      blur: 18,
      opacity: 0.22,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.pink[200]!),
          gradient: LinearGradient(
            colors: [Colors.pink[50]!, Colors.pink[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.pink[300], size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Track your mood and see your emotional journey over time.",
                style: TextStyle(fontSize: 14, color: Color(0xFF880E4F)),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.pink[300]),
          ],
        ),
      ),
    );
  }

  Widget _helpFab(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.05),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.35),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          label: const Text(
            "I need to talk",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () => _openTalkSheet(),
        ),
      ),
    );
  }

  // ————— Sheets —————

  void _openTalkSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.0),
      barrierColor: Colors.black.withOpacity(0.35),
      isScrollControlled: true,
      builder: (context) {
        return _Glass(
          blur: 30,
          opacity: 0.28,
          borderRadius: 28,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              color: Colors.white.withOpacity(0.75),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Text(
                    "Choose how you’d like to talk",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.pink[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _talkOption(
                    icon: Icons.smart_toy_rounded,
                    title: "Talk to AI Listener",
                    subtitle: "Instant, supportive, judgment-free",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AIChatPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _talkOption(
                    icon: Icons.headset_mic_rounded,
                    title: "Connect to Human Listener",
                    subtitle: "Real person, trained to listen",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      // Placeholder — route to your human listener flow
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _talkOption(
                    icon: Icons.sos_rounded,
                    title: "Crisis Helpline",
                    subtitle: "Add local numbers you trust",
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelplinePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBreathSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.0),
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return _Glass(
          blur: 30,
          opacity: 0.28,
          borderRadius: 28,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              color: Colors.white.withOpacity(0.8),
            ),
            child: _BreathCoach(accent: accentColor),
          ),
        );
      },
    );
  }

  Widget _talkOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.10), color.withOpacity(0.20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.85),
              child: Icon(icon, color: color.darken(0.2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.darken(0.2)),
          ],
        ),
      ),
    );
  }
}

// ————— Visual helpers —————

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0E0), Color(0xFFFCE4EC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final double blur;
  final double opacity;
  final double borderRadius;
  final Widget child;

  const _Glass({
    required this.blur,
    required this.opacity,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: Colors.white.withOpacity(opacity),
          child: child,
        ),
      ),
    );
  }
}

class _BreathCoach extends StatefulWidget {
  final Color accent;
  const _BreathCoach({required this.accent});

  @override
  State<_BreathCoach> createState() => _BreathCoachState();
}

class _BreathCoachState extends State<_BreathCoach>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 4,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Text(
          "Breathe with me",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.pink[800],
          ),
        ),
        const SizedBox(height: 16),
        ScaleTransition(
          scale: _c,
          child: Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.accent.withOpacity(0.2),
                  widget.accent.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text("Inhale • Exhale", style: TextStyle(color: Colors.grey[800])),
        const SizedBox(height: 6),
        Text(
          "4 seconds in, 4 seconds out",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ————— Floating hearts —————

class _FloatHeart {
  final double startX; // 0..1 (percent of width)
  final double size;
  final double speed;
  final double phase;
  final int hue; // 0..2 small palette switch

  _FloatHeart({
    required this.startX,
    required this.size,
    required this.speed,
    required this.phase,
    required this.hue,
  });
}

class _HeartsPainter extends CustomPainter {
  final List<_FloatHeart> hearts;
  final double t; // 0..1 loop

  _HeartsPainter(this.hearts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in hearts) {
      final progress = ((t * h.speed + h.phase) % 1.0);
      final x =
          (h.startX * size.width) + sin(progress * pi * 2) * 18; // gentle sway
      final y = size.height * (1.1 - progress * 1.2); // float upwards

      final paint = Paint()
        ..color = _palette(h.hue).withOpacity(0.18)
        ..style = PaintingStyle.fill;

      _drawHeart(canvas, Offset(x, y), h.size, paint);
    }
  }

  Color _palette(int i) {
    switch (i) {
      case 0:
        return const Color(0xFFF48FB1); // pink
      case 1:
        return const Color(0xFFFFCDD2); // light pink
      default:
        return const Color(0xFFE57373); // soft red
    }
  }

  void _drawHeart(Canvas c, Offset center, double s, Paint p) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    path.moveTo(x, y);
    path.cubicTo(x - s, y - s, x - s * 1.4, y + s * 0.2, x, y + s);
    path.cubicTo(x + s * 1.4, y + s * 0.2, x + s, y - s, x, y);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.hearts != hearts;
}

// ————— Color utils —————

extension _ColorMath on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}

// ============ SIMPLE PAGES ============

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

class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder: integrate your AI later
    return Scaffold(
      appBar: AppBar(title: const Text("AI Listener")),
      body: const Center(
        child: Text(
          "AI chat coming soon.\nHook your SDK/model here.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community")),
      body: const Center(
        child: Text(
          "Community hub placeholder.\nAdd rooms, posts, or spaces.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ("Grounding techniques", Icons.terrain),
      ("Healthy sleep tips", Icons.bedtime),
      ("Anxiety first-aid", Icons.healing),
      ("Emergency preparation", Icons.shield),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("Resources")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (title, icon) = items[i];
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            tileColor: Colors.pink[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class HelplinePage extends StatefulWidget {
  const HelplinePage({super.key});

  @override
  State<HelplinePage> createState() => _HelplinePageState();
}

class _HelplinePageState extends State<HelplinePage> {
  final List<Map<String, String>> _numbers = [
    // Keep these as placeholders — replace with trusted local contacts/orgs.
    {'name': 'Local Emergency', 'phone': '112'},
    {'name': 'Trusted Friend', 'phone': ''},
    {'name': 'Counselor', 'phone': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Helplines")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _numbers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _numbers[i];
          return ListTile(
            leading: const Icon(Icons.call_rounded),
            title: Text(n['name']!),
            subtitle: Text(n['phone']!.isEmpty ? "Add number" : n['phone']!),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final c = TextEditingController(text: n['phone']);
                final newNum = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Edit ${n['name']}"),
                    content: TextField(
                      controller: c,
                      decoration: const InputDecoration(
                        hintText: "Enter phone number",
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, c.text.trim()),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
                if (newNum != null) {
                  setState(() => _numbers[i]['phone'] = newNum);
                }
              },
            ),
            onTap: () {
              final phone = _numbers[i]['phone'] ?? '';
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Add a number first, then tap to call."),
                  ),
                );
                return;
              }
              // Use url_launcher if you want to actually dial:
              // launchUrl(Uri.parse("tel:$phone"));
            },
          );
        },
      ),
    );
  }
}
