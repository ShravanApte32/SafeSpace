// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hereforyou/models/hearts.dart';
import 'package:hereforyou/screens/homepage/home/challenges/quiz_helper.dart';
import 'package:hereforyou/screens/homepage/chat/ai_chat/ai_chat.dart';
import 'package:hereforyou/screens/homepage/chat/community_chat/community.dart';
import 'package:hereforyou/screens/homepage/home/exercises/breath_coach.dart';
import 'package:hereforyou/screens/homepage/explore/helplines/helplines.dart';
import 'package:hereforyou/screens/homepage/explore/resources/resources.dart';
import 'package:hereforyou/screens/homepage/home/mood_tracker/mood_history/mood_history.dart';
import 'package:hereforyou/screens/homepage/journal/journal_page.dart';
import 'package:hereforyou/utils/colormath.dart';
import 'package:hereforyou/widgets/background_gradient.dart';
import 'package:hereforyou/widgets/glass_effect.dart';
import 'package:hereforyou/widgets/heart_painter.dart';
import 'package:hereforyou/widgets/particle_widget.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final List<FloatHeart> _hearts;
  String? affirmation;
  String? challenge;
  bool habitReminderEnabled = false;

  // HABIT — state & key

  // glow animation on completion
  late final AnimationController _habitBtnController; // bounce +1

  static const _kHabitEnabled = "habit_toggle";

  int _quizPoints = 0;
  int _currentQuestionIndex = 0;
  bool _quizCompleted = false;
  bool _showCelebration = false;
  final _pageController = PageController();
  late AnimationController _answerAnimationController;
  late AnimationController _pointsAnimationController;

  late final AnimationController _pointsCtrl;
  late final Animation<Offset> _pointsSlide;
  late final Animation<double> _pointsFade;

  // Mood carousel state
  final PageController _moodController = PageController(
    viewportFraction: 0.32,
    initialPage: 2,
  );
  final int _currentMood = 2;

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
      (_) => FloatHeart(
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

    _habitBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.0,
      upperBound: 0.12, // scale bounce
    );

    _answerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pointsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pointsSlide = Tween<Offset>(
      begin: const Offset(-0.25, 0), // 👈 horizontal only
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_pointsCtrl);

    _pointsFade = CurvedAnimation(parent: _pointsCtrl, curve: Curves.easeOut);
    _pointsCtrl.forward();

    _fetchAffirmation();
    _loadHabitToggle();
    _loadDailyChallenge();

    _loadQuizProgress();
  }

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'Which activity helps most with immediate stress relief?',
      'options': [
        'Deep Breathing',
        'Scrolling Social Media',
        'Eating Junk Food',
      ],
      'correct': 0,
      'points': 10,
      'explanation':
          'Deep breathing activates the parasympathetic nervous system which helps calm the body.',
    },
    {
      'question': 'How many hours of sleep do experts recommend for adults?',
      'options': ['4-5 hours', '7-9 hours', '10+ hours'],
      'correct': 1,
      'points': 15,
      'explanation':
          '7-9 hours is ideal for cognitive function and emotional regulation.',
    },
    {
      'question': 'Which of these is NOT a healthy coping mechanism?',
      'options': ['Journaling', 'Bottling up emotions', 'Talking to friends'],
      'correct': 1,
      'points': 20,
      'explanation':
          'Suppressing emotions can lead to increased stress and anxiety over time.',
    },
  ];

  // ignore: unused_element
  Widget _challengeCard() {
    if (_showCelebration) {
      return _buildCelebration();
    }

    if (_quizCompleted) {
      return _buildResults();
    }

    return _buildQuizQuestion();
  }

  Widget _buildResults() {
    return Glass(
      blur: 22,
      opacity: 0.24,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purpleAccent.withOpacity(0.1),
              Colors.blueAccent.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/stay_connected.json',
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 20),
              Text(
                "Quiz Complete!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You earned $_quizPoints XP!",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showCelebration = true;
                  });
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _showCelebration = false;
                        _resetQuiz();
                      });
                    }
                  });
                },
                child: const Text("Claim Reward"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return Stack(
      children: [
        // Background particles
        Positioned.fill(
          child: IgnorePointer(
            child: ParticleWidget(
              numberOfParticles: 50,
              color: Colors.blueAccent,
            ),
          ),
        ),
        // Celebration content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/lil_heart.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 20),
              Text(
                "Great Job!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You earned $_quizPoints XP!",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkAnswer(int selectedIndex) async {
    final currentQuestion = _quizQuestions[_currentQuestionIndex];
    final isCorrect = selectedIndex == currentQuestion['correct'];

    if (isCorrect) {
      _pointsAnimationController.reset();
      _pointsAnimationController.forward();
      setState(() {
        _quizPoints += currentQuestion['points'] as int;
      });
    }

    // Show explanation tooltip
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect ? "✅ Correct!" : "❌ Try Again",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(currentQuestion['explanation']),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _quizCompleted = true;
      });
      _saveQuizCompletion();
    }
  }

  Future<void> _saveQuizCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_quiz_date', today);
    await prefs.setInt(
      'total_points',
      (_quizPoints + (prefs.getInt('total_points') ?? 0)),
    );
  }

  Future<void> _loadQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_quiz_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDate != today) {
      setState(() {
        _currentQuestionIndex = 0;
        _quizPoints = 0;
        _quizCompleted = false;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _quizCompleted = false;
      _quizPoints = 0;
    });
    _pageController.jumpToPage(0);
  }

  Widget _buildQuizQuestion() {
    final currentQuestion = _quizQuestions[_currentQuestionIndex];

    return Glass(
      blur: 22,
      opacity: 0.24,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz header with progress
            Row(
              children: [
                SizedBox(
                  // reserves consistent height so nothing collides
                  height: 28,
                  child: FadeTransition(
                    opacity: _pointsFade,
                    child: SlideTransition(
                      position: _pointsSlide, // y == 0 → no vertical overlap
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_quizPoints XP',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _quizQuestions.length,
                  effect: const ExpandingDotsEffect(
                    dotWidth: 8,
                    dotHeight: 8,
                    activeDotColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20), // ✅ extra spacing added here
            // Question text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                currentQuestion['question'],
                key: ValueKey(_currentQuestionIndex),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Answer options with ripple animations
            ...List.generate(currentQuestion['options'].length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedAnswerOption(
                  text: currentQuestion['options'][index],
                  points: currentQuestion['points'],
                  onTap: () => _checkAnswer(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAffirmation() async {
    try {
      final res = await http.get(Uri.parse("https://zenquotes.io/api/random"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => affirmation = data[0]["q"]);
      }
    } catch (e) {
      setState(() => affirmation = "Stay positive and keep moving forward!");
    }
  }

  Future<void> _loadHabitToggle() async {
    final prefs = await SharedPreferences.getInstance();

    // enabled toggle (backward compatible with your previous key)
    habitReminderEnabled = prefs.getBool(_kHabitEnabled) ?? false;

    if (mounted) setState(() {});
  }

  void _loadDailyChallenge() {
    // simple daily challenge based on weekday index
    final challenges = [
      "Draw something using only circles",
      "Write a 4-line poem about today",
      "Take a 5-min mindful walk",
      "List 3 things you’re grateful for",
      "Doodle your dream place",
      "Try writing with your non-dominant hand",
      "Do 10 stretches before bed",
    ];
    final day = DateTime.now().weekday;
    setState(() => challenge = challenges[day % challenges.length]);
  }

  // Optional: allow quick goal adjust (persists)

  @override
  void dispose() {
    _bgController.dispose();
    _moodController.dispose();
    _habitBtnController.dispose(); // ⬅️
    _answerAnimationController.dispose();
    _pointsAnimationController.dispose();
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
        const BackgroundGradient(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              const BackgroundGradient(),
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: HeartsPainter(_hearts, _bgController.value),
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
                      MoodCarousel(), // now tappable + saves mood
                      const SizedBox(height: 20),
                      _affirmationCard(),
                      const SizedBox(height: 20),
                      // _challengeCard(),
                      // const SizedBox(height: 20),
                      // _habitReminderCard(),
                      // const HabitsPage(),
                      // const SizedBox(height: 20),
                      _quickActionsRow1(),
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
    return Glass(
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
    return Glass(
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

  Widget _affirmationCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          affirmation ?? "Loading your daily affirmation...",
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _quickActionsRow1() {
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
          onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BreathMeditationPage(accent: Colors.pink[400]!),
  ),
),
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
          child: Glass(
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
      child: Glass(
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
      child: Glass(
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
    return Glass(
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
        return Glass(
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

  // void _showBreathSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.white.withOpacity(0.0),
  //     barrierColor: Colors.black.withOpacity(0.35),
  //     builder: (context) {
  //       return Glass(
  //         blur: 30,
  //         opacity: 0.28,
  //         borderRadius: 28,
  //         child: Container(
  //           padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
  //           decoration: BoxDecoration(
  //             borderRadius: const BorderRadius.vertical(
  //               top: Radius.circular(28),
  //             ),
  //             color: Colors.white.withOpacity(0.8),
  //           ),
  //           child: BreathCoach(accent: accentColor),
  //         ),
  //       );
  //     },
  //   );
  // }

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

class MoodCarousel extends StatefulWidget {
  const MoodCarousel({super.key});

  @override
  State<MoodCarousel> createState() => _MoodCarouselState();
}

class _MoodCarouselState extends State<MoodCarousel> {
  final _moodController = PageController(viewportFraction: 0.32);
  final supabase = Supabase.instance.client;
  int _currentMood = 0;
  List<Map<String, dynamic>> moods = [];

  @override
  void initState() {
    super.initState();
    moods = [
      {"emoji": "😊", "label": "Happy", "color": Colors.orangeAccent},
      {"emoji": "😢", "label": "Sad", "color": Colors.blueAccent},
      {"emoji": "😡", "label": "Angry", "color": Colors.redAccent},
      {"emoji": "😌", "label": "Calm", "color": Colors.greenAccent},
      {"emoji": "😰", "label": "Anxious", "color": Colors.purpleAccent},
    ];
    _fetchMoodLogs(); // 🔹 Load from Supabase when screen opens
  }

  Future<void> _fetchMoodLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) return;

      final response = await supabase
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1); // ✅ only get latest mood

      if (response.isNotEmpty) {
        final latestMood = response.first;
        final label = latestMood['label'];

        // Find the index of this mood in the carousel
        final index = moods.indexWhere((m) => m['label'] == label);

        if (index != -1) {
          setState(() {
            _currentMood = index;
          });

          // Animate carousel to that mood
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _moodController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      }

      print('✅ Loaded last mood successfully');
    } catch (e) {
      print('❌ Error fetching moods: $e');
    }
  }

  Future<void> _logMood(Map<String, dynamic> mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to log moods.')),
        );
        return;
      }

      await supabase.from('mood_logs').insert({
        'user_id': userId,
        'label': mood['label'],
        'emoji': mood['emoji'],
        'color_value': (mood['color'] as Color).value,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🪶 Logged mood: ${mood['emoji']} ${mood['label']}"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchMoodLogs(); // refresh after logging
    } catch (e) {
      print('❌ Error logging mood: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Carousel
        SizedBox(
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
                    onTap: selected ? () => _logMood(mood) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood['emoji'],
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mood['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: color.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
