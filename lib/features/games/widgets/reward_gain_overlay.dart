// lib/features/games/widgets/reward_gain_overlay.dart

import 'package:flutter/material.dart';
import 'package:unlock/core/utils/level_calculator.dart';
import 'package:unlock/features/games/widgets/reward_animation_controller.dart';

/// Um widget de overlay que exibe uma animação de ganho de recompensa
/// sobre um widget filho.
class RewardGainOverlay extends StatefulWidget {
  final Widget child;
  final RewardAnimationController controller;

  const RewardGainOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<RewardGainOverlay> createState() => _RewardGainOverlayState();
}

class _RewardGainOverlayState extends State<RewardGainOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showRewardAnimation = false;
  RewardAnimationValues _values = RewardAnimationValues();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, -2.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.3,
      ),
    ]).animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _showRewardAnimation = false);
        }
      }
    });

    // Registra o método de disparo no controlador
    widget.controller.register(_triggerAnimation);
  }

  void _triggerAnimation(RewardAnimationValues values) {
    if (mounted) {
      setState(() {
        _values = values;
        _showRewardAnimation = true;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showRewardAnimation)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: _RewardGainAnimationWidget(
                values: _values,
                slideAnimation: _slideAnimation,
                fadeAnimation: _fadeAnimation,
              ),
            ),
          ),
      ],
    );
  }
}

/// O widget visual da animação de recompensa.
class _RewardGainAnimationWidget extends StatelessWidget {
  final RewardAnimationValues values;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const _RewardGainAnimationWidget({
    required this.values,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final rewardsToShow = <Widget>[];
    if (values.xp > 0) {
      rewardsToShow.add(
        _buildRewardChip(
          icon: Icons.trending_up,
          text: '+${LevelCalculator.formatXP(values.xp)} XP',
        ),
      );
    }
    if (values.coins > 0) {
      rewardsToShow.add(
        _buildRewardChip(
          icon: Icons.monetization_on,
          text: '+${LevelCalculator.formatXP(values.coins)} Moedas',
        ),
      );
    }
    if (values.gems > 0) {
      rewardsToShow.add(
        _buildRewardChip(
          icon: Icons.diamond,
          text: '+${LevelCalculator.formatXP(values.gems)} Gemas',
        ),
      );
    }

    if (rewardsToShow.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: rewardsToShow,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
