import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animates a numeric value counting up from 0 to [value] once, then stays
/// put. Used for hero/KPI numbers so the dashboard feels alive without being
/// distracting — a single fast run, not a repeating animation.
class CountUpNumber extends StatelessWidget {
  const CountUpNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 700),
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat(decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          '$prefix${formatter.format(animatedValue)}$suffix',
          style: style,
        );
      },
    );
  }
}

/// Fades and slides a section in once it first builds. Staggering several of
/// these by [delay] gives a subtle, professional "cascading" entrance without
/// a dedicated animation package.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Lays two sections side by side once the viewport is wide enough (tablet /
/// desktop / web), otherwise stacks them — used to pair related analytics
/// cards (Wear + Outfit, Category + Color) per the dashboard's responsive
/// layout requirements.
class ResponsiveTwoColumn extends StatelessWidget {
  const ResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 900,
    this.spacing = 16,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [left, SizedBox(height: spacing), right],
        );
      },
    );
  }
}
