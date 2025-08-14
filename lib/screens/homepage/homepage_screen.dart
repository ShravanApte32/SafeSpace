import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

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
    // Floating hearts animator
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Create some floating hearts with randomized paths/speeds
    final rnd = Random();
    _hearts = List.generate(
      16,
      (_) => _FloatHeart(
        startX: rnd.nextDouble(),
        size: rnd.nextDouble() * 22 + 10,
        speed: rnd.nextDouble() * 0.5 + 0.5,
        phase: rnd.nextDouble() * pi * 2,
        hue: rnd.nextInt(3), // slight color variety
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
          // appBar: AppBar(
          //   automaticallyImplyLeading: false,
          //   elevation: 0,
          //   backgroundColor: Colors.transparent,
          //   actions: [
          //     IconButton(
          //       icon: const Icon(
          //         Icons.notifications_none,
          //         color: Colors.black87,
          //       ),
          //       onPressed: () {},
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.settings, color: Colors.black87),
          //       onPressed: () {},
          //     ),
          //   ],
          // ),
          body: Stack(
            children: [
              // Soft gradient background
              const _BackgroundGradient(),
              // Floating hearts layer
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HeartsPainter(_hearts, _bgController.value),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
              // Content
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
                      _moodCarousel(),
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
                      _moodTrackerTeaser(),
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
          onTap: () {},
        ),
        _glassAction(
          title: "Chat",
          icon: Icons.chat_bubble_outline_rounded,
          color: Colors.teal,
          onTap: () {},
        ),
        _glassAction(
          title: "Breathe",
          icon: Icons.self_improvement_rounded,
          color: Colors.purple,
          onTap: () {
            _showBreathSheet();
          },
        ),
        _glassAction(
          title: "Helpline",
          icon: Icons.phone_in_talk_rounded,
          color: Colors.redAccent,
          onTap: () {},
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
    // One big card + two smaller cards
    return Column(
      children: [
        // Big card
        _featureBigCard(
          title: "Instant Listener",
          subtitle: "AI or human — your choice.\nWe’re here now.",
          icon: Icons.headset_mic_rounded,
          color: Colors.teal,
          onTap: () {},
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _featureSmallCard(
                title: "Community",
                icon: Icons.people_rounded,
                color: Colors.orange,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _featureSmallCard(
                title: "Resources",
                icon: Icons.health_and_safety_rounded,
                color: Colors.blueAccent,
                onTap: () {},
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
            Expanded(
              child: Text(
                "Track your mood and see your emotional journey over time.",
                style: TextStyle(fontSize: 14, color: Colors.pink[900]),
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
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _talkOption(
                    icon: Icons.headset_mic_rounded,
                    title: "Connect to Human Listener",
                    subtitle: "Real person, trained to listen",
                    color: Colors.teal,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _talkOption(
                    icon: Icons.sos_rounded,
                    title: "Crisis Helpline",
                    subtitle: "Verified numbers in your country",
                    color: Colors.redAccent,
                    onTap: () {},
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
