// lib/features/home/widgets/animated_floating_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/router/app_router.dart';

/// Floating Action Button animado com efeitos visuais e micro-interações
class AnimatedFloatingButton extends StatefulWidget {
  const AnimatedFloatingButton({super.key});

  @override
  State<AnimatedFloatingButton> createState() => _AnimatedFloatingButtonState();
}

class _AnimatedFloatingButtonState extends State<AnimatedFloatingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _pressController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPulseAnimation();
  }

  void _setupAnimations() {
    // Animação de pulso contínua
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animação de rotação no tap
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.125, // 45 graus
        ).animate(
          CurvedAnimation(
            parent: _rotationController,
            curve: Curves.elasticOut,
          ),
        );

    // Animação de press
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));

    _elevationAnimation = Tween<double>(
      begin: 6.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _pressController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * _scaleAnimation.value,
          child: Transform.rotate(
            angle:
                _rotationAnimation.value *
                2 *
                3.14159, // Converter para radianos
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value + 4,
                    offset: Offset(0, _elevationAnimation.value / 2),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _handleTap,
                elevation: _elevationAnimation.value,
                backgroundColor: theme.colorScheme.primary,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de fundo com gradiente
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Ícone com efeito de brilho
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Icon(
                        Icons.connect_without_contact,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Indicador de pulse
                    if (!_isPressed)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    (1 - _pulseAnimation.value) * 0.5,
                                  ),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    setState(() {
      _isPressed = true;
    });

    // Feedback tátil
    HapticFeedback.mediumImpact();

    // Animações
    _pressController.forward().then((_) {
      _pressController.reverse();
    });

    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });

    // Reset do estado após um delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });

    // Mostrar ripple effect personalizado
    _showCustomRipple();

    // Navegar para conexões
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.go(AppRoutes.connections);
      }
    });
  }

  void _showCustomRipple() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset center =
        renderBox.localToGlobal(Offset.zero) +
        Offset(renderBox.size.width / 2, renderBox.size.height / 2);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => _CustomRippleEffect(center: center),
    );

    // Auto-fechar o ripple
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }
}

/// Efeito de ripple personalizado
class _CustomRippleEffect extends StatefulWidget {
  final Offset center;

  const _CustomRippleEffect({required this.center});

  @override
  State<_CustomRippleEffect> createState() => _CustomRippleEffectState();
}

class _CustomRippleEffectState extends State<_CustomRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _radiusAnimation = Tween<double>(
      begin: 0,
      end: 150,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: widget.center.dx - _radiusAnimation.value,
              top: widget.center.dy - _radiusAnimation.value,
              child: Container(
                width: _radiusAnimation.value * 2,
                height: _radiusAnimation.value * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(
                    _opacityAnimation.value * 0.3,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(
                      _opacityAnimation.value,
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
