// lib/features/missions/widgets/progress_indicator.dart
// Indicadores de progresso para missões - Fase 3

import 'package:flutter/material.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'dart:math' as math;

/// Indicador de progresso linear personalizado
class MissionProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool animated;
  final Duration animationDuration;
  final String? label;
  final bool showPercentage;

  const MissionProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.label,
    this.showPercentage = false,
  });

  @override
  State<MissionProgressIndicator> createState() => _MissionProgressIndicatorState();
}

class _MissionProgressIndicatorState extends State<MissionProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MissionProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      
      _controller.reset();
      if (widget.animated) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? AppTheme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        theme.colorScheme.surfaceVariant;
    final effectiveBorderRadius = widget.borderRadius ?? 
        BorderRadius.circular(widget.height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label e porcentagem
        if (widget.label != null || widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final percentage = (_animation.value * 100).round();
                      return Text(
                        '$percentage%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: effectiveColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        
        // Barra de progresso
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: effectiveBorderRadius,
          ),
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: AnimatedBuilder(
              animation: widget.animated ? _animation : AlwaysStoppedAnimation(widget.progress),
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: widget.animated ? _animation.value : widget.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  minHeight: widget.height,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicador de progresso circular personalizado
class CircularMissionProgress extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;
  final bool animated;
  final Duration animationDuration;

  const CircularMissionProgress({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.progressColor,
    this.backgroundColor,
    this.child,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<CircularMissionProgress> createState() => _CircularMissionProgressState();
}

class _CircularMissionProgressState extends State<CircularMissionProgress>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CircularMissionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      
      _controller.reset();
      if (widget.animated) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor = widget.progressColor ?? AppTheme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        theme.colorScheme.surfaceVariant;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveBackgroundColor),
            ),
          ),
          
          // Círculo de progresso
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: widget.animated ? _animation : AlwaysStoppedAnimation(widget.progress),
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: widget.animated ? _animation.value : widget.progress,
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveProgressColor),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          
          // Conteúdo central
          if (widget.child != null)
            widget.child!
          else
            AnimatedBuilder(
              animation: widget.animated ? _animation : AlwaysStoppedAnimation(widget.progress),
              builder: (context, child) {
                final percentage = ((widget.animated ? _animation.value : widget.progress) * 100).round();
                return Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: effectiveProgressColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Indicador de progresso em steps/etapas
class StepProgressIndicator extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final double stepSize;
  final double lineWidth;
  final bool animated;
  final Duration animationDuration;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.stepSize = 24,
    this.lineWidth = 2,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<StepProgressIndicator> createState() => _StepProgressIndicatorState();
}

class _StepProgressIndicatorState extends State<StepProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StepProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentStep != widget.currentStep) {
      _controller.reset();
      if (widget.animated) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = widget.activeColor ?? AppTheme.primaryColor;
    final effectiveInactiveColor = widget.inactiveColor ?? 
        theme.colorScheme.onSurface.withOpacity(0.3);
    final effectiveCompletedColor = widget.completedColor ?? AppTheme.successColor;

    return AnimatedBuilder(
      animation: widget.animated ? _animation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Row(
          children: List.generate(
            widget.totalSteps * 2 - 1, // Steps + lines between them
            (index) {
              if (index.isEven) {
                // Step circle
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < widget.currentStep;
                final isActive = stepIndex == widget.currentStep;
                
                Color stepColor;
                if (isCompleted) {
                  stepColor = effectiveCompletedColor;
                } else if (isActive) {
                  stepColor = effectiveActiveColor;
                } else {
                  stepColor = effectiveInactiveColor;
                }

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (stepIndex * 100)),
                  width: widget.stepSize,
                  height: widget.stepSize,
                  decoration: BoxDecoration(
                    color: stepColor,
                    shape: BoxShape.circle,
                    boxShadow: (isActive || isCompleted) ? [
                      BoxShadow(
                        color: stepColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: widget.stepSize * 0.6,
                          )
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : 
                                     theme.colorScheme.surface,
                              fontWeight: FontWeight.w600,
                              fontSize: widget.stepSize * 0.4,
                            ),
                          ),
                  ),
                );
              } else {
                // Line between steps
                final lineIndex = index ~/ 2;
                final isActiveLine = lineIndex < widget.currentStep;
                
                return Expanded(
                  child: Container(
                    height: widget.lineWidth,
                    color: isActiveLine 
                        ? effectiveCompletedColor 
                        : effectiveInactiveColor,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

/// Indicador de progresso com gradiente animado
class GradientProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final List<Color> gradientColors;
  final double height;
  final BorderRadius? borderRadius;
  final bool animated;
  final Duration animationDuration;

  const GradientProgressIndicator({
    super.key,
    required this.progress,
    required this.gradientColors,
    this.height = 8,
    this.borderRadius,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<GradientProgressIndicator> createState() => _GradientProgressIndicatorState();
}

class _GradientProgressIndicatorState extends State<GradientProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _progressController.forward();
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(GradientProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ));
      
      _progressController.reset();
      if (widget.animated) {
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ?? 
        BorderRadius.circular(widget.height / 2);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: effectiveBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: AnimatedBuilder(
          animation: Listenable.merge([_progressAnimation, _shimmerAnimation]),
          builder: (context, child) {
            return Stack(
              children: [
                // Barra de progresso com gradiente
                FractionallySizedBox(
                  widthFactor: widget.animated ? _progressAnimation.value : widget.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                
                // Efeito shimmer
                if (widget.animated && _progressAnimation.value > 0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(_shimmerAnimation.value * 200, 0),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Indicador de progresso com padrão de ondas
class WaveProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final Color waveColor;
  final Color backgroundColor;
  final double height;
  final bool animated;

  const WaveProgressIndicator({
    super.key,
    required this.progress,
    required this.waveColor,
    required this.backgroundColor,
    this.height = 60,
    this.animated = true,
  });

  @override
  State<WaveProgressIndicator> createState() => _WaveProgressIndicatorState();
}

class _WaveProgressIndicatorState extends State<WaveProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _progressController;
  late Animation<double> _waveAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _waveController.repeat();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: AnimatedBuilder(
          animation: Listenable.merge([_waveAnimation, _progressAnimation]),
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                progress: widget.animated ? _progressAnimation.value : widget.progress,
                wavePhase: _waveAnimation.value,
                waveColor: widget.waveColor,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// Painter personalizado para efeito de ondas
class WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color waveColor;

  WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final progressWidth = size.width * progress;

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * (1 - progress));

    // Criar ondas
    for (double x = 0; x <= progressWidth; x += 1) {
      final normalizedX = x / size.width;
      final waveY = size.height * (1 - progress) + 
          waveHeight * math.sin(normalizedX * 4 * math.pi + wavePhase);
      path.lineTo(x, waveY);
    }

    path.lineTo(progressWidth, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.wavePhase != wavePhase ||
           oldDelegate.waveColor != waveColor;
  }
}