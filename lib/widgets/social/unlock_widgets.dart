// lib/widgets/social/unlock_widgets.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/unlock_requirement.dart';

import '../../models/affinity_test_model.dart';
import '../../models/unlock_match_model.dart';
import '../animated/bounce_widget.dart';
import '../animated/fade_in_widget.dart';

/// Card de match com sistema de desbloqueio
class UnlockMatchCard extends StatelessWidget {
  final UnlockMatchModel match;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const UnlockMatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onLike,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BounceWidget(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background com gradiente misterioso
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.secondary.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Overlay com padrão de desbloqueio
              if (!match.isUnlocked) _buildLockOverlay(),

              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com status de desbloqueio
                    _buildHeader(theme),
                    const Spacer(),

                    // Info principal
                    _buildMainInfo(theme),
                    const SizedBox(height: 20),

                    // Interesses em comum
                    _buildCommonInterests(theme),
                    const SizedBox(height: 20),

                    // Barra de compatibilidade
                    _buildCompatibilityBar(theme),

                    if (!match.isUnlocked) ...[
                      const SizedBox(height: 20),
                      _buildUnlockButton(theme),
                    ],
                  ],
                ),
              ),

              // Botões de ação (se desbloqueado)
              if (match.isUnlocked) _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        child: const Center(
          child: Icon(Icons.lock_rounded, size: 60, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            match.isUnlocked ? 'DESBLOQUEADO' : 'BLOQUEADO',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getRequirementColor().withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getRequirementIcon(), color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildMainInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar misterioso
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            match.isUnlocked ? Icons.person_rounded : Icons.help_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Nome/codinome
        Text(
          match.isUnlocked ? match.targetUserCodinome : 'Mistério',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          match.isUnlocked
              ? 'Perfil desbloqueado'
              : 'Complete o teste para descobrir',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCommonInterests(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interesses em Comum',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: match.commonInterests.take(3).map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompatibilityBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compatibilidade',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${match.compatibilityScore.toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: match.compatibilityScore / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Fazer Teste de Afinidade',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          if (onPass != null) ...[
            Expanded(
              child: BounceWidget(
                onTap: onPass!,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (onLike != null) ...[
            Expanded(
              child: BounceWidget(
                onTap: onLike!,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRequirementColor() {
    switch (match.unlockRequirement) {
      case UnlockRequirement.easy:
        return Colors.green;
      case UnlockRequirement.medium:
        return Colors.orange;
      case UnlockRequirement.hard:
        return Colors.red;
    }
  }

  IconData _getRequirementIcon() {
    switch (match.unlockRequirement) {
      case UnlockRequirement.easy:
        return Icons.star_rounded;
      case UnlockRequirement.medium:
        return Icons.star_half_rounded;
      case UnlockRequirement.hard:
        return Icons.star_border_rounded;
    }
  }
}

/// Indicador de compatibilidade circular
class CompatibilityIndicator extends StatefulWidget {
  final double percentage;
  final double size;
  final Color? color;
  final bool animated;

  const CompatibilityIndicator({
    super.key,
    required this.percentage,
    this.size = 80,
    this.color,
    this.animated = true,
  });

  @override
  State<CompatibilityIndicator> createState() => _CompatibilityIndicatorState();
}

class _CompatibilityIndicatorState extends State<CompatibilityIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    if (widget.animated) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );

      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
          ),

          // Progress circle
          if (widget.animated)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            )
          else
            CircularProgressIndicator(
              value: widget.percentage / 100,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),

          // Percentage text
          Center(
            child: Text(
              '${widget.percentage.toInt()}%',
              style: TextStyle(
                fontSize: widget.size * 0.2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar interesses em comum
class CommonInterestsWidget extends StatelessWidget {
  final List<String> interests;
  final int maxVisible;
  final bool compact;

  const CommonInterestsWidget({
    super.key,
    required this.interests,
    this.maxVisible = 3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleInterests = interests.take(maxVisible).toList();
    final hasMore = interests.length > maxVisible;

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: compact ? 4 : 8,
      children: [
        ...visibleInterests.map((interest) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),

        if (hasMore)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
            ),
            child: Text(
              '+${interests.length - maxVisible}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget para exibir resultado do teste de afinidade
class AffinityResultWidget extends StatelessWidget {
  final AffinityTestResult result;
  final VoidCallback? onContinue;

  const AffinityResultWidget({
    super.key,
    required this.result,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de resultado
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: result.unlocked
                    ? [Colors.green, Colors.teal]
                    : [Colors.orange, Colors.red],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Text(
            result.unlocked ? 'Perfil Desbloqueado!' : 'Não foi desta vez...',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: result.unlocked ? Colors.green : Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Score
          Text(
            '${result.affinityScore.toInt()}% de afinidade',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown por categoria
          if (result.breakdown.isNotEmpty) ...[
            _buildBreakdown(result.breakdown, theme),
            const SizedBox(height: 20),
          ],

          // Botão de ação
          if (onContinue != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  result.unlocked ? 'Iniciar Conversa' : 'Tentar Novamente',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(Map<String, double> breakdown, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes da Afinidade:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...breakdown.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(entry.key, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${entry.value.toInt()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

/// Badge de status de desbloqueio
class UnlockBadge extends StatelessWidget {
  final bool isUnlocked;
  final UnlockRequirement requirement;
  final bool showText;

  const UnlockBadge({
    super.key,
    required this.isUnlocked,
    required this.requirement,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showText ? 12 : 8,
        vertical: showText ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(showText ? 20 : 12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: showText ? 16 : 20,
            color: _getStatusColor(),
          ),
          if (showText) ...[
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (isUnlocked) return Colors.green;

    switch (requirement) {
      case UnlockRequirement.easy:
        return Colors.blue;
      case UnlockRequirement.medium:
        return Colors.orange;
      case UnlockRequirement.hard:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (isUnlocked) return Icons.lock_open_rounded;

    switch (requirement) {
      case UnlockRequirement.easy:
        return Icons.star_rounded;
      case UnlockRequirement.medium:
        return Icons.star_half_rounded;
      case UnlockRequirement.hard:
        return Icons.whatshot_rounded;
    }
  }

  String _getStatusText() {
    if (isUnlocked) return 'DESBLOQUEADO';

    switch (requirement) {
      case UnlockRequirement.easy:
        return 'FÁCIL';
      case UnlockRequirement.medium:
        return 'MÉDIO';
      case UnlockRequirement.hard:
        return 'DIFÍCIL';
    }
  }
}
