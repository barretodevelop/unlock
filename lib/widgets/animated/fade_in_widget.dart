// lib/widgets/animated/fade_in_widget.dart
import 'package:flutter/material.dart';

class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double fromOpacity;
  final double toOpacity;
  final Offset? fromOffset;
  final Offset? toOffset;
  final Curve curve;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.fromOpacity = 0.0,
    this.toOpacity = 1.0,
    this.fromOffset,
    this.toOffset,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.fromOpacity,
      end: widget.toOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.fromOffset != null || widget.toOffset != null) {
      _slideAnimation = Tween<Offset>(
        begin: widget.fromOffset ?? Offset.zero,
        end: widget.toOffset ?? Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
    }
  }

  void _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
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
        Widget result = FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        );

        if (_slideAnimation != null) {
          result = SlideTransition(
            position: _slideAnimation!,
            child: result,
          );
        }

        return result;
      },
    );
  }
}

// Variações especializadas do FadeInWidget

class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      duration: duration,
      delay: delay,
      fromOffset: const Offset(0, 0.3),
      toOffset: Offset.zero,
      child: child,
    );
  }
}

class FadeInDown extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInDown({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      duration: duration,
      delay: delay,
      fromOffset: const Offset(0, -0.3),
      toOffset: Offset.zero,
      child: child,
    );
  }
}

class FadeInLeft extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInLeft({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      duration: duration,
      delay: delay,
      fromOffset: const Offset(-0.3, 0),
      toOffset: Offset.zero,
      child: child,
    );
  }
}

class FadeInRight extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInRight({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      duration: duration,
      delay: delay,
      fromOffset: const Offset(0.3, 0),
      toOffset: Offset.zero,
      child: child,
    );
  }
}