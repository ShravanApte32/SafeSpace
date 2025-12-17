// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hereforyou/models/hearts.dart';
import 'package:hereforyou/screens/homepage/chat/chat_tab.dart';
import 'package:hereforyou/screens/homepage/explore/explore_tab.dart';
import 'package:hereforyou/screens/homepage/home/challenges/quiz_helper.dart';
import 'package:hereforyou/screens/homepage/chat/ai_chat/ai_chat.dart';
import 'package:hereforyou/screens/homepage/chat/community_chat/community.dart';
import 'package:hereforyou/screens/homepage/home/exercises/breath_coach.dart';
import 'package:hereforyou/screens/homepage/explore/helplines/helplines.dart';
import 'package:hereforyou/screens/homepage/explore/resources/resources.dart';
import 'package:hereforyou/screens/homepage/home/mood_tracker/mood_history/mood_history.dart';
import 'package:hereforyou/screens/homepage/journal/journal_page.dart';
import 'package:hereforyou/screens/profile_page/profile_tab.dart';
import 'package:hereforyou/utils/colormath.dart';
import 'package:hereforyou/widgets/background_gradient.dart';
import 'package:hereforyou/widgets/glass_effect.dart';
import 'package:hereforyou/widgets/heart_painter.dart';
import 'package:hereforyou/widgets/interactive_mood_section.dart';
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
  late final AnimationController _habitBtnController;
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

  // Mood state
  int _currentMood = 2;
  late PageController _moodController;

  int _currentIndex = 0;

  // Define all your main pages here

  final supabase = Supabase.instance.client;

  final moods = <Map<String, dynamic>>[
    {'emoji': '😊', 'label': 'Okay', 'color': const Color(0xFF81C784)},
    {'emoji': '😌', 'label': 'Calm', 'color': const Color(0xFF4DB6AC)},
    {'emoji': '😔', 'label': 'Low', 'color': const Color(0xFFEF9A9A)},
    {'emoji': '😣', 'label': 'Anxious', 'color': const Color(0xFFFFB74D)},
    {'emoji': '🥱', 'label': 'Drained', 'color': const Color(0xFF90A4AE)},
  ];

  final prompts = const [
    "How's your heart today? 💖",
    "You don't have to hold it alone",
    "Small steps still count ✨",
    "You deserve kindness, especially from yourself",
  ];
  int _promptIndex = 0;
  late AnimationController _promptController;
  late Animation<double> _promptAnimation;

  // New interactive elements
  bool _isHeartPulsing = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  double _userEnergyLevel = 0.75;
  final PageController _featureController = PageController();

  @override
  void initState() {
    super.initState();

    // Initialize mood controller after moods list is defined
    _moodController = PageController(
      viewportFraction: 0.32,
      initialPage: _currentMood,
    );

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

    // Prompt animation
    _promptController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _promptAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _promptController, curve: Curves.easeInOut),
    );

    // Heart pulse animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _heartAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // Rotate prompts
    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _promptIndex = (_promptIndex + 1) % prompts.length;
        });
      }
    });

    _habitBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
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
      begin: const Offset(-0.25, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_pointsCtrl);

    _pointsFade = CurvedAnimation(parent: _pointsCtrl, curve: Curves.easeOut);
    _pointsCtrl.forward();

    _fetchAffirmation();
    _loadHabitToggle();
    _loadDailyChallenge();
    _loadQuizProgress();

    // Load last mood from Supabase
    _loadLastMood();
  }

  Future<void> _loadLastMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('No user ID found');
        return;
      }

      print('Loading last mood for user ID: $userId');

      final response = await supabase
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      print('Supabase response: ${response.length} records found');

      if (response.isNotEmpty) {
        final latestMood = response.first;
        final label = latestMood['label'];
        final emoji = latestMood['emoji'];

        print('Latest mood from DB: label="$label", emoji="$emoji"');
        print(
          'Available mood labels: ${moods.map((m) => m['label']).toList()}',
        );

        // Find index of this mood
        final index = moods.indexWhere((m) => m['label'] == label);
        print('Found index: $index');

        if (index != -1 && mounted) {
          print(
            'Setting current mood to index: $index (${moods[index]['label']})',
          );
          setState(() {
            _currentMood = index;
          });

          // Small delay to ensure controller is ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _moodController.hasClients) {
              print('Jumping to page: $index');
              _moodController.jumpToPage(index);
            }
          });
        } else {
          print('Mood label "$label" not found in moods list');
          // Try case-insensitive search
          final caseInsensitiveIndex = moods.indexWhere(
            (m) =>
                (m['label'] as String).toLowerCase() ==
                (label as String).toLowerCase(),
          );
          if (caseInsensitiveIndex != -1) {
            print(
              'Found case-insensitive match at index: $caseInsensitiveIndex',
            );
            setState(() {
              _currentMood = caseInsensitiveIndex;
            });
          }
        }
      } else {
        print('No mood logs found for user');
      }
    } catch (e) {
      print('Error loading last mood: $e');
      print('Stack trace: ${e.toString()}');
    }
  }

  Future<void> _logMoodToSupabase(Map<String, dynamic> mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save moods')),
        );
        return;
      }

      await supabase.from('mood_logs').insert({
        'user_id': userId,
        'label': mood['label'],
        'emoji': mood['emoji'],
        'color_value': (mood['color'] as Color).value,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood logged: ${mood['emoji']} ${mood['label']}'),
          backgroundColor: mood['color'],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error logging mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log mood: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    habitReminderEnabled = prefs.getBool(_kHabitEnabled) ?? false;
    if (mounted) setState(() {});
  }

  void _loadDailyChallenge() {
    final challenges = [
      "Draw something using only circles",
      "Write a 4-line poem about today",
      "Take a 5-min mindful walk",
      "List 3 things you're grateful for",
      "Doodle your dream place",
      "Try writing with your non-dominant hand",
      "Do 10 stretches before bed",
    ];
    final day = DateTime.now().weekday;
    setState(() => challenge = challenges[day % challenges.length]);
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  void dispose() {
    _bgController.dispose();
    _moodController.dispose();
    _habitBtnController.dispose();
    _answerAnimationController.dispose();
    _pointsAnimationController.dispose();
    _promptController.dispose();
    _heartController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.bottom;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final _pages = [
      HomeTabContent(
        bgController: _bgController,
        hearts: _hearts,
        header: _buildHeaderSection(),
        moodSection: InteractiveMoodSection(
          controller: _moodController,
          currentMood: _currentMood,
          moods: moods,
          onMoodChanged: (i) => setState(() => _currentMood = i),
          onMoodTap: (i) async {
            await _logMoodToSupabase(moods[i]);
            if (!mounted) return;
            setState(() => _currentMood = i);
            _moodController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        affirmationCard: _buildAffirmationCard(),
        quickActionsBuilder: (maxWidth, isTablet) =>
            _buildQuickActions(maxWidth: maxWidth, isTablet: isTablet),
        moodHistoryButton: _buildMoodHistoryButton(),
      ),
      ChatTabPage(),
      const ExploreTabPage(),
      ProfileTabPage(userName: widget.userName),
    ];

    return Stack(
      children: [
        const BackgroundGradient(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: _pages),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _buildHelpButton(),
          bottomNavigationBar: _buildBottomNav(safePadding),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.pink[300]!.withOpacity(0.95),
            Colors.pink[200]!.withOpacity(0.8),
            Colors.pink[100]!.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Larger welcome section
              Row(
                children: [
                  // Larger animated heart
                  AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartAnimation.value,
                        child: Container(
                          width: 80, // Increased from 44
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.pink[200]!, Colors.pink[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink[300]!.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 40, // Increased from 24
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_greeting()}, ${widget.userName}",
                          style: const TextStyle(
                            fontSize: 28, // Increased from 22
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black38),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey(_promptIndex),
                            prompts[_promptIndex],
                            style: TextStyle(
                              fontSize: 16, // Increased from 14
                              color: Colors.white.withOpacity(0.95),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Enhanced date indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink[100]!.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Today's highlight
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withOpacity(0.3),
                    ),

                    // Day of week
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "It's",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWeekday(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
  }

  String _getWeekday(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }

  Widget _buildInteractiveMoodSection() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive viewport fraction
    final viewportFraction = isTablet ? 0.32 : 0.35;
    // Calculate item width based on screen
    final itemWidth = screenWidth * viewportFraction;

    return Glass(
      blur: 20,
      opacity: 0.25,
      borderRadius: 24,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16), // Responsive padding
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[50]!.withOpacity(0.3),
              Colors.purple[50]!.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 40 : 36,
                  height: isTablet ? 40 : 36,
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.pink[400],
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isTablet ? 150 : 110,
              child: PageView.builder(
                controller: _moodController,
                itemCount: moods.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentMood = index;
                  });
                },
                itemBuilder: (context, index) {
                  final mood = moods[index];
                  final isSelected = index == _currentMood;
                  return GestureDetector(
                    onTap: () async {
                      await _logMoodToSupabase(mood);
                      setState(() {
                        _currentMood = index;
                      });
                      _moodController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: itemWidth - 12, // Account for margins
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    mood['color'].withOpacity(0.4),
                                    mood['color'].withOpacity(0.2),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? mood['color'].withOpacity(0.6)
                                : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: mood['color'].withOpacity(0.3),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood['emoji'],
                              style: TextStyle(fontSize: isTablet ? 36 : 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? mood['color']
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SmoothPageIndicator(
                controller: _moodController,
                count: moods.length,
                effect: ExpandingDotsEffect(
                  dotWidth: isTablet ? 10 : 8,
                  dotHeight: isTablet ? 10 : 8,
                  activeDotColor: Colors.pink[400]!,
                  dotColor: Colors.pink[200]!.withOpacity(0.5),
                  spacing: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationCard() {
    return GestureDetector(
      onTap: _fetchAffirmation,
      child: Glass(
        blur: 25,
        opacity: 0.3,
        borderRadius: 24,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple[100]!.withOpacity(0.4),
                Colors.blue[100]!.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.purple[400],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Daily Affirmation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const Spacer(),
                  // IconButton(
                  //   onPressed: _fetchAffirmation,
                  //   icon: Icon(
                  //     Icons.refresh_rounded,
                  //     color: Colors.purple[400],
                  //     size: 24,
                  //   ),
                  //   tooltip: 'Get new affirmation',
                  // ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                affirmation ??
                    "Stay positive and keep moving forward! Every day is a fresh start.",
                style: const TextStyle(
                  fontSize: 18, // Increased
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: Text(
              //     "Tap to refresh",
              //     style: TextStyle(
              //       fontSize: 12,
              //       color: Colors.purple[400]!.withOpacity(0.7),
              //       fontStyle: FontStyle.italic,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodHistoryButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoodHistoryPage()),
      ),
      child: Glass(
        blur: 20,
        opacity: 0.25,
        borderRadius: 20,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink[50]!.withOpacity(0.3),
                Colors.pink[100]!.withOpacity(0.3),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink[200]!.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: Colors.pink[400],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mood History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Track your emotional journey over time",
                      style: TextStyle(fontSize: 14, color: Colors.pink[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.pink[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions({double? maxWidth, bool isTablet = false}) {
    final actions = [
      {
        'icon': Icons.edit_note_rounded,
        'label': 'Journal',
        'color': Colors.orange[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalPage()),
        ),
      },
      {
        'icon': Icons.self_improvement_rounded,
        'label': 'Breathe',
        'color': Colors.purple[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BreathMeditationPage(accent: Colors.pink[400]!),
          ),
        ),
      },
    ];

    // Calculate responsive height
    final itemHeight = isTablet ? 200.0 : 150.0;
    final crossAxisCount = isTablet ? 2 : 2; // Keep 2 columns for both
    final totalRows = (actions.length / crossAxisCount).ceil();
    final totalHeight = (totalRows * itemHeight) + ((totalRows - 1) * 16);

    return SizedBox(
      height: totalHeight, // Fixed height to prevent overflow
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isTablet ? 16 : 12,
          mainAxisSpacing: isTablet ? 16 : 12,
          childAspectRatio: isTablet ? 2.6 : 1.4, // Adjust for mobile
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: action['route'] as VoidCallback,
            child: Glass(
              blur: 15,
              opacity: 0.2,
              borderRadius: 20,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (action['color'] as Color).withOpacity(0.2),
                      (action['color'] as Color).withOpacity(0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(
                        action['icon'] as IconData,
                        size: isTablet ? 100 : 80, // Smaller on mobile
                        color: (action['color'] as Color).withOpacity(0.08),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: isTablet ? 48 : 40,
                            height: isTablet ? 48 : 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (action['color'] as Color).withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: (action['color'] as Color),
                              size: isTablet ? 28 : 24,
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            action['label'] as String,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: (action['color'] as Color).darken(0.2),
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
        },
      ),
    );
  }

  Widget _buildFeaturedTools() {
    final features = [
      {
        'title': 'Crisis Support',
        'subtitle': 'Immediate help available',
        'icon': Icons.sos_rounded,
        'color': Colors.red[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelplinePage()),
        ),
      },
      {
        'title': 'Resources Library',
        'subtitle': 'Tools & guides for healing',
        'icon': Icons.health_and_safety_rounded,
        'color': Colors.green[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResourcesPage()),
        ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            "Resources",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink[800],
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _featureController,
            itemCount: features.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final feature = features[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: feature['route'] as VoidCallback,
                  child: Glass(
                    blur: 25,
                    opacity: 0.3,
                    borderRadius: 24,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (feature['color'] as Color).withOpacity(0.25),
                            (feature['color'] as Color).withOpacity(0.15),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (feature['color'] as Color)
                                      .withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              feature['icon'] as IconData,
                              color: (feature['color'] as Color),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  feature['title'] as String,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: (feature['color'] as Color).darken(
                                      0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feature['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      'Explore Now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: (feature['color'] as Color),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: (feature['color'] as Color),
                                    ),
                                  ],
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHelpButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 28,
              ),
              label: const Text(
                "I need to talk",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: _openTalkSheet,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(double safePadding) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.only(bottom: max(safePadding, 4), top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navBtn(Icons.home_rounded, "Home", 0, isTablet),
          _navBtn(Icons.chat_rounded, "Chat", 1, isTablet),
          SizedBox(width: isTablet ? 80 : 40),
          _navBtn(Icons.explore_rounded, "Explore", 2, isTablet),
          _navBtn(Icons.person_rounded, "Profile", 3, isTablet),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active, {
    required bool isTablet,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? Colors.pink[400] : Colors.grey[500],
          size: isTablet ? 28 : 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 11 : 10,
            color: active ? Colors.pink[400] : Colors.grey[500],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, String label, int index, bool isTablet) {
    final active = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _buildNavItem(icon, label, active, isTablet: isTablet),
      ),
    );
  }

  void _openTalkSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              Glass(
                blur: 30,
                opacity: 0.3,
                borderRadius: 30.0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    color: Colors.white.withOpacity(0.95),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Choose how you'd like to talk",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[800],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTalkOption(
                        icon: Icons.smart_toy_rounded,
                        title: "AI Listener",
                        subtitle: "Always available, judgment-free",
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AIChatPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTalkOption(
                        icon: Icons.people_rounded,
                        title: "Community Chat",
                        subtitle: "Connect with understanding peers",
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTalkOption(
                        icon: Icons.phone_rounded,
                        title: "Human Helpline",
                        subtitle: "Connect with professional help support",
                        color: const Color.fromARGB(255, 221, 137, 89),
                        onTap: () {
                          // Navigator.pop(context);
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (_) => const HelplinePage(),
                          //   ),
                          // );
                        },
                      ),
                      SizedBox(height: 60),
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

  Widget _buildTalkOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class HomeTabContent extends StatelessWidget {
  final AnimationController bgController;
  final List<FloatHeart> hearts;

  final Widget header;
  final Widget moodSection;
  final Widget affirmationCard;
  final Widget Function(double maxWidth, bool isTablet) quickActionsBuilder;
  final Widget moodHistoryButton;

  const HomeTabContent({
    super.key,
    required this.bgController,
    required this.hearts,
    required this.header,
    required this.moodSection,
    required this.affirmationCard,
    required this.quickActionsBuilder,
    required this.moodHistoryButton,
  });

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.bottom;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isTablet ? 250 : 280,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          stretch: true,
          automaticallyImplyLeading: false,
          collapsedHeight: 0,
          toolbarHeight: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: bgController,
                  builder: (_, __) => CustomPaint(
                    painter: HeartsPainter(hearts, bgController.value),
                  ),
                ),
                header,
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                moodSection,
                const SizedBox(height: 20),
                affirmationCard,
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (_, constraints) =>
                      quickActionsBuilder(constraints.maxWidth, isTablet),
                ),
                const SizedBox(height: 20),
                moodHistoryButton,
                SizedBox(height: safePadding + 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
