// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hereforyou/screens/urgent_help_screen/emergency_contacts_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UrgentHelpPage extends StatefulWidget {
  const UrgentHelpPage({super.key});

  @override
  State<UrgentHelpPage> createState() => _UrgentHelpPageState();
}

class _UrgentHelpPageState extends State<UrgentHelpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _gradientAnimation;

  final List<Map<String, dynamic>> _helpOptions = [
    {
      'icon': Icons.phone_in_talk_rounded,
      'title': 'National Helpline',
      'subtitle': 'Speak with trained counselors now',
      'color': const Color(0xFFFF5252),
      'gradient': [const Color(0xFFFF5252), const Color(0xFFFF8A80)],
      'action': 'call',
      'number': '917020666430',
    },
    {
      'icon': Icons.chat_rounded,
      'title': 'WhatsApp Support',
      'subtitle': '24/7 anonymous chat support',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF81C784)],
      'action': 'whatsapp',
      'number': '917020666430',
    },
    {
      'icon': Icons.contact_emergency_rounded,
      'title': 'Emergency Contacts',
      'subtitle': 'Your trusted support network',
      'color': const Color(0xFF7986CB),
      'gradient': [const Color(0xFF7986CB), const Color(0xFF9FA8DA)],
      'action': 'contacts',
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xFFFFE0E0),
      end: const Color(0xFFFCE4EC),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Start floating animation loop
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_controller.status == AnimationStatus.completed) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 800), () {
          _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  void _openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = "whatsapp://send?phone=$phone&text=$encodedMessage";

    if (await canLaunchUrlString(whatsappUrl)) {
      await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = "https://wa.me/$phone?text=$encodedMessage";
      if (await canLaunchUrlString(fallbackUrl)) {
        await launchUrlString(
          fallbackUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  void _handleAction(Map<String, dynamic> option) {
    switch (option['action']) {
      case 'call':
        _callNumber(option['number']);
        break;
      case 'whatsapp':
        _openWhatsApp(option['number'], "Hi, I need urgent emotional support.");
        break;
      case 'contacts':
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const EmergencyContactsPage(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                child: child,
              );
            },
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _gradientAnimation.value!,
                  _gradientAnimation.value!.withOpacity(0.8),
                ],
                center: Alignment.topRight,
                radius: 1.8,
                stops: [0.1, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(8, (index) {
                  return Positioned(
                    top: 100 + sin(index * 0.8 + _controller.value * 2) * 50,
                    left: 50 + cos(index * 0.5 + _controller.value) * 200,
                    child: Opacity(
                      opacity: 0.1 + 0.1 * sin(index + _controller.value * 3),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.pinkAccent.withOpacity(0.1),
                              Colors.pinkAccent.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated header
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(-1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _controller,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Urgent Support",
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Immediate help when you need it",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Hero animation with floating effect
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Center(
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.pinkAccent.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.1, 1.0],
                                  ),
                                ),
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    sin(_controller.value * 2 * pi) * 10,
                                  ),
                                  child: Lottie.asset(
                                    'assets/animations/lil_heart.json',
                                    repeat: true,
                                    animate: true,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Help cards with staggered animation
                          ...List.generate(_helpOptions.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: 16,
                                top: index == 0 ? 0 : 0,
                              ),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  _slideAnimation.value * (index + 1),
                                ),
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: _HelpOptionCard(
                                    option: _helpOptions[index],
                                    delay: index * 200,
                                    onTap: () =>
                                        _handleAction(_helpOptions[index]),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 40),

                          // Safety message with animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _controller,
                                      curve: const Interval(0.3, 0.5),
                                    ),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFF7986CB),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Secure & Confidential",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "All conversations are protected with end-to-end encryption and remain completely private.",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpOptionCard extends StatefulWidget {
  final Map<String, dynamic> option;
  final int delay;
  final VoidCallback onTap;

  const _HelpOptionCard({
    required this.option,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_HelpOptionCard> createState() => _HelpOptionCardState();
}

class _HelpOptionCardState extends State<_HelpOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay + 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: MouseRegion(
            onEnter: (_) {
              if (mounted) {
                _controller.reverse();
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _controller.forward();
                });
              }
            },
            child: GestureDetector(
              onTap: () {
                _controller.reverse().then((_) {
                  _controller.forward();
                  widget.onTap();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: List<Color>.from(widget.option['gradient']),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.option['color'].withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          widget.option['icon'],
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              widget.option['icon'],
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.option['title'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.option['subtitle'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
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
}
