// lib/features/missions/widgets/mission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart'; // Para cores customizadas

/// Um widget [Card] que exibe os detalhes de uma missão e seu progresso.
///
/// Permite ao usuário visualizar o título, descrição, progresso e recompensas
/// de uma missão, além de um botão para resgatar a recompensa quando concluída.
class MissionCard extends ConsumerWidget {
  final Mission mission;
  final UserMissionProgress? progress; // Progresso do usuário para esta missão

  const MissionCard({super.key, required this.mission, this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtém o progresso atual, status de completude e resgate da missão.
    final isCompleted = progress?.isCompleted ?? false;
    final isClaimed = progress?.isClaimed ?? false;
    final currentProgress = progress?.currentProgress ?? 0;

    // Calcula o valor da barra de progresso (entre 0.0 e 1.0).
    // Evita divisão por zero e garante que o valor esteja entre 0 e 1.
    final progressValue = mission.criterion.targetCount == 0
        ? 1.0
        : (currentProgress / mission.criterion.targetCount).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título da Missão
                Expanded(
                  // Usado Expanded para evitar overflow de texto longo
                  child: Text(
                    mission.title, // mission.title é String não-nula
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      // Altera a cor do título se a missão já foi resgatada.
                      color: isClaimed
                          ? Colors.grey
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Adicionado para lidar com texto muito longo
                  ),
                ),
                const SizedBox(
                  width: 8,
                ), // Espaçamento entre o título e os ícones de status
                // Ícone de status da Missão (concluída mas não resgatada, ou já resgatada)
                if (isCompleted && !isClaimed)
                  Icon(Icons.check_circle, color: AppTheme.successColor),
                if (isClaimed) Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 8),
            // Descrição da Missão
            Text(
              mission.description, // mission.description é String não-nula
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                // Altera a cor da descrição se a missão já foi resgatada.
                color: isClaimed
                    ? Colors.grey
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Barra de Progresso da Missão
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            // Texto de Progresso
            Text(
              'Progresso: ${currentProgress.toString()} / ${mission.criterion.targetCount.toString()}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Recompensas e Botão de Resgate
            Row(
              children: [
                // Chips para exibir as recompensas da missão (XP, Coins, Gems)
                if (mission.reward.xp > 0)
                  _buildRewardChip(
                    'XP: ${mission.reward.xp.toString()}',
                    Colors.purple,
                  ),
                if (mission.reward.coins > 0)
                  _buildRewardChip(
                    'Coins: ${mission.reward.coins.toString()}',
                    Colors.amber,
                  ),
                if (mission.reward.gems > 0)
                  _buildRewardChip(
                    'Gems: ${mission.reward.gems.toString()}',
                    Colors.lightBlue,
                  ),

                const Spacer(), // Empurra o botão para a direita
                // Botão de Resgatar Recompensa ou status da missão
                ...(isCompleted && !isClaimed)
                    ? [
                        // Se concluída e não resgatada, mostra o botão Resgatar
                        ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(missionsProvider.notifier)
                                .claimMissionReward(mission.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Recompensa de "${mission.title}" resgatada!',
                                ),
                                backgroundColor:
                                    AppTheme.successColor, // Cor de sucesso
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Resgatar'),
                        ),
                      ]
                    : (isClaimed)
                    ? [
                        // Se já resgatada, mostra texto "Resgatado"
                        Text(
                          'Resgatado',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ]
                    : [
                        // Se não concluída, mostra texto "Não concluída"
                        Text(
                          'Não concluída',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um Chip para exibir uma recompensa (ex: XP, Coins, Gems).
  Widget _buildRewardChip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
        padding: EdgeInsets.zero, // Remover padding extra do Chip
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, // Reduzir tamanho de toque
        labelPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
      ),
    );
  }
}
