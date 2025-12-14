import 'package:flutter/material.dart';
import 'package:hereforyou/screens/onboarding_screen/onboarding_screen.dart';
import 'package:hereforyou/screens/urgent_help_screen/urgent_help_screen.dart';
import 'package:hereforyou/widgets/app_loader.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _offsetAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigate(
    BuildContext context,
    Widget nextPage, {
    bool showLoader = false,
  }) {
    if (showLoader) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (_) => const AppLoader(),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => nextPage,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
      });
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextPage,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EC),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1.5,
                    child: Lottie.asset(
                      'assets/animations/exit.json',
                      height: 80,
                      width: 80,
                      repeat: true,
                      animate: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Exit SafeSpace?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF9A9A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your safe space will be here whenever you need it.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFEF9A9A),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Stay',
                          style: TextStyle(
                            color: Color(0xFFEF9A9A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF9A9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE0E0), Color(0xFFFCE4EC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _offsetAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _offsetAnimation.value),
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Hero(
                              tag: 'app_logo',
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.2),
                                      blurRadius: 25,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Lottie.asset(
                                  'assets/animations/lil_heart.json',
                                  height: 130,
                                  options: LottieOptions(
                                    enableMergePaths: true,
                                  ),
                                  frameRate: FrameRate.max,
                                  repeat: true,
                                  animate: true,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "Hey, you're safe here.",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "Whenever you feel unheard, we're here to listen with compassion and understanding.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  navigate(
                                    context,
                                    OnboardingScreen(),
                                    showLoader: true,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    238,
                                    101,
                                    101,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 18,
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Let's Start Talking",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward_rounded, size: 22),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              TextButton(
                                onPressed: () {
                                  navigate(
                                    context,
                                    UrgentHelpPage(),
                                    showLoader: false,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.emergency_rounded,
                                      size: 20,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "I need urgent help",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: Colors.black45,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Your conversations are private and secure.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
