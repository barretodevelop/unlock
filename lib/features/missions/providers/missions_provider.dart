// lib/features/missions/providers/missions_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';
import 'package:unlock/features/missions/repositories/mission_repository.dart';
import 'package:unlock/features/rewards/services/rewards_service.dart';
import 'package:unlock/providers/auth_provider.dart'; // Importa o AuthProvider

/// Estado que o provedor MissionsNotifier irá gerenciar.
/// Contém a lista de missões disponíveis, o progresso do usuário em cada missão,
/// e o status de carregamento/erro.
class MissionsState {
  final List<Mission> availableMissions;
  // Correção: Inicializa userProgress com um mapa vazio do tipo correto
  final Map<String, UserMissionProgress> userProgress; // Chave: missionId
  final bool isLoading;
  final String? error;

  MissionsState({
    this.availableMissions = const [],
    // Garante que o mapa padrão seja do tipo correto
    Map<String, UserMissionProgress>? userProgress,
    this.isLoading = false,
    this.error,
  }) : userProgress =
           userProgress ??
           const {}; // Usa const {} para um mapa vazio e imutável do tipo inferido

  /// Permite criar uma nova instância de MissionsState com campos atualizados.
  MissionsState copyWith({
    List<Mission>? availableMissions,
    Map<String, UserMissionProgress>? userProgress, // Parameter type
    bool? isLoading,
    String? error,
  }) {
    return MissionsState(
      availableMissions: availableMissions ?? this.availableMissions,
      // Correção: Torna a cópia do mapa explícita para o tipo correto.
      // Se userProgress for nulo, cria um novo mapa a partir do existente.
      userProgress:
          userProgress ??
          Map<String, UserMissionProgress>.from(this.userProgress),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provedor principal para o sistema de missões.
///
/// Gerencia o estado das missões, o progresso do usuário e a lógica de conclusão/recompensa.
final missionsProvider = StateNotifierProvider<MissionsNotifier, MissionsState>((
  ref,
) {
  final userId = ref
      .watch(authProvider)
      .user
      ?.uid; // Obtém o ID do usuário logado

  // Se não há usuário logado, retorna um MissionsNotifier que não carregará dados
  // ou um estado de erro, dependendo da sua preferência para usuários não logados.
  if (userId == null) {
    print(
      'DEBUG: MissionsNotifier inicializado sem userId. Não carregará missões.',
    );
    return MissionsNotifier(ref, null);
  }
  return MissionsNotifier(ref, userId);
});

/// StateNotifier responsável por gerenciar o estado das missões.
class MissionsNotifier extends StateNotifier<MissionsState> {
  final Ref _ref;
  final String? _userId; // O ID do usuário logado (pode ser nulo se não logado)
  late final MissionRepository
  _missionRepository; // Repositório para acesso a dados
  late final RewardsService _rewardsService; // Serviço para aplicar recompensas

  MissionsNotifier(this._ref, this._userId) : super(MissionsState()) {
    _missionRepository = _ref.read(missionRepositoryProvider);
    _rewardsService = _ref.read(rewardsServiceProvider);

    // Carrega as missões e o progresso se houver um usuário logado
    if (_userId != null) {
      _fetchMissionsAndProgress();
    }
  }

  /// Carrega as missões ativas e o progresso do usuário a partir do repositório.
  Future<void> _fetchMissionsAndProgress() async {
    if (_userId == null) {
      state = state.copyWith(
        error: 'Usuário não autenticado para carregar missões.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final missions = await _missionRepository.getActiveMissions();
      // Correção: Garante que progressMap é do tipo correto desde o início
      final Map<String, UserMissionProgress> progressMap = {};

      // Para cada missão, busca o progresso do usuário.
      for (var mission in missions) {
        final progress = await _missionRepository.getMissionProgress(
          _userId!,
          mission.id,
        );
        progressMap[mission.id] = progress;

        // Lógica para resetar missões diárias automaticamente ao carregar, se necessário.
        // O ideal é que isso seja orquestrado pelo backend, mas aqui é uma simulação.
        if (mission.type == MissionType.DAILY) {
          final now = DateTime.now();
          if (progress.lastUpdateDate == null ||
              progress.lastUpdateDate!.day != now.day ||
              progress.lastUpdateDate!.month != now.month ||
              progress.lastUpdateDate!.year != now.year) {
            // Se a última atualização não foi hoje, reseta a missão.
            await _missionRepository.resetDailyMissionProgress(
              _userId!,
              mission.id,
            );
            // Rebusca o progresso para ter o estado resetado
            progressMap[mission.id] = await _missionRepository
                .getMissionProgress(_userId!, mission.id);
            print(
              'DEBUG: Missão diária ${mission.title} (${mission.id}) resetada no cliente.',
            );
          }
        }
      }
      state = state.copyWith(
        availableMissions: missions,
        userProgress: progressMap,
        isLoading: false,
      );
      print('DEBUG: Missões e progresso carregados com sucesso.');
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      print('ERRO: Erro ao carregar missões: $e');
    }
  }

  /// Reporta um evento de ação que pode afetar o progresso das missões.
  ///
  /// [eventType]: A string que identifica o tipo de evento (ex: 'LOGIN_DIARIO', 'LIKE_PROFILE').
  /// [details]: Um mapa opcional com detalhes adicionais do evento.
  Future<void> reportMissionEvent(
    String eventType, {
    Map<String, dynamic>? details,
  }) async {
    if (_userId == null) {
      print('INFO: Evento $eventType ignorado. Usuário não autenticado.');
      return;
    }

    // Correção: Garante que currentProgressMap é do tipo correto
    final currentProgressMap = Map<String, UserMissionProgress>.from(
      state.userProgress,
    );
    bool stateChanged = false;

    // Itera sobre as missões disponíveis para ver quais são afetadas pelo evento
    for (var mission in state.availableMissions) {
      if (mission.criterion.eventType == eventType) {
        final progress =
            currentProgressMap[mission.id] ??
            UserMissionProgress(userId: _userId!, missionId: mission.id);

        // Somente atualiza se a missão não estiver COMPLETA E não tiver sido RESGATADA
        if (!progress.isCompleted && !progress.isClaimed) {
          // Lógica específica para LOGIN_DIARIO para garantir que só conta uma vez por dia
          if (eventType == 'LOGIN_DAILY') {
            final now = DateTime.now();
            if (progress.lastUpdateDate == null ||
                progress.lastUpdateDate!.day != now.day ||
                progress.lastUpdateDate!.month != now.month ||
                progress.lastUpdateDate!.year != now.year) {
              progress.currentProgress = 1; // Login diário é 1 (concluído) ou 0
              progress.lastUpdateDate = now;
              stateChanged = true;
            } else {
              // Já logou hoje, não incrementa.
              continue; // Pula para a próxima missão
            }
          } else {
            progress.currentProgress++;
            stateChanged = true;
          }

          // Verifica se a missão foi concluída
          if (progress.currentProgress >= mission.criterion.targetCount) {
            if (!progress.isCompleted) {
              // Verifica se ainda não estava marcada como concluída
              progress.isCompleted = true;
              stateChanged = true;
              print('DEBUG: Missão "${mission.title}" concluída!');
            }
          }

          if (stateChanged) {
            currentProgressMap[mission.id] =
                progress; // Atualiza o progresso no mapa
            state = state.copyWith(
              userProgress: currentProgressMap,
            ); // Atualiza o estado
            await _missionRepository.updateMissionProgress(
              progress,
            ); // Persiste a mudança

            // Se a missão foi concluída, emite a recompensa (antes de ser resgatada)
            if (progress.isCompleted && !progress.isClaimed) {
              _rewardsService.emitReward(mission.reward);
              print('DEBUG: Recompensa da missão "${mission.title}" emitida.');
            }
          }
        }
      }
    }
  }

  /// Permite ao usuário resgatar as recompensas de uma missão concluída.
  ///
  /// [missionId]: O ID da missão cujas recompensas serão resgatadas.
  Future<void> claimMissionReward(String missionId) async {
    if (_userId == null) {
      print('INFO: Resgate de recompensa ignorado. Usuário não autenticado.');
      return;
    }

    final progress = state.userProgress[missionId];
    if (progress != null && progress.isCompleted && !progress.isClaimed) {
      // Marca a recompensa como resgatada
      progress.isClaimed = true;
      // Correção: Garante que newProgressMap é do tipo correto
      final newProgressMap = Map<String, UserMissionProgress>.from(
        state.userProgress,
      );
      newProgressMap[missionId] = progress;
      state = state.copyWith(userProgress: newProgressMap);
      await _missionRepository.updateMissionProgress(
        progress,
      ); // Persiste a mudança

      // Aplica a recompensa real ao UserModel do usuário usando o RewardsService
      final mission = state.availableMissions.firstWhere(
        (m) => m.id == missionId,
        orElse: () =>
            throw Exception('Missão com ID $missionId não encontrada.'),
      );
      // Chamada para o método `applyRewardToUser` do RewardsService
      await _rewardsService.applyRewardToUser(mission.reward, _userId!);
      print(
        'DEBUG: Recompensa de "${mission.title}" resgatada e aplicada ao usuário.',
      );
    } else if (progress != null && !progress.isCompleted) {
      print('INFO: Missão "${missionId}" ainda não concluída para resgate.');
    } else if (progress != null && progress.isClaimed) {
      print('INFO: Recompensa de "${missionId}" já foi resgatada.');
    } else {
      print(
        'ERRO: Progresso da missão "${missionId}" não encontrado para resgate.',
      );
    }
  }

  /// Reinicia o progresso de missões diárias para o dia atual.
  ///
  /// NOTA: Em um sistema de produção, o reset de missões diárias/semanais
  /// deve ser orquestrado e executado no backend (via cron jobs, por exemplo).
  /// Este método é uma simulação para fins de desenvolvimento no cliente,
  /// garantindo que as missões diárias fiquem disponíveis novamente.
  Future<void> resetDailyMissions() async {
    if (_userId == null) return;
    print('DEBUG: Tentando resetar missões diárias para o usuário ${_userId}');
    bool changed = false;
    for (var mission in state.availableMissions) {
      if (mission.type == MissionType.DAILY) {
        await _missionRepository.resetDailyMissionProgress(
          _userId!,
          mission.id,
        );
        changed = true;
      }
    }
    if (changed) {
      // Re-busca todas as missões e progresso para sincronizar o estado
      await _fetchMissionsAndProgress();
      print('DEBUG: Reset de missões diárias concluído e estado re-carregado.');
    }
  }

  Future<void> refresh() async {}
}
