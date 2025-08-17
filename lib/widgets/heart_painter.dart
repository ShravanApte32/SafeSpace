// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hereforyou/models/hearts.dart';

class HeartsPainter extends CustomPainter {
  final List<FloatHeart> hearts;
  final double t; // 0..1 loop

  HeartsPainter(this.hearts, this.t);

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
  bool shouldRepaint(covariant HeartsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.hearts != hearts;
}
