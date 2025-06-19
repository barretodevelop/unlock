// lib/features/missions/providers/missions_notifier.dart

import 'dart:async'; // Importar Completer

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/models/user_mission_progress.dart';
import 'package:unlock/features/missions/repositories/mission_repository.dart';
import 'package:unlock/features/rewards/providers/rewards_provider.dart';
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
  final Completer<void> _initialLoadCompleter =
      Completer<void>(); // Para sincronização

  MissionsNotifier(this._ref, this._userId) : super(MissionsState()) {
    _missionRepository = _ref.read(missionRepositoryProvider);
    _rewardsService = _ref.read(rewardsServiceProvider);

    // Carrega as missões e o progresso se houver um usuário logado
    if (_userId != null) {
      _loadData();
    } else {
      // Se não há usuário, o carregamento inicial é considerado completo (não há o que carregar).
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }
  }

  /// Carrega as missões ativas e o progresso do usuário a partir do repositório.
  Future<void> _loadData() async {
    // Usar o userId mais recente do AuthProvider, embora _userId deva estar correto aqui
    // devido à recriação do notifier quando authProvider muda.
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;

    if (currentUserId == null) {
      state = state.copyWith(
        error: 'Usuário não autenticado para carregar missões.',
        isLoading: false, // Garante que isLoading seja false
      );
      if (!_initialLoadCompleter.isCompleted) _initialLoadCompleter.complete();
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
          currentUserId,
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
              currentUserId,
              mission.id,
            );
            // Rebusca o progresso para ter o estado resetado
            progressMap[mission.id] = await _missionRepository
                .getMissionProgress(currentUserId, mission.id);
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
    } catch (e, stackTrace) {
      // Adicionar stackTrace para melhor debugging
      state = state.copyWith(error: e.toString(), isLoading: false);
      AppLogger.error(
        'ERRO: Erro ao carregar missões',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Garante que o completer seja finalizado mesmo em caso de erro.
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
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
    // Espera o carregamento inicial ter sido concluído
    await _initialLoadCompleter.future;

    // Obter o userId mais atualizado do AuthProvider no momento da chamada.
    final currentUserId = _ref.read(authProvider).user?.uid;
    AppLogger.debug(
      'MissionsNotifier.reportMissionEvent para eventType: $eventType. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
    );

    if (currentUserId == null) {
      AppLogger.info(
        'Evento $eventType ignorado. Usuário não autenticado (currentUserId é nulo).',
      );
      return;
    }

    // Garante que currentProgressMap seja uma nova instância baseada no estado atual.
    final currentProgressMap = Map<String, UserMissionProgress>.from(
      state.userProgress,
    );
    bool stateChanged = false;

    // Itera sobre as missões disponíveis para ver quais são afetadas pelo evento
    for (var mission in state.availableMissions) {
      if (mission.criterion.eventType == eventType) {
        // Usa currentUserId para buscar ou criar o progresso.
        UserMissionProgress progress =
            currentProgressMap[mission.id] ??
            UserMissionProgress(userId: currentUserId, missionId: mission.id);

        // Garante que o progresso tenha o userId mais atualizado.
        if (progress.userId != currentUserId) {
          progress = progress.copyWith(userId: currentUserId);
        }

        // Somente atualiza se a missão não estiver COMPLETA E não tiver sido RESGATADA
        if (!progress.isCompleted && !progress.isClaimed) {
          // Lógica específica para LOGIN_DIARIO para garantir que só conta uma vez por dia
          if (eventType == 'LOGIN_DAILY') {
            final now = DateTime.now();
            if (progress.lastUpdateDate == null ||
                progress.lastUpdateDate!.day != now.day ||
                progress.lastUpdateDate!.month != now.month ||
                progress.lastUpdateDate!.year != now.year) {
              // Cria uma nova instância de progress com os campos atualizados
              progress = progress.copyWith(
                currentProgress: 1,
                lastUpdateDate: now,
              );
              stateChanged = true;
            } else {
              // Já logou hoje, não incrementa.
              AppLogger.debug(
                'Evento LOGIN_DAILY já processado hoje para missão ${mission.id}. Nenhuma alteração no progresso.',
              );
              continue;
            }
          } else {
            // Cria uma nova instância de progress com currentProgress incrementado
            progress = progress.copyWith(
              currentProgress: progress.currentProgress + 1,
            );
            stateChanged = true;
          }

          // Verifica se a missão foi concluída
          final bool wasCompletedBefore = progress.isCompleted;
          if (progress.currentProgress >= mission.criterion.targetCount) {
            // Cria uma nova instância de progress com isCompleted = true, se ainda não estiver
            if (!progress.isCompleted) {
              progress = progress.copyWith(isCompleted: true);
            }
          }

          // Se o estado de 'isCompleted' mudou para true, marca stateChanged.
          if (progress.isCompleted && !wasCompletedBefore) {
            stateChanged = true;
            AppLogger.debug(
              'Missão "${mission.title}" (${mission.id}) AGORA está completa! Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
            );
          } else if (progress.isCompleted) {
            AppLogger.debug(
              'Missão "${mission.title}" (${mission.id}) já estava completa ou continua completa. Progresso: ${progress.currentProgress}/${mission.criterion.targetCount}',
            );
          }

          if (stateChanged) {
            currentProgressMap[mission.id] =
                progress; // Atualiza o progresso no mapa local
            // A atualização do estado global (state.copyWith) será feita uma vez após o loop se houver mudanças.

            await _missionRepository.updateMissionProgress(
              progress,
            ); // Persiste a mudança
            AppLogger.debug(
              'Progresso da missão ${mission.id} atualizado no repositório: ${progress.toString()}',
            );

            // Se a missão foi concluída, emite a recompensa (antes de ser resgatada)
            if (progress.isCompleted && !progress.isClaimed) {
              final user = _ref.read(authProvider).user;
              if (user != null && user.uid == currentUserId) {
                await _ref
                    .read(rewardsProvider.notifier)
                    .grantMissionRewards(mission, user);
                AppLogger.debug(
                  'Recompensa da missão "${mission.title}" registrada como pendente.',
                );
              } else {
                AppLogger.error(
                  'Usuário nulo ou ID divergente ao tentar conceder recompensa da missão ${mission.title}. User from Auth: ${user?.uid}, currentUserId for mission: $currentUserId',
                );
              }
            }
          }
        }
      }
    }
    // Após o loop, se houve alguma mudança, atualiza o estado uma vez.
    if (stateChanged) {
      state = state.copyWith(
        userProgress: Map<String, UserMissionProgress>.from(currentProgressMap),
      );
      AppLogger.debug(
        'Estado do MissionsNotifier atualizado com novo progresso global.',
      );
    }
  }

  /// Permite ao usuário resgatar as recompensas de uma missão concluída.
  ///
  /// [missionId]: O ID da missão cujas recompensas serão resgatadas.
  Future<void> claimMissionReward(String missionId) async {
    // Usar o userId atual do AuthProvider
    final currentUserId = _ref.read(authProvider).user?.uid;
    AppLogger.debug(
      'MissionsNotifier.claimMissionReward para missionId: $missionId. _userId (do construtor): $_userId, currentUserId (lido agora): $currentUserId',
    );

    if (currentUserId == null) {
      AppLogger.info(
        'Resgate de recompensa ignorado para $missionId. Usuário não autenticado (lido dinamicamente).',
      );
      return;
    }

    final progress = state.userProgress[missionId];
    if (progress != null && progress.isCompleted && !progress.isClaimed) {
      // Marca a recompensa como resgatada
      // Cria uma nova instância de progress com isClaimed = true
      final updatedProgress = progress.copyWith(isClaimed: true);
      // Garante que newProgressMap seja uma nova instância do mapa
      final newProgressMap = Map<String, UserMissionProgress>.from(
        state.userProgress,
      );
      newProgressMap[missionId] = updatedProgress; // Usa a instância atualizada
      state = state.copyWith(userProgress: newProgressMap);
      await _missionRepository.updateMissionProgress(
        updatedProgress, // Persiste a instância atualizada
      ); // Persiste a mudança

      // Aplica a recompensa real ao UserModel do usuário usando o RewardsService
      final mission = state.availableMissions.firstWhere(
        (m) => m.id == missionId,
        orElse: () =>
            throw Exception('Missão com ID $missionId não encontrada.'),
      );
      // Chamada para o método `applyRewardToUser` do RewardsService
      await _rewardsService.applyRewardToUser(
        mission.reward,
        currentUserId,
      ); // Usa currentUserId
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
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
    if (currentUserId == null) return;
    AppLogger.debug(
      'Tentando resetar missões diárias para o usuário $currentUserId',
    );
    bool changed = false;
    for (var mission in state.availableMissions) {
      if (mission.type == MissionType.DAILY) {
        await _missionRepository.resetDailyMissionProgress(
          currentUserId,
          mission.id,
        );
        changed = true;
      }
    }
    if (changed) {
      // Re-busca todas as missões e progresso para sincronizar o estado
      await _loadData();
      AppLogger.debug(
        'Reset de missões diárias concluído e estado re-carregado.',
      );
    }
  }

  Future<void> refresh() async {
    AppLogger.debug('MissionsNotifier.refresh() chamado.');
    final currentUserId = _userId ?? _ref.read(authProvider).user?.uid;
    if (currentUserId != null) {
      await _loadData(); // Chama _loadData em vez de _fetchMissionsAndProgress diretamente
    } else {
      AppLogger.debug(
        'MissionsNotifier.refresh() ignorado, currentUserId é nulo.',
      );
    }
  }
}
