
// lib/widgets/animated/slide_in_widget.dart
import 'package:flutter/material.dart';

enum SlideDirection { left, right, up, down }

class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final SlideDirection direction;
  final double distance;
  final Curve curve;

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.direction = SlideDirection.up,
    this.distance = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = Offset(-widget.distance, 0);
        break;
      case SlideDirection.right:
        beginOffset = Offset(widget.distance, 0);
        break;
      case SlideDirection.up:
        beginOffset = Offset(0, widget.distance);
        break;
      case SlideDirection.down:
        beginOffset = Offset(0, -widget.distance);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
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
    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }
}
