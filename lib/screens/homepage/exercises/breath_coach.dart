// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class BreathCoach extends StatefulWidget {
  final Color accent;
  const BreathCoach({super.key, required this.accent});

  @override
  State<BreathCoach> createState() => BreathCoachState();
}

class BreathCoachState extends State<BreathCoach>
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
