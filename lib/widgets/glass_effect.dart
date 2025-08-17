// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final double blur;
  final double opacity;
  final double borderRadius;
  final Widget child;

  const Glass({
    super.key,
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
