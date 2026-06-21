import 'dart:math';

import 'package:flutter/material.dart';

/// Self-contained confetti animation overlay.
///
/// Renders a one-shot burst of falling/rotating coloured rectangles using a
/// single `CustomPainter` driven by an `AnimationController`. No external
/// dependencies; meant to be dropped above other UI inside a `Stack`.
///
/// The overlay swallows no pointer events ([IgnorePointer]), so any UI behind
/// it remains interactive while the celebration plays. When the animation
/// finishes, [onDone] is called so the host can remove the overlay.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.colors,
    this.duration = const Duration(milliseconds: 3500),
    this.particleCount = 80,
    this.onDone,
  });

  /// Palette particles are sampled from.
  final List<Color> colors;

  /// Total time from emit to fall-off.
  final Duration duration;

  /// Number of confetti pieces in the burst.
  final int particleCount;

  /// Called once when the animation completes.
  final VoidCallback? onDone;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(rng, widget.colors),
    );
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Single confetti piece. All position values are normalised against the
/// painter's canvas size so the burst scales to any screen.
class _Particle {
  _Particle({
    required this.startX,
    required this.startY,
    required this.vy,
    required this.vx,
    required this.color,
    required this.width,
    required this.height,
    required this.rotationSpeed,
    required this.initialRotation,
    required this.delay,
  });

  factory _Particle.random(Random rng, List<Color> colors) {
    return _Particle(
      startX: rng.nextDouble(),
      startY: -0.05 - rng.nextDouble() * 0.1,
      vy: 0.75 + rng.nextDouble() * 0.5,
      vx: (rng.nextDouble() - 0.5) * 0.4,
      color: colors[rng.nextInt(colors.length)],
      width: 7 + rng.nextDouble() * 6,
      height: 9 + rng.nextDouble() * 8,
      rotationSpeed: (rng.nextDouble() - 0.5) * 6 * pi,
      initialRotation: rng.nextDouble() * 2 * pi,
      delay: rng.nextDouble() * 0.25,
    );
  }

  final double startX;
  final double startY;
  final double vy;
  final double vx;
  final Color color;
  final double width;
  final double height;
  final double rotationSpeed;
  final double initialRotation;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  static const double _gravity = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final yNorm = p.startY + p.vy * localT + 0.5 * _gravity * localT * localT;
      final xNorm = p.startX + p.vx * localT;
      final dx = xNorm * size.width;
      final dy = yNorm * size.height;
      if (dy > size.height + p.height) continue;

      final fadeStart = 0.75;
      final fade = localT < fadeStart
          ? 1.0
          : (1 - ((localT - fadeStart) / (1 - fadeStart))).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      final rotation = p.initialRotation + p.rotationSpeed * localT;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.width,
            height: p.height,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}
