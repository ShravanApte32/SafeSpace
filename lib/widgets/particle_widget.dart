// Add this as a new widget class in your file (outside _HomePageState)
// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';

class ParticleWidget extends StatefulWidget {
  final int numberOfParticles;
  final Color color;

  const ParticleWidget({
    super.key,
    this.numberOfParticles = 20,
    this.color = Colors.white,
  });

  @override
  State<ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Initialize particles
    final random = Random();
    particles = List.generate(widget.numberOfParticles, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 5 + 2,
        speed: random.nextDouble() * 0.5 + 0.1,
        angle: random.nextDouble() * 2 * pi,
        color: widget.color.withOpacity(random.nextDouble() * 0.5 + 0.3),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particle positions
        for (var particle in particles) {
          particle.x += cos(particle.angle) * particle.speed * 0.01;
          particle.y += sin(particle.angle) * particle.speed * 0.01;

          // Wrap around screen edges
          if (particle.x > 1.2) particle.x = -0.2;
          if (particle.x < -0.2) particle.x = 1.2;
          if (particle.y > 1.2) particle.y = -0.2;
          if (particle.y < -0.2) particle.y = 1.2;
        }

        return CustomPaint(
          painter: ParticlePainter(particles),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
