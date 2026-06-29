import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/app_navigation.dart';

class AiLoadingScreen extends StatefulWidget {
  const AiLoadingScreen({super.key});

  @override
  State<AiLoadingScreen> createState() => _AiLoadingScreenState();
}

class _AiLoadingScreenState extends State<AiLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  final List<_LoadingStep> _steps = [
    _LoadingStep(icon: Icons.wifi, label: 'Connecting...'),
    _LoadingStep(icon: Icons.inbox, label: 'Loading Inbox...'),
    _LoadingStep(icon: Icons.category_outlined, label: 'Classifying Emails...'),
    _LoadingStep(icon: Icons.summarize_outlined, label: 'Generating Summaries...'),
    _LoadingStep(icon: Icons.wb_sunny_outlined, label: 'Building Smart Daily Brief...'),
    _LoadingStep(icon: Icons.check_circle, label: 'Ready!'),
  ];

  int _currentStep = 0;
  final List<bool> _completed = [];

  @override
  void initState() {
    super.initState();
    _completed.addAll(List.filled(_steps.length, false));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runSteps();
  }

  Future<void> _runSteps() async {
    const stepDuration = Duration(milliseconds: 500);
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() {
        _completed[i] = true;
        if (i + 1 < _steps.length) _currentStep = i + 1;
      });
    }
    // Short pause then navigate
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppNavigation.dailyBrief);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated logo
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, Color(0xFFD93025)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SmartInbox AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preparing your intelligent inbox…',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 48),
              // Step list
              ..._steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                return _StepRow(
                  step: step,
                  isCompleted: _completed[idx],
                  isActive: idx == _currentStep && !_completed[idx],
                );
              }),
              const Spacer(),
              // Progress bar
              _AnimatedProgressBar(
                progress: _completed.where((c) => c).length / _steps.length,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatefulWidget {
  final _LoadingStep step;
  final bool isCompleted;
  final bool isActive;

  const _StepRow({
    required this.step,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_StepRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _checkController.forward();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color textColor;
    Widget leading;

    if (widget.isCompleted) {
      iconColor = AppTheme.success;
      textColor = AppTheme.text;
      leading = ScaleTransition(
        scale: _checkScale,
        child: Icon(Icons.check_circle, color: iconColor, size: 22),
      );
    } else if (widget.isActive) {
      iconColor = AppTheme.secondary;
      textColor = AppTheme.secondary;
      leading = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: iconColor,
        ),
      );
    } else {
      iconColor = Colors.grey.shade300;
      textColor = Colors.grey.shade400;
      leading = Icon(widget.step.icon, color: iconColor, size: 22);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isCompleted
            ? AppTheme.success.withOpacity(0.04)
            : widget.isActive
                ? AppTheme.secondary.withOpacity(0.06)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isCompleted
              ? AppTheme.success.withOpacity(0.2)
              : widget.isActive
                  ? AppTheme.secondary.withOpacity(0.25)
                  : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 15,
                fontWeight: widget.isCompleted || widget.isActive
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: textColor,
              ),
              child: Text(widget.step.label),
            ),
          ),
          if (widget.isCompleted)
            Text(
              '✓',
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Initializing AI…',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingStep {
  final IconData icon;
  final String label;
  const _LoadingStep({required this.icon, required this.label});
}
