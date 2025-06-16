// lib/screens/social/unlock_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:unlock/widgets/animated/fade_in_widget.dart';

import '../../models/unlock_match_model.dart';
import '../../widgets/animated/scale_in_widget.dart';

class UnlockResultScreen extends ConsumerStatefulWidget {
  final UnlockMatchModel match;
  final bool wasSuccessful;

  const UnlockResultScreen({
    super.key,
    required this.match,
    required this.wasSuccessful,
  });

  @override
  ConsumerState<UnlockResultScreen> createState() => _UnlockResultScreenState();
}

class _UnlockResultScreenState extends ConsumerState<UnlockResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scoreAnimation =
        Tween<double>(begin: 0, end: widget.match.compatibilityScore).animate(
          CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
        );

    if (widget.wasSuccessful) {
      _confettiController.forward();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: widget.wasSuccessful
          ? const Color(0xFF0D1B2A)
          : theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildResultAnimation(),
              const SizedBox(height: 32),
              _buildScoreSection(),
              const SizedBox(height: 32),
              _buildCompatibilityDetails(),
              const Spacer(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.close,
            color: widget.wasSuccessful ? Colors.white : null,
          ),
        ),
        const Spacer(),
        Text(
          widget.wasSuccessful ? 'DESBLOQUEADO!' : 'BLOQUEADO',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: widget.wasSuccessful
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildResultAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confete (apenas no sucesso)
        if (widget.wasSuccessful)
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/confetti.json',
              controller: _confettiController,
              fit: BoxFit.cover,
            ),
          ),

        // Ícone principal
        ScaleInWidget(
          duration: const Duration(milliseconds: 800),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.wasSuccessful
                  ? const LinearGradient(
                      colors: [Color(0xFF00F5FF), Color(0xFF0080FF)],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade600],
                    ),
              boxShadow: [
                BoxShadow(
                  color: widget.wasSuccessful
                      ? Colors.cyan.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              widget.wasSuccessful ? Icons.lock_open : Icons.lock,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Text(
            'Compatibilidade',
            style: TextStyle(
              fontSize: 16,
              color: widget.wasSuccessful
                  ? Colors.white70
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Container(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: CircularProgressPainter(
                    progress: _scoreAnimation.value / 100,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    progressColor: widget.wasSuccessful
                        ? Colors.cyan
                        : Colors.orange,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_scoreAnimation.value.toInt()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: widget.wasSuccessful
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _getScoreDescription(),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.wasSuccessful
                                ? Colors.white70
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityDetails() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.wasSuccessful
              ? Colors.white.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.wasSuccessful
                ? Colors.cyan.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes da Afinidade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.wasSuccessful
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              'Interesses em comum',
              '${widget.match.commonInterests.length}',
              Icons.favorite,
            ),

            _buildDetailRow(
              'Respostas similares',
              '${widget.match.affinityScore}%',
              Icons.psychology,
            ),

            _buildDetailRow(
              'Tipo de relacionamento',
              widget.match.relationshipCompatibility,
              Icons.people,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: widget.wasSuccessful
                ? Colors.cyan
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: widget.wasSuccessful
                    ? Colors.white70
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.wasSuccessful
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.wasSuccessful) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Iniciar Conversa',
              onPressed: () {
                context.pushReplacementNamed(
                  'chat',
                  extra: {'connectionId': widget.match.targetUserId},
                );
              },
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5FF), Color(0xFF0080FF)],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.cyan),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Ver Perfil Completo',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Tentar Novamente',
              onPressed: () => context.pop(),
              backgroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ),
        ],
      ],
    );
  }

  String _getScoreDescription() {
    final score = widget.match.compatibilityScore;
    if (score >= 80) return 'Perfeito!';
    if (score >= 70) return 'Excelente';
    if (score >= 60) return 'Muito Bom';
    if (score >= 50) return 'Bom';
    return 'Baixo';
  }
}

// Custom painter para o círculo de progresso
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top
      2 * 3.14159 * progress, // Progress angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
