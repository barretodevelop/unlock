// lib/features/home/widgets/voting_home_integration.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/voting/widgets/voting_notification_widgets.dart';
import 'package:unlock/features/voting/widgets/voting_widgets.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/voting_integration_provider.dart';

// ========== VOTING QUICK ACCESS WIDGET ==========

/// Widget de acesso rápido às funcionalidades de votação na home
class VotingQuickAccessWidget extends ConsumerWidget {
  const VotingQuickAccessWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final hasVotingChallenges = ref.watch(userHasVotingChallengesProvider);
    final notificationsCount = ref.watch(votingNotificationsCountProvider);

    if (user == null || !hasVotingChallenges) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/voting'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone com badge de notificações
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.how_to_vote,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    if (notificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              notificationsCount > 9
                                  ? '9+'
                                  : notificationsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votações Ativas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificationsCount == 1
                            ? 'Você tem 1 desafio em votação'
                            : 'Você tem $notificationsCount desafios em votação',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Seta
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== VOTING CHALLENGES CAROUSEL ==========

/// Carrossel de desafios em votação para a home
class VotingChallengesCarousel extends ConsumerWidget {
  const VotingChallengesCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votingChallengesAsync = ref.watch(votingChallengesProvider);

    return votingChallengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da seção
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.how_to_vote,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Em Votação Agora',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${challenges.length} ${challenges.length == 1 ? 'desafio' : 'desafios'} aguardando seus votos',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/voting'),
                    child: const Text('Ver Todos'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Carrossel
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < challenges.length - 1 ? 12 : 0,
                    ),
                    child: VotingChallengeCard(challenge: challenge),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingCarousel(context),
      error: (error, stack) => _buildErrorWidget(context, ref),
    );
  }

  Widget _buildLoadingCarousel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Erro ao carregar desafios em votação',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => ref.refresh(votingChallengesProvider),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}

// ========== VOTING CHALLENGE CARD ==========

/// Card individual para desafio em votação
class VotingChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const VotingChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(
      challengeStatisticsProvider(challenge.id),
    );

    return Container(
      width: 280,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/voting/${challenge.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      challenge.type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Descrição
                Text(
                  challenge.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Timer de votação
                if (challenge.votingConfig != null)
                  VotingTimer(
                    votingConfig: challenge.votingConfig!,
                    isCompact: true,
                  ),

                const SizedBox(height: 8),

                // Estatísticas
                statisticsAsync.when(
                  data: (stats) => _buildStatistics(context, stats),
                  loading: () => _buildLoadingStats(context),
                  error: (error, stack) => _buildErrorStats(context),
                ),

                const SizedBox(height: 8),

                // Botão de ação
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/voting/${challenge.id}'),
                    icon: const Icon(Icons.how_to_vote, size: 18),
                    label: const Text('Votar Agora'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, Map<String, dynamic> stats) {
    final totalSubmissions = stats['totalSubmissions'] ?? 0;
    final totalVotes = stats['totalVotes'] ?? 0;

    return Row(
      children: [
        _buildStatChip(
          context,
          totalSubmissions.toString(),
          'submissões',
          Icons.file_present,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          totalVotes.toString(),
          'votos',
          Icons.how_to_vote,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStats(BuildContext context) {
    return Text(
      'Erro ao carregar estatísticas',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ========== UPCOMING VOTING BANNER ==========

/// Banner para desafios prestes a entrar em votação
class UpcomingVotingBanner extends ConsumerWidget {
  const UpcomingVotingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingChallengesAsync = ref.watch(upcomingVotingChallengesProvider);
    final user = ref.watch(authProvider.select((state) => state.user));

    if (user == null) return const SizedBox.shrink();

    return upcomingChallengesAsync.when(
      data: (challenges) {
        final userChallenges = challenges
            .where(
              (challenge) =>
                  challenge.creatorId == user.uid ||
                  challenge.participants.contains(user.uid),
            )
            .toList();

        if (userChallenges.isEmpty) return const SizedBox.shrink();

        // Mostrar o próximo desafio
        final nextChallenge = userChallenges.first;

        return VotingBanner(
          challenge: nextChallenge,
          onTap: () => context.push('/challenges/${nextChallenge.id}'),
          canDismiss: true,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

// ========== INTEGRATION HELPER ==========

/// Helper para integrar funcionalidades de votação na home
class VotingHomeIntegration {
  VotingHomeIntegration._();

  /// Verificar se deve mostrar seção de votação na home
  static bool shouldShowVotingSection(WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    if (user == null || !user.onboardingCompleted) return false;

    final hasVotingChallenges = ref.watch(userHasVotingChallengesProvider);
    return hasVotingChallenges;
  }

  /// Obter widgets de votação para integrar na home
  static List<Widget> getVotingWidgetsForHome(BuildContext context) {
    return [
      const UpcomingVotingBanner(),
      const SizedBox(height: 8),
      const VotingQuickAccessWidget(),
      const SizedBox(height: 16),
      const VotingChallengesCarousel(),
      const SizedBox(height: 24),
    ];
  }

  /// Configurar listeners para notificações de votação
  static void setupVotingNotifications(WidgetRef ref) {
    // Listener para mudanças no estado de votação
    ref.listen(votingMonitorProvider, (previous, next) {
      if (previous?.isActive != next.isActive) {
        AppLogger.info(
          next.isActive
              ? '🤖 Monitoramento de votação iniciado'
              : '🛑 Monitoramento de votação parado',
        );
      }
    });

    // Listener para novas notificações
    ref.listen(votingNotificationsCountProvider, (previous, next) {
      if (previous != null && next > previous) {
        AppLogger.info('🔔 Nova notificação de votação: $next total');
      }
    });
  }

  /// Inicializar sistema de votação na home
  static void initializeVotingSystem(WidgetRef ref) {
    // Aguardar um frame para garantir que a UI está pronta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar se usuário está autenticado
      final user = ref.read(authProvider.select((state) => state.user));
      if (user != null) {
        // Inicializar sistema
        ref.read(votingSystemInitProvider);

        // Configurar notificações
        setupVotingNotifications(ref);

        AppLogger.info('🏠 Sistema de votação integrado à home screen');
      }
    });
  }
}
