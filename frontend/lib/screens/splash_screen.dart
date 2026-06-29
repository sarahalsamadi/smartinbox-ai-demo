import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppNavigation.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Logo with animated scale + fade
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _buildLogoStack(),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            FadeTransition(
              opacity: _fadeAnim,
              child: const Text(
                'SmartInbox AI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle with delayed fade
            FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                'Your AI Email Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Bottom Google-colored dots indicator
            FadeTransition(
              opacity: _subtitleFade,
              child: _buildColorDots(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primary.withOpacity(0.12),
                AppTheme.secondary.withOpacity(0.06),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Inner circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, Color(0xFFD93025)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_unread,
            color: Colors.white,
            size: 48,
          ),
        ),
        // AI sparkle badge
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorDots() {
    const colors = [
      AppTheme.secondary,  // blue
      AppTheme.primary,    // red
      AppTheme.warning,    // yellow
      AppTheme.success,    // green
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((c) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
      }).toList(),
    );
  }
}
