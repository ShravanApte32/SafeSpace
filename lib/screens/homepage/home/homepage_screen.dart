// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hereforyou/models/hearts.dart';
import 'package:hereforyou/screens/homepage/chat/chat_tab.dart';
import 'package:hereforyou/screens/homepage/explore/explore_tab.dart';
import 'package:hereforyou/screens/homepage/chat/ai_chat/ai_chat.dart';
import 'package:hereforyou/screens/homepage/chat/community_chat/community.dart';
import 'package:hereforyou/screens/homepage/home/exercises/breath_coach.dart';
import 'package:hereforyou/screens/homepage/explore/helplines/helplines.dart';
import 'package:hereforyou/screens/homepage/home/mood_tracker/mood_history/mood_history.dart';
import 'package:hereforyou/screens/homepage/journal/journal_page.dart';
import 'package:hereforyou/screens/profile_page/profile_tab.dart';
import 'package:hereforyou/widgets/background_gradient.dart';
import 'package:hereforyou/widgets/glass_effect.dart';
import 'package:hereforyou/widgets/heart_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main home page of the application with bottom navigation and dashboard
class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _bgController;
  late final AnimationController _promptController;
  late final AnimationController _heartController;

  // Page controllers
  late final PageController _moodController;

  // Animations
  late final Animation<double> _promptAnimation;
  late final Animation<double> _heartAnimation;

  // Floating hearts for background animation
  late final List<FloatHeart> _hearts;

  // App state
  int _currentIndex = 0; // Current bottom navigation index
  int _currentMood = 2; // Default mood index
  int _promptIndex = 0; // Current rotating prompt index
  String? affirmation; // Daily affirmation text

  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // Mood options with emoji, label and color
  final List<Map<String, dynamic>> moods = <Map<String, dynamic>>[
    {'emoji': '😊', 'label': 'Okay', 'color': const Color(0xFF81C784)},
    {'emoji': '😌', 'label': 'Calm', 'color': const Color(0xFF4DB6AC)},
    {'emoji': '😔', 'label': 'Low', 'color': const Color(0xFFEF9A9A)},
    {'emoji': '😣', 'label': 'Anxious', 'color': const Color(0xFFFFB74D)},
    {'emoji': '🥱', 'label': 'Drained', 'color': const Color(0xFF90A4AE)},
  ];

  // Rotating supportive prompts
  final List<String> prompts = const [
    "How's your heart today? 💖",
    "You don't have to hold it alone",
    "Small steps still count ✨",
    "You deserve kindness, especially from yourself",
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _startPeriodicTasks();
    _loadInitialData();
  }

  /// Initialize all animation and page controllers
  void _initializeControllers() {
    _moodController = PageController(
      viewportFraction: 0.32,
      initialPage: _currentMood,
    );

    // Background animation controller
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Prompt text animation controller
    _promptController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Heart pulsing animation controller
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Initialize floating hearts for background
    final Random random = Random();
    _hearts = List<FloatHeart>.generate(
      16,
      (_) => FloatHeart(
        startX: random.nextDouble(),
        size: random.nextDouble() * 22 + 10,
        speed: random.nextDouble() * 0.5 + 0.5,
        phase: random.nextDouble() * pi * 2,
        hue: random.nextInt(3),
      ),
    );
  }

  /// Initialize all animation tween values
  void _initializeAnimations() {
    _promptAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _promptController, curve: Curves.easeInOut),
    );

    _heartAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  /// Start periodic tasks like rotating prompts
  void _startPeriodicTasks() {
    Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (mounted) {
        setState(() {
          _promptIndex = (_promptIndex + 1) % prompts.length;
        });
      }
    });
  }

  /// Load initial data from various sources
  Future<void> _loadInitialData() async {
    await _fetchAffirmation();
    await _loadLastMood();
  }

  /// Fetch a random affirmation
  Future<void> _fetchAffirmation() async {
    try {
      // TODO: Replace with actual API call or local database
      setState(() {
        affirmation = "Stay positive and keep moving forward!";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          affirmation = "Stay positive and keep moving forward!";
        });
      }
    }
  }

  /// Load the last logged mood from Supabase
  Future<void> _loadLastMood() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      if (userId == null) {
        print('No user ID found');
        return;
      }

      print('Loading last mood for user ID: $userId');

      final List<Map<String, dynamic>> response = await supabase
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      print('Supabase response: ${response.length} records found');

      if (response.isNotEmpty) {
        final Map<String, dynamic> latestMood = response.first;
        final String? label = latestMood['label'];
        final String? emoji = latestMood['emoji'];

        print('Latest mood from DB: label="$label", emoji="$emoji"');
        print(
          'Available mood labels: ${moods.map((m) => m['label']).toList()}',
        );

        if (label != null) {
          // Find index of this mood
          int index = moods.indexWhere((m) => m['label'] == label);
          print('Found index: $index');

          if (index == -1) {
            // Try case-insensitive search
            print('Mood label "$label" not found in moods list');
            index = moods.indexWhere(
              (m) =>
                  (m['label'] as String).toLowerCase() == label.toLowerCase(),
            );
            if (index != -1) {
              print('Found case-insensitive match at index: $index');
            }
          }

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

  /// Log a mood entry to Supabase
  Future<void> _logMoodToSupabase(Map<String, dynamic> mood) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      if (userId == null) {
        _showSnackBar('Please log in to save moods', Colors.orange);
        return;
      }

      await supabase.from('mood_logs').insert({
        'user_id': userId,
        'label': mood['label'],
        'emoji': mood['emoji'],
        'color_value': (mood['color'] as Color).value,
        'created_at': DateTime.now().toIso8601String(),
      });

      _showSnackBar(
        'Mood logged: ${mood['emoji']} ${mood['label']}',
        mood['color'] as Color,
      );
    } catch (e) {
      print('Error logging mood: $e');
      _showSnackBar('Failed to log mood', Colors.red);
    }
  }

  /// Helper method to show snackbars
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Get appropriate greeting based on time of day
  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  void dispose() {
    _bgController.dispose();
    _moodController.dispose();
    _promptController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double safePadding = MediaQuery.of(context).padding.bottom;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    // Define pages dynamically in build method to access context
    final List<Widget> pages = [
      HomeTabContent(
        bgController: _bgController,
        hearts: _hearts,
        header: _buildHeaderSection(),
        moodSection: _buildInteractiveMoodSection(),
        affirmationCard: _buildAffirmationCard(),
        quickActionsBuilder: (maxWidth, tablet) =>
            _buildQuickActions(isTablet: tablet),
        moodHistoryButton: _buildMoodHistoryButton(),
      ),
      const ChatTabPage(),
      const ExploreTabPage(),
      ProfileTabPage(userName: widget.userName),
    ];

    return Stack(
      children: <Widget>[
        const BackgroundGradient(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: pages),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _buildHelpButton(),
          bottomNavigationBar: _buildBottomNavigationBar(safePadding),
        ),
      ],
    );
  }

  /// Build the main help/support floating action button
  Widget _buildHelpButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: <BoxShadow>[
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

  /// Build the bottom navigation bar
  Widget _buildBottomNavigationBar(double safePadding) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.only(bottom: max(safePadding, 4), top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildNavigationButton(Icons.home_rounded, "Home", 0, isTablet),
          _buildNavigationButton(Icons.chat_rounded, "Chat", 1, isTablet),
          SizedBox(width: isTablet ? 80 : 40),
          _buildNavigationButton(Icons.explore_rounded, "Explore", 2, isTablet),
          _buildNavigationButton(Icons.person_rounded, "Profile", 3, isTablet),
        ],
      ),
    );
  }

  /// Build individual navigation button
  Widget _buildNavigationButton(
    IconData icon,
    String label,
    int index,
    bool isTablet,
  ) {
    final bool isActive = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: isActive ? Colors.pink[400] : Colors.grey[500],
              size: isTablet ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 11 : 10,
                color: isActive ? Colors.pink[400] : Colors.grey[500],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open the talk options bottom sheet
  void _openTalkSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
                    children: <Widget>[
                      _buildBottomSheetHandle(),
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
                            MaterialPageRoute<void>(
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
                            MaterialPageRoute<void>(
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
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const HelplinePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
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

  /// Build the bottom sheet drag handle
  Widget _buildBottomSheetHandle() {
    return Container(
      width: 60,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Build a talk option tile
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
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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

  // ============ HOME TAB SPECIFIC WIDGETS ============

  /// Build the header section with greeting and date
  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.pink[300]!.withOpacity(0.95),
            Colors.pink[200]!.withOpacity(0.8),
            Colors.pink[100]!.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.4, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildWelcomeRow(),
              const SizedBox(height: 20),
              _buildDateIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the welcome row with animated heart
  Widget _buildWelcomeRow() {
    return Row(
      children: <Widget>[
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (BuildContext context, Widget? child) {
            return Transform.scale(
              scale: _heartAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Colors.pink[200]!, Colors.pink[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: <BoxShadow>[
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
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "${_greeting()}, ${widget.userName}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: <Shadow>[
                    Shadow(blurRadius: 6, color: Colors.black38),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey<int>(_promptIndex),
                  prompts[_promptIndex],
                  style: TextStyle(
                    fontSize: 16,
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
    );
  }

  /// Build the date indicator with weekday
  Widget _buildDateIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.pink[100]!.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildDateSection("Today", _formatDate(DateTime.now())),
          _buildDivider(),
          _buildDateSection("It's", _getWeekday(DateTime.now())),
        ],
      ),
    );
  }

  /// Build a date section within the indicator
  Widget _buildDateSection(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a vertical divider
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.3),
    );
  }

  /// Format date as MM/DD/YY
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
  }

  /// Get weekday name
  String _getWeekday(DateTime date) {
    const List<String> weekdays = <String>[
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

  /// Build the interactive mood selection section
  Widget _buildInteractiveMoodSection() {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double viewportFraction = isTablet ? 0.32 : 0.35;
    final double itemWidth = screenWidth * viewportFraction;

    return Glass(
      blur: 20,
      opacity: 0.25,
      borderRadius: 24,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.pink[50]!.withOpacity(0.3),
              Colors.purple[50]!.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildMoodSectionHeader(isTablet),
            const SizedBox(height: 16),
            _buildMoodCarousel(itemWidth, isTablet),
            const SizedBox(height: 12),
            _buildMoodIndicators(isTablet),
          ],
        ),
      ),
    );
  }

  /// Build mood section header
  Widget _buildMoodSectionHeader(bool isTablet) {
    return Row(
      children: <Widget>[
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
    );
  }

  /// Build the mood selection carousel
  Widget _buildMoodCarousel(double itemWidth, bool isTablet) {
    return SizedBox(
      height: isTablet ? 150 : 110,
      child: PageView.builder(
        controller: _moodController,
        itemCount: moods.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (int index) => setState(() => _currentMood = index),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> mood = moods[index];
          final bool isSelected = index == _currentMood;
          return _buildMoodItem(mood, isSelected, itemWidth, isTablet, index);
        },
      ),
    );
  }

  /// Build individual mood item
  Widget _buildMoodItem(
    Map<String, dynamic> mood,
    bool isSelected,
    double itemWidth,
    bool isTablet,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _onMoodSelected(mood, index),
      child: Container(
        width: itemWidth - 12,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? <Color>[
                      (mood['color'] as Color).withOpacity(0.4),
                      (mood['color'] as Color).withOpacity(0.2),
                    ]
                  : <Color>[
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (mood['color'] as Color).withOpacity(0.6)
                  : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: (mood['color'] as Color).withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                mood['emoji'],
                style: TextStyle(fontSize: isTablet ? 36 : 28),
              ),
              const SizedBox(height: 12),
              Text(
                mood['label'],
                style: TextStyle(
                  fontSize: isTablet ? 14 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (mood['color'] as Color)
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle mood selection
  void _onMoodSelected(Map<String, dynamic> mood, int index) async {
    await _logMoodToSupabase(mood);
    setState(() => _currentMood = index);
    _moodController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Build mood page indicators
  Widget _buildMoodIndicators(bool isTablet) {
    return Center(
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
    );
  }

  /// Build the affirmation card
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
              colors: <Color>[
                Colors.purple[100]!.withOpacity(0.4),
                Colors.blue[100]!.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
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
                ],
              ),
              const SizedBox(height: 16),
              Text(
                affirmation ??
                    "Stay positive and keep moving forward! Every day is a fresh start.",
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the mood history button
  Widget _buildMoodHistoryButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const MoodHistoryPage()),
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
              colors: <Color>[
                Colors.pink[50]!.withOpacity(0.3),
                Colors.pink[100]!.withOpacity(0.3),
              ],
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
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
                  children: <Widget>[
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

  /// Build quick action buttons (Journal, Breathe)
  Widget _buildQuickActions({required bool isTablet}) {
    final List<Map<String, dynamic>> actions = <Map<String, dynamic>>[
      {
        'icon': Icons.edit_note_rounded,
        'label': 'Journal',
        'color': Colors.orange[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const JournalPage()),
        ),
      },
      {
        'icon': Icons.self_improvement_rounded,
        'label': 'Breathe',
        'color': Colors.purple[400]!,
        'route': () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                BreathMeditationPage(accent: Colors.pink[400]!),
          ),
        ),
      },
    ];

    final double itemHeight = isTablet ? 200.0 : 150.0;
    const int crossAxisCount = 2;
    final int totalRows = (actions.length / crossAxisCount).ceil();
    final double totalHeight =
        (totalRows * itemHeight) + ((totalRows - 1) * 16);

    return SizedBox(
      height: totalHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isTablet ? 16 : 12,
          mainAxisSpacing: isTablet ? 16 : 12,
          childAspectRatio: isTablet ? 2.6 : 1.4,
        ),
        itemCount: actions.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> action = actions[index];
          return _buildQuickActionItem(action, isTablet);
        },
      ),
    );
  }

  /// Build individual quick action item
  Widget _buildQuickActionItem(Map<String, dynamic> action, bool isTablet) {
    final Color actionColor = action['color'] as Color;

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
              colors: <Color>[
                actionColor.withOpacity(0.2),
                actionColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  action['icon'] as IconData,
                  size: isTablet ? 100 : 80,
                  color: actionColor.withOpacity(0.08),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: isTablet ? 48 : 40,
                      height: isTablet ? 48 : 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: actionColor.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: actionColor,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
}

/// Home tab content widget - separated for better organization
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
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    final double safePadding = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      slivers: <Widget>[
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
              children: <Widget>[
                AnimatedBuilder(
                  animation: bgController,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: HeartsPainter(hearts, bgController.value),
                    );
                  },
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
              children: <Widget>[
                moodSection,
                const SizedBox(height: 20),
                affirmationCard,
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) =>
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
