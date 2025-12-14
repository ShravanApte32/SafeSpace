// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hereforyou/screens/login_screen/login_screen.dart';
import 'package:hereforyou/widgets/app_loader.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _autoSwipeTimer;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, String>> onboardingData = [
    {
      "lottie": "assets/animations/ai_friend.json",
      "title": "Welcome to Your Space",
      "desc":
          "A safe and calming place designed just for you, where every conversation matters.",
    },
    {
      "lottie": "assets/animations/smart_conversations.json",
      "title": "Talk. Share. Feel Better.",
      "desc":
          "Open up about your thoughts and feelings anytime — we're here to listen and guide.",
    },
    {
      "lottie": "assets/animations/stay_connected.json",
      "title": "Your Journey to Wellness",
      "desc":
          "Small steps lead to big changes. Let's begin your path toward a happier, healthier you.",
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animController.forward();

    _autoSwipeTimer = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      if (_controller.hasClients) {
        _animController.reverse().then((_) {
          int nextPage = (_currentPage + 1) % onboardingData.length;
          _controller.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          _animController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void navigateWithLoader(BuildContext context, Widget nextPage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoader(),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => nextPage));
    });
  }

  void _goToLogin() {
    navigateWithLoader(context, const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animController.reset();
                  _animController.forward();
                },
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            
                            // Animated Lottie Container
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.pinkAccent.withOpacity(0.15),
                                    Colors.transparent,
                                ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pinkAccent.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Lottie.asset(
                                onboardingData[index]["lottie"]!,
                                height: 250,
                                fit: BoxFit.contain,
                                animate: true,
                                repeat: true,
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Title with fade animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                onboardingData[index]["title"]!,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description with slide animation
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.2),
                                end: Offset.zero,
                              ).animate(_animController),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  onboardingData[index]["desc"]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Enhanced Page Indicators
            Container(
              height: 60,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 28 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.redAccent
                            : Colors.redAccent.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _currentPage == index ? [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Enhanced Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button (Left side)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage != onboardingData.length - 1
                        ? TextButton(
                            key: const ValueKey('skip'),
                            onPressed: _goToLogin,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          )
                        : const SizedBox(width: 80, key: ValueKey('space')),
                  ),

                  // Get Started/Next Button (Right side)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_currentPage),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _goToLogin,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentPage == onboardingData.length - 1
                              ? const Text(
                                  "Get Started",
                                  key: ValueKey('get_started'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Row(
                                  key: ValueKey('next'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Next",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}