import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/permission_service.dart';
import '../theme/app_colors.dart';
import 'home_shell.dart';

/// Animated splash screen shown at app launch.
///
/// Displays for [_splashDuration] then navigates to [HomeShell].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 3);

  late final AnimationController _floatController;
  late final AnimationController _spinController;
  late final AnimationController _fadeController;

  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Request all required permissions as early as possible after the first
    // frame so the OS dialogs appear over a fully rendered splash screen.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => PermissionService.requestAll(),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    Future.delayed(_splashDuration, _navigateToHome);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeShell(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _GradientMeshBackground(),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  _CentralCluster(floatAnimation: _floatAnimation),
                  const Spacer(),
                  _BottomCluster(spinController: _spinController),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft radial gradient mesh in the corners — matches design.
class _GradientMeshBackground extends StatelessWidget {
  const _GradientMeshBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MeshPainter());
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = RadialGradient(
      center: Alignment.topLeft,
      radius: 0.7,
      colors: [
        AppColors.primaryContainer.withValues(alpha: 0.45),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final topRight = RadialGradient(
      center: Alignment.topRight,
      radius: 0.7,
      colors: [
        AppColors.secondaryContainer.withValues(alpha: 0.35),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final bottomRight = RadialGradient(
      center: Alignment.bottomRight,
      radius: 0.7,
      colors: [
        AppColors.primaryFixed.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = topLeft
        ..blendMode = BlendMode.srcOver,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = topRight
        ..blendMode = BlendMode.srcOver,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = bottomRight
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// App icon + brand name.
class _CentralCluster extends StatelessWidget {
  const _CentralCluster({required this.floatAnimation});

  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatingIcon(animation: floatAnimation),
        const SizedBox(height: 24),
        Text(
          'FlexFlow',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 44 / 36,
            letterSpacing: -0.72,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// App icon inside a white card with glow and float animation.
class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow
          Container(
            width: 224,
            height: 224,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(52),
              color: AppColors.primaryContainer.withValues(alpha: 0.28),
            ),
          ),
          // White icon card
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(42),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tagline and spinning loader.
class _BottomCluster extends StatelessWidget {
  const _BottomCluster({required this.spinController});

  final AnimationController spinController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'FIND YOUR FLOW.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 48,
          height: 48,
          child: AnimatedBuilder(
            animation: spinController,
            builder: (context, _) {
              return CustomPaint(
                painter: _SpinnerPainter(progress: spinController.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Custom circular spinner with a track and rotating arc, matching the design.
class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.secondaryContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Rotating arc
    final arcPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const sweepAngle = math.pi * 0.4; // ~72° arc
    final startAngle = 2 * math.pi * progress - math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
