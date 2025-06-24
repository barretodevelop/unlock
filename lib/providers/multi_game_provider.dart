// lib/providers/multi_game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/multi_game_service.dart';

/// Provider para o MultiGameService
final multiGameServiceProvider = Provider<MultiGameService>((ref) {
  return MultiGameService();
});

/// Provider para stream de jogos ativos do usuário
final activeGamesProvider = StreamProvider<List<GameRoomModel>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  final multiGameService = ref.watch(multiGameServiceProvider);
  return multiGameService.getActiveGamesStream(userId);
});

/// Provider para contar jogos ativos
final activeGamesCountProvider = FutureProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) return Future.value(0);

  final multiGameService = ref.watch(multiGameServiceProvider);
  return multiGameService.getActiveGamesCount(userId);
});

/// Provider para verificar se pode criar novo jogo
final canCreateGameProvider = FutureProvider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) return Future.value(false);

  final multiGameService = ref.watch(multiGameServiceProvider);
  return multiGameService.canCreateNewGame(userId);
});

/// Provider para estatísticas de jogos
final gameStatsProvider = FutureProvider<MultiGameStats>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) return Future.value(MultiGameStats.empty());

  final multiGameService = ref.watch(multiGameServiceProvider);
  return multiGameService.getUserGameStats(userId);
});

/// Provider para jogos por status
final gamesByStatusProvider =
    FutureProvider.family<List<GameRoomModel>, List<GameStatus>>((
      ref,
      statuses,
    ) {
      final authState = ref.watch(authProvider);
      final userId = authState.user?.uid;

      if (userId == null) return Future.value([]);

      final multiGameService = ref.watch(multiGameServiceProvider);
      return multiGameService.getGamesByStatus(userId, statuses);
    });

/// Notifier para gerenciar ações de múltiplos jogos
final multiGameNotifierProvider =
    StateNotifierProvider<MultiGameNotifier, MultiGameState>((ref) {
      final authState = ref.watch(authProvider);
      final multiGameService = ref.watch(multiGameServiceProvider);

      return MultiGameNotifier(
        multiGameService: multiGameService,
        userId: authState.user?.uid,
        ref: ref,
      );
    });

/// Estado dos múltiplos jogos
class MultiGameState {
  final bool isLoading;
  final String? error;
  final String? selectedGameId;
  final bool isCreatingGame;

  const MultiGameState({
    this.isLoading = false,
    this.error,
    this.selectedGameId,
    this.isCreatingGame = false,
  });

  MultiGameState copyWith({
    bool? isLoading,
    String? error,
    String? selectedGameId,
    bool? isCreatingGame,
  }) {
    return MultiGameState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedGameId: selectedGameId ?? this.selectedGameId,
      isCreatingGame: isCreatingGame ?? this.isCreatingGame,
    );
  }
}

/// Notifier para ações de múltiplos jogos
class MultiGameNotifier extends StateNotifier<MultiGameState> {
  final MultiGameService _multiGameService;
  final String? _userId;
  final Ref _ref;

  MultiGameNotifier({
    required MultiGameService multiGameService,
    required String? userId,
    required Ref ref,
  }) : _multiGameService = multiGameService,
       _userId = userId,
       _ref = ref,
       super(const MultiGameState());

  /// Cria um novo jogo
  Future<String?> createGame(String inviteeId) async {
    if (_userId == null) {
      state = state.copyWith(error: 'Usuário não autenticado');
      return null;
    }

    try {
      state = state.copyWith(isCreatingGame: true, error: null);

      final gameId = await _multiGameService.sendGameInvite(
        inviterId: _userId!,
        inviteeId: inviteeId,
      );

      if (gameId != null) {
        state = state.copyWith(isCreatingGame: false, selectedGameId: gameId);

        AppLogger.info(
          '✅ Novo jogo criado via MultiGameNotifier',
          data: {'gameId': gameId, 'invitee': inviteeId},
        );

        // Refresh da lista de jogos ativos
        _ref.invalidate(activeGamesProvider);
      } else {
        state = state.copyWith(
          isCreatingGame: false,
          error: 'Falha ao criar o jogo',
        );
      }

      return gameId;
    } catch (e) {
      String errorMessage;

      if (e is GameLimitException) {
        errorMessage = e.message;
      } else if (e is GameAlreadyExistsException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Erro inesperado ao criar jogo';
      }

      state = state.copyWith(isCreatingGame: false, error: errorMessage);

      AppLogger.error('❌ Erro ao criar jogo via MultiGameNotifier', error: e);
      return null;
    }
  }

  /// Seleciona um jogo ativo
  void selectGame(String gameId) {
    state = state.copyWith(selectedGameId: gameId);

    // Atualiza prioridade do jogo
    if (_userId != null) {
      _multiGameService.updateGamePriority(gameId, _userId!);
    }
  }

  /// Arquiva um jogo
  Future<void> archiveGame(String gameId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _multiGameService.archiveGame(gameId);

      // Se o jogo arquivado era o selecionado, limpa a seleção
      if (state.selectedGameId == gameId) {
        state = state.copyWith(selectedGameId: null);
      }

      // Refresh da lista
      _ref.invalidate(activeGamesProvider);

      state = state.copyWith(isLoading: false);

      AppLogger.info(
        '📁 Jogo arquivado via MultiGameNotifier',
        data: {'gameId': gameId},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao arquivar jogo');
      AppLogger.error('❌ Erro ao arquivar jogo', error: e);
    }
  }

  /// Finaliza um jogo
  Future<void> finishGame(
    String gameId, {
    GameStatus status = GameStatus.completed,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _multiGameService.finishGame(gameId, finalStatus: status);

      // Refresh das listas
      _ref.invalidate(activeGamesProvider);
      _ref.invalidate(gameStatsProvider);

      state = state.copyWith(isLoading: false);

      AppLogger.info(
        '🏁 Jogo finalizado via MultiGameNotifier',
        data: {'gameId': gameId, 'status': status.name},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao finalizar jogo');
      AppLogger.error('❌ Erro ao finalizar jogo', error: e);
    }
  }

  /// Limpa erro
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Força refresh das listas
  void refreshGames() {
    _ref.invalidate(activeGamesProvider);
    _ref.invalidate(activeGamesCountProvider);
    _ref.invalidate(gameStatsProvider);
  }
}

/// Provider para o jogo selecionado atualmente
final selectedGameProvider = Provider<String?>((ref) {
  final multiGameState = ref.watch(multiGameNotifierProvider);
  return multiGameState.selectedGameId;
});

/// Provider para verificar se um jogo específico é o selecionado
final isGameSelectedProvider = Provider.family<bool, String>((ref, gameId) {
  final selectedId = ref.watch(selectedGameProvider);
  return selectedId == gameId;
});

/// Provider para jogos por categoria (para UI com abas)
final gamesCategorizedProvider = Provider<Map<String, List<GameRoomModel>>>((
  ref,
) {
  final activeGamesAsync = ref.watch(activeGamesProvider);

  return activeGamesAsync.when(
    data: (games) {
      final categorized = <String, List<GameRoomModel>>{
        'pending': [],
        'active': [],
        'waiting': [],
      };

      for (final game in games) {
        switch (GameStatus.values.firstWhere((s) => s.name == game.status)) {
          case GameStatus.pending:
            categorized['pending']!.add(game);
            break;
          case GameStatus.active:
            // Verifica se é a vez do usuário
            final authState = ref.read(authProvider);
            final userId = authState.user?.uid;

            if (userId != null && game.currentTurnPlayerId == userId) {
              categorized['active']!.add(game);
            } else {
              categorized['waiting']!.add(game);
            }
            break;
          default:
            break;
        }
      }

      return categorized;
    },
    loading: () => {
      'pending': <GameRoomModel>[],
      'active': <GameRoomModel>[],
      'waiting': <GameRoomModel>[],
    },
    error: (error, stack) {
      AppLogger.error('❌ Erro ao categorizar jogos', error: error);
      return {
        'pending': <GameRoomModel>[],
        'active': <GameRoomModel>[],
        'waiting': <GameRoomModel>[],
      };
    },
  );
});

/// Provider para contadores por categoria
final gameCountsProvider = Provider<Map<String, int>>((ref) {
  final categorized = ref.watch(gamesCategorizedProvider);

  return {
    'pending': categorized['pending']?.length ?? 0,
    'active': categorized['active']?.length ?? 0,
    'waiting': categorized['waiting']?.length ?? 0,
    'total':
        (categorized['pending']?.length ?? 0) +
        (categorized['active']?.length ?? 0) +
        (categorized['waiting']?.length ?? 0),
  };
});

/// Provider para verificar se o usuário tem jogos pendentes
final hasPendingGamesProvider = Provider<bool>((ref) {
  final counts = ref.watch(gameCountsProvider);
  return (counts['pending'] ?? 0) > 0;
});

/// Provider para verificar se o usuário tem jogos aguardando sua vez
final hasActiveGamesProvider = Provider<bool>((ref) {
  final counts = ref.watch(gameCountsProvider);
  return (counts['active'] ?? 0) > 0;
});

/// Provider para o próximo jogo que precisa de ação
final nextActionGameProvider = Provider<GameRoomModel?>((ref) {
  final categorized = ref.watch(gamesCategorizedProvider);

  // Prioridade: convites pendentes > jogos ativos > jogos aguardando
  if (categorized['pending']?.isNotEmpty == true) {
    return categorized['pending']!.first;
  }

  if (categorized['active']?.isNotEmpty == true) {
    return categorized['active']!.first;
  }

  if (categorized['waiting']?.isNotEmpty == true) {
    return categorized['waiting']!.first;
  }

  return null;
});
