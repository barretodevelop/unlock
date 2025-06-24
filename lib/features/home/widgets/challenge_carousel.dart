// lib/features/home/widgets/challenge_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/providers/challenge_provider.dart';

class ChallengeCarousel extends ConsumerWidget {
  const ChallengeCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return challengesAsync.when(
      data: (challenges) => _buildCarousel(context, challenges),
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context),
    );
  }

  /// Construir carrossel
  Widget _buildCarousel(BuildContext context, List<Challenge> challenges) {
    if (challenges.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == challenges.length - 1 ? 16 : 12,
              left: index == 0 ? 0 : 0,
            ),
            child: _buildChallengeCard(context, challenge),
          );
        },
      ),
    );
  }

  /// Construir card do desafio
  Widget _buildChallengeCard(BuildContext context, Challenge challenge) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getChallengeColor(challenge.type),
            _getChallengeColor(challenge.type).withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getChallengeColor(challenge.type).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToChallenge(context, challenge.id),
          child: Padding(
            padding: const EdgeInsets.all(14), // ✅ REDUZIDO MAIS: de 16 para 14
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ ADICIONADO: Tamanho mínimo
              children: [
                _buildChallengeHeader(context, challenge),
                const SizedBox(height: 6), // ✅ REDUZIDO MAIS: de 8 para 6
                Flexible(
                  flex: 2,
                  child: _buildChallengeInfo(context, challenge),
                ),
                const SizedBox(height: 6), // ✅ REDUZIDO MAIS: de 8 para 6
                _buildChallengeFooter(context, challenge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cabeçalho do card
  Widget _buildChallengeHeader(BuildContext context, Challenge challenge) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6), // ✅ REDUZIDO: de 8 para 6
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            challenge.type.icon,
            style: const TextStyle(fontSize: 18), // ✅ REDUZIDO: de 20 para 18
          ),
        ),
        const SizedBox(width: 10), // ✅ REDUZIDO: de 12 para 10
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ ADICIONADO: Tamanho mínimo
            children: [
              Text(
                challenge.type.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                challenge.arena.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ), // ✅ REDUZIDO
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${challenge.participants.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Informações do desafio
  Widget _buildChallengeInfo(BuildContext context, Challenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          challenge.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (challenge.description.isNotEmpty) ...[
          const SizedBox(height: 3), // ✅ REDUZIDO MAIS: de 4 para 3
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Rodapé do card
  Widget _buildChallengeFooter(BuildContext context, Challenge challenge) {
    final timeLeft = challenge.timeLeft;
    final isAboutToEnd = timeLeft.inHours < 24;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ ADICIONADO: Tamanho mínimo
            children: [
              Text(
                'Termina em',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 1), // ✅ REDUZIDO: de 2 para 1
              Row(
                children: [
                  Icon(
                    isAboutToEnd ? Icons.warning : Icons.schedule,
                    size: 12, // ✅ REDUZIDO: de 14 para 12
                    color: isAboutToEnd ? Colors.amber : Colors.white,
                  ),
                  const SizedBox(width: 3), // ✅ REDUZIDO: de 4 para 3
                  Flexible(
                    // ✅ ADICIONADO: Flexible para evitar overflow
                    child: Text(
                      _formatTimeLeft(timeLeft),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isAboutToEnd ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ), // ✅ REDUZIDO
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Participar',
            style: TextStyle(
              color: _getChallengeColor(challenge.type),
              fontWeight: FontWeight.w600,
              fontSize: 11, // ✅ REDUZIDO: de 12 para 11
            ),
          ),
        ),
      ],
    );
  }

  /// Estado vazio
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16), // ✅ REDUZIDO MAIS: de 20 para 16
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          // ✅ ADICIONADO: ScrollView para evitar overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 36, // ✅ REDUZIDO MAIS: de 40 para 36
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 6), // ✅ REDUZIDO MAIS: de 8 para 6
              Text(
                'Nenhum Desafio Ativo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3), // ✅ REDUZIDO MAIS: de 4 para 3
              Text(
                'Seja o primeiro a criar!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // ✅ REDUZIDO MAIS: de 12 para 8
              ElevatedButton.icon(
                onPressed: () => context.push('/challenges/create'),
                icon: const Icon(
                  Icons.add,
                  size: 14,
                ), // ✅ REDUZIDO: de 16 para 14
                label: const Text('Criar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // ✅ REDUZIDO: de 16 para 12
                    vertical: 4, // ✅ REDUZIDO: de 6 para 4
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado de carregamento
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Estado de erro
  Widget _buildErrorState(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16), // ✅ REDUZIDO MAIS: de 20 para 16
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          // ✅ ADICIONADO: ScrollView para evitar overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 28, // ✅ REDUZIDO MAIS: de 32 para 28
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 6), // ✅ REDUZIDO MAIS: de 8 para 6
              Text(
                'Erro ao carregar desafios',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Obter cor do desafio por tipo
  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.creative:
        return Colors.purple;
      case ChallengeType.performance:
        return Colors.orange;
      case ChallengeType.knowledge:
        return Colors.blue;
      case ChallengeType.realWorld:
        return Colors.green;
    }
  }

  /// Formatar tempo restante
  String _formatTimeLeft(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Quase terminando!';
    }
  }

  /// Navegar para desafio
  void _navigateToChallenge(BuildContext context, String challengeId) {
    AppLogger.navigation('📍 Navegando para desafio: $challengeId');
    context.push('/challenges/$challengeId');
  }
}
