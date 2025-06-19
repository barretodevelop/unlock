// lib/features/missions/screens/missions_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa o provedor de missões
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/mission_card.dart';
// Importa o MissionCard

/// Tela que exibe a lista de missões disponíveis para o usuário.
///
/// Esta tela observa o estado do `missionsProvider` para exibir missões,
/// seus respectivos progressos e status (carregando, erro, vazio).
class MissionsListScreen extends ConsumerWidget {
  const MissionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o estado do provedor de missões.
    final missionsState = ref.watch(missionsProvider);

    // Exibe um indicador de carregamento enquanto as missões estão sendo carregadas.
    if (missionsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Exibe uma mensagem de erro se houver algum problema ao carregar as missões.
    if (missionsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro ao carregar missões: ${missionsState.error}\nPor favor, tente novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    // Exibe uma mensagem se não houver missões disponíveis.
    if (missionsState.availableMissions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma missão disponível no momento.\nVolte em breve para novas aventuras!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Exibe a lista de missões usando um ListView.builder para eficiência.
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: missionsState.availableMissions.length,
      itemBuilder: (context, index) {
        final mission = missionsState.availableMissions[index];
        // Obtém o progresso específico do usuário para a missão atual.
        final progress = missionsState.userProgress[mission.id];

        // Retorna um MissionCard para cada missão na lista.
        return MissionCard(mission: mission, progress: progress);
      },
    );
  }
}
