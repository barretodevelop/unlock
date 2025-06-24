// lib/shared/widgets/animated_fab.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';

/// FAB animado com rotação e efeitos visuais
class AnimatedFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Animation<double>? rotationAnimation;
  final bool isExpanded;
  final IconData? icon;
  final IconData? expandedIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    this.rotationAnimation,
    this.isExpanded = false,
    this.icon,
    this.expandedIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: rotationAnimation ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Transform.rotate(
          angle: (rotationAnimation?.value ?? 0) * 2 * 3.14159,
          child: Container(
            width: size ?? 56,
            height: size ?? 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor ?? colorScheme.primary,
                  backgroundColor?.withOpacity(0.8) ??
                      colorScheme.primary.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (backgroundColor ?? colorScheme.primary).withOpacity(
                    0.4,
                  ),
                  blurRadius: isExpanded ? 16 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: isExpanded ? 2 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppConstants.animationDuration,
                    transitionBuilder: (child, animation) {
                      return RotationTransition(turns: animation, child: child);
                    },
                    child: Icon(
                      isExpanded
                          ? (expandedIcon ?? Icons.close)
                          : (icon ?? Icons.add),
                      key: ValueKey(isExpanded),
                      color: foregroundColor ?? Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// FAB com pulso animado
class PulsatingFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final bool enablePulse;

  const PulsatingFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.enablePulse = true,
  });

  @override
  State<PulsatingFAB> createState() => _PulsatingFABState();
}

class _PulsatingFABState extends State<PulsatingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePulse ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: widget.color,
            child: Icon(widget.icon),
          ),
        );
      },
    );
  }
}

/// FAB com efeito morphing
class MorphingFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool isToggled;

  const MorphingFAB({
    super.key,
    required this.onPressed,
    required this.primaryIcon,
    required this.secondaryIcon,
    this.primaryColor,
    this.secondaryColor,
    this.isToggled = false,
  });

  @override
  State<MorphingFAB> createState() => _MorphingFABState();
}

class _MorphingFABState extends State<MorphingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _morphController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: widget.primaryColor ?? Theme.of(context).colorScheme.primary,
      end: widget.secondaryColor ?? Theme.of(context).colorScheme.secondary,
    ).animate(_morphController);

    if (widget.isToggled) {
      _morphController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MorphingFAB oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isToggled != oldWidget.isToggled) {
      if (widget.isToggled) {
        _morphController.forward();
      } else {
        _morphController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: _colorAnimation.value,
          child: AnimatedSwitcher(
            duration: AppConstants.animationDuration ~/ 2,
            child: Icon(
              _morphAnimation.value < 0.5
                  ? widget.primaryIcon
                  : widget.secondaryIcon,
              key: ValueKey(_morphAnimation.value < 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// FAB com badge de notificação
class FABWithBadge extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final int? badgeCount;
  final Color? backgroundColor;
  final Color? badgeColor;

  const FABWithBadge({
    super.key,
    required this.onPressed,
    required this.icon,
    this.badgeCount,
    this.backgroundColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount != null && badgeCount! > 0;

    return Stack(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          child: Icon(icon),
        ),

        if (showBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// FAB com loading state
class LoadingFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final Color? backgroundColor;

  const LoadingFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  State<LoadingFAB> createState() => _LoadingFABState();
}

class _LoadingFABState extends State<LoadingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.isLoading) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingFAB oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      backgroundColor: widget.backgroundColor,
      child: widget.isLoading
          ? RotationTransition(
              turns: _rotationController,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(widget.icon),
    );
  }
}
