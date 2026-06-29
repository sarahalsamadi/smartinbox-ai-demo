import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Reusable AI badge shown throughout the app to signal AI-processed content.
class AiBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final Color? bgColor;

  const AiBadge({
    super.key,
    required this.label,
    this.icon = Icons.auto_awesome,
    this.color,
    this.bgColor,
  });

  /// "Analyzed by AI" badge
  const AiBadge.analyzed({super.key})
    : label = 'Analyzed by AI',
      icon = Icons.psychology,
      color = null,
      bgColor = null;

  /// "Generated Summary" badge
  const AiBadge.summary({super.key})
    : label = 'Generated Summary',
      icon = Icons.summarize,
      color = null,
      bgColor = null;

  /// "AI Suggested Action" badge
  const AiBadge.suggested({super.key})
    : label = 'AI Suggested Action',
      icon = Icons.tips_and_updates,
      color = null,
      bgColor = null;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.secondary;
    final badgeBg = bgColor ?? AppTheme.secondary.withOpacity(0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that animates in with a fade + slide-up effect.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index; // used to stagger the animation
  final Duration delay;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    final stagger = widget.delay + Duration(milliseconds: widget.index * 80);
    Future.delayed(stagger, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Animated statistic card used in the productivity widget and KPI grid.
class AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final int index;

  const AnimatedStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.index = 0,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
              Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget shown when a list has no data.
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade400;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withOpacity(0.08),
                border: Border.all(color: c.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 44, color: c.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
