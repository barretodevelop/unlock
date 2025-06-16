
// lib/widgets/animated/bounce_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BounceWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scale;
  final bool enableHaptic;
  final Curve curve;

  const BounceWidget({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
    this.enableHaptic = true,
    this.curve = Curves.easeInOut,
  });

  @override
  State<BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<BounceWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
