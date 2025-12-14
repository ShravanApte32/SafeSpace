import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hereforyou/screens/welcome_screen/welcome_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle haptic feedback
    HapticFeedback.lightImpact();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();

    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? const [
                    Color(0xFF1E1E1E),
                    Color(0xFF2A2A2A),
                    Color(0xFF3A1F1F),
                  ]
                : const [
                    Color(0xFFFFE0E0),
                    Color(0xFFFCE4EC),
                    Color(0xFFF8BBD0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Stack(
              children: [
                // Animated background elements
                Positioned(
                  top: 100,
                  right: -30,
                  child: Opacity(
                    opacity: _fadeAnimation.value * 0.2,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent.withOpacity(0.3),
                            Colors.redAccent.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                Positioned(
                  bottom: 120,
                  left: -60,
                  child: Opacity(
                    opacity: _fadeAnimation.value * 0.15,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.2),
                            Colors.pink.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(
                                    0.3 * _fadeAnimation.value,
                                  ),
                                  blurRadius: 25,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              'assets/animations/lil_heart.json',
                              height: 120,
                              repeat: true,
                              animate: true,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      SlideTransition(
                        position: _textSlideAnimation,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                "SafeSpace",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode 
                                      ? Colors.white70 
                                      : Colors.black87,
                                  letterSpacing: 1.2,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Here for you, always",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDarkMode 
                                      ? Colors.white60 
                                      : Colors.black54,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Animated loading indicator
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: SizedBox(
                          width: 120,
                          child: LinearProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode 
                                  ? Colors.pinkAccent 
                                  : Color.fromARGB(255, 238, 101, 101),
                            ),
                            backgroundColor: Colors.transparent,
                            minHeight: 2,
                            value: _fadeController.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}