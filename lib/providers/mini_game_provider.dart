// lib/providers/mini_game_provider.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/mini_game_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/mini_game_service.dart';

// ========== STREAM PROVIDERS ==========

/// Provider para ranking de um jogo específico
final gameLeaderboardProvider = StreamProvider.family<List<GameResult>, GameType>((ref, gameType) {
  AppLogger.debug('🎮 Buscando leaderboard: ${gameType.name}');
  return MiniGameService.getLeaderboard(gameType);
});

/// Provider para histórico pessoal de jogos
final userGameHistoryProvider = StreamProvider.family<List<GameResult>, String>((ref, userId) {
  AppLogger.debug('🎮 Buscando histórico: $userId');
  return MiniGameService.getUserGameHistory(userId);
});

/// Provider para melhor score pessoal
final personalBestProvider = FutureProvider.family<GameResult?, GameTypeQuery>((ref, query) {
  AppLogger.debug('🎮 Buscando personal best: ${query.type.name}');
  return MiniGameService.getPersonalBest(query.userId, query.type, query.difficulty);
});

// ========== STATE PROVIDERS ==========

/// Estado global dos mini-games
class MiniGameGlobalState {
  final bool isLoading;
  final String? error;
  final Map<GameType, GameResult?> personalBests;
  final Map<GameType, List<GameResult>> recentGames;

  const MiniGameGlobalState({
    this.isLoading = false,
    this.error,
    this.personalBests = const {},
    this.recentGames = const {},
  });

  MiniGameGlobalState copyWith({
    bool? isLoading,
    String? error,
    Map<GameType, GameResult?>? personalBests,
    Map<GameType, List<GameResult>>? recentGames,
  }) {
    return MiniGameGlobalState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      personalBests: personalBests ?? this.personalBests,
      recentGames: recentGames ?? this.recentGames,
    );
  }
}

/// Provider global dos mini-games
final miniGameGlobalProvider = StateNotifierProvider<MiniGameGlobalNotifier, MiniGameGlobalState>((ref) {
  return MiniGameGlobalNotifier(ref);
});

class MiniGameGlobalNotifier extends StateNotifier<MiniGameGlobalState> {
  final Ref _ref;

  MiniGameGlobalNotifier(this._ref) : super(const MiniGameGlobalState());

  /// Carregar dados pessoais
  Future<void> loadPersonalData() async {
    final user = _ref.read(authProvider.select((s) => s.user));
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final personalBests = <GameType, GameResult?>{};
      
      for (final gameType in GameType.values) {
        final best = await MiniGameService.getPersonalBest(
          user.uid, 
          gameType, 
          GameDifficulty.normal,
        );
        personalBests[gameType] = best;
      }

      state = state.copyWith(
        isLoading: false,
        personalBests: personalBests,
      );

      AppLogger.info('🎮 Dados pessoais carregados', data: {
        'personalBests': personalBests.length,
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar dados: $e',
      );
      AppLogger.error('🎮 Erro ao carregar dados pessoais', error: e);
    }
  }

  /// Salvar resultado de jogo
  Future<bool> saveGameResult(GameResult result) async {
    try {
      final saved = await MiniGameService.saveGameResult(result);
      
      if (saved) {
        // Atualizar personal best se necessário
        final currentBest = state.personalBests[result.type];
        if (currentBest == null || result.finalScore > currentBest.finalScore) {
          final updatedBests = Map<GameType, GameResult?>.from(state.personalBests);
          updatedBests[result.type] = result.copyWith(isPersonalBest: true);
          
          state = state.copyWith(personalBests: updatedBests);
          
          AppLogger.info('🎮 Novo personal best!', data: {
            'game': result.type.name,
            'score': result.finalScore,
          });
        }
      }

      return saved;
    } catch (e) {
      AppLogger.error('🎮 Erro ao salvar resultado', error: e);
      return false;
    }
  }
}

/// Provider para estado de jogo individual
final gameSessionProvider = StateNotifierProvider.family<GameSessionNotifier, GameState, GameType>((ref, gameType) {
  return GameSessionNotifier(ref, gameType);
});

class GameSessionNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  Timer? _gameTimer;
  Timer? _reactionTimer;

  GameSessionNotifier(this._ref, GameType gameType) : super(GameState.initial(gameType));

  @override
  void dispose() {
    _gameTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }

  /// Iniciar novo jogo
  void startGame({GameDifficulty? difficulty}) {
    // Cancelar timers existentes
    _gameTimer?.cancel();
    _reactionTimer?.cancel();

    // Criar novo estado
    state = GameState.initial(state.type, difficulty: difficulty);
    
    // Inicializar dados específicos do jogo
    final gameData = _initializeGameData();
    state = state.copyWith(
      status: GameStatus.playing,
      gameData: gameData,
    );

    // Iniciar timer principal
    _startGameTimer();

    // Setup específico por tipo de jogo
    _setupGameType();

    AppLogger.info('🎮 Jogo iniciado: ${state.type.name}', data: {
      'difficulty': state.config.difficulty.label,
      'timeLimit': state.config.timeLimit?.inSeconds,
    });
  }

  /// Pausar jogo
  void pauseGame() {
    if (state.status == GameStatus.playing) {
      state = state.copyWith(status: GameStatus.paused);
      _gameTimer?.cancel();
      _reactionTimer?.cancel();
      AppLogger.debug('🎮 Jogo pausado');
    }
  }

  /// Retomar jogo
  void resumeGame() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
      _startGameTimer();
      _setupGameType();
      AppLogger.debug('🎮 Jogo retomado');
    }
  }

  /// Finalizar jogo
  Future<GameResult?> finishGame({bool success = true}) async {
    _gameTimer?.cancel();
    _reactionTimer?.cancel();

    final finalStatus = success ? GameStatus.completed : GameStatus.failed;
    state = state.copyWith(status: finalStatus);

    if (success) {
      // Criar resultado
      final result = GameResult.fromScore(
        gameId: state.id,
        userId: _ref.read(authProvider.select((s) => s.user?.uid)) ?? '',
        type: state.type,
        difficulty: state.config.difficulty,
        score: state.currentScore,
        duration: state.elapsed,
        stats: _generateGameStats(),
      );

      // Salvar resultado
      await _ref.read(miniGameGlobalProvider.notifier).saveGameResult(result);

      AppLogger.info('🎮 Jogo finalizado com sucesso', data: {
        'score': result.finalScore,
        'rank': result.rank,
        'duration': result.duration.inSeconds,
      });

      return result;
    }

    AppLogger.info('🎮 Jogo finalizado sem sucesso');
    return null;
  }

  /// Atualizar pontuação
  void updateScore(int points) {
    if (state.canPlay) {
      state = state.copyWith(currentScore: state.currentScore + points);
    }
  }

  /// Atualizar dados do jogo
  void updateGameData(Map<String, dynamic> newData) {
    if (state.canPlay) {
      final updatedData = Map<String, dynamic>.from(state.gameData);
      updatedData.addAll(newData);
      state = state.copyWith(gameData: updatedData);
    }
  }

  /// Timer principal do jogo
  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.status != GameStatus.playing) {
        timer.cancel();
        return;
      }

      final newElapsed = state.elapsed + const Duration(milliseconds: 100);
      state = state.copyWith(elapsed: newElapsed);

      // Verificar limite de tempo
      if (state.isTimeUp) {
        timer.cancel();
        finishGame(success: false);
      }
    });
  }

  /// Inicializar dados específicos do jogo
  Map<String, dynamic> _initializeGameData() {
    switch (state.type) {
      case GameType.memory:
        return _initMemoryData();
      case GameType.reaction:
        return _initReactionData();
      case GameType.puzzle:
        return _initPuzzleData();
    }
  }

  /// Setup específico por tipo
  void _setupGameType() {
    switch (state.type) {
      case GameType.memory:
        _setupMemoryGame();
        break;
      case GameType.reaction:
        _setupReactionGame();
        break;
      case GameType.puzzle:
        _setupPuzzleGame();
        break;
    }
  }

  /// Gerar estatísticas do jogo
  Map<String, dynamic> _generateGameStats() {
    final baseStats = {
      'accuracy': _calculateAccuracy(),
      'averageTime': _calculateAverageTime(),
      'totalMoves': state.gameData['totalMoves'] ?? 0,
    };

    switch (state.type) {
      case GameType.memory:
        final memoryStats = _generateMemoryStats();
        return {...baseStats, ...memoryStats};
      case GameType.reaction:
        final reactionStats = _generateReactionStats();
        return {...baseStats, ...reactionStats};
      case GameType.puzzle:
        final puzzleStats = _generatePuzzleStats();
        return {...baseStats, ...puzzleStats};
    }
  }

  // ========== MÉTODOS ESPECÍFICOS DE CADA JOGO ==========

  /// JOGO DE MEMÓRIA
  Map<String, dynamic> _initMemoryData() {
    final gridSize = state.config.customParams['gridSize'] as int;
    final sequence = _generateMemorySequence(gridSize * gridSize);
    
    return {
      'gridSize': gridSize,
      'sequence': sequence,
      'currentStep': 0,
      'showTime': state.config.customParams['showTime'],
      'isShowing': true,
      'totalMoves': 0,
      'correctMoves': 0,
    };
  }

  void _setupMemoryGame() {
    // Timer para esconder sequência
    final showTime = state.gameData['showTime'] as int;
    _reactionTimer = Timer(Duration(milliseconds: showTime), () {
      updateGameData({'isShowing': false});
    });
  }

  List<int> _generateMemorySequence(int maxIndex) {
    final random = math.Random();
    final sequenceLength = math.max(3, (maxIndex * 0.3).round());
    return List.generate(sequenceLength, (_) => random.nextInt(maxIndex));
  }

  Map<String, dynamic> _generateMemoryStats() {
    return {
      'sequenceLength': (state.gameData['sequence'] as List).length,
      'memoryAccuracy': state.gameData['correctMoves'] / (state.gameData['sequence'] as List).length,
    };
  }

  /// JOGO DE REAÇÃO
  Map<String, dynamic> _initReactionData() {
    return {
      'rounds': state.config.customParams['rounds'],
      'currentRound': 0,
      'reactions': <int>[],
      'isWaiting': false,
      'showTarget': false,
      'roundStartTime': 0,
      'totalMoves': 0,
    };
  }

  void _setupReactionGame() {
    _startReactionRound();
  }

  void _startReactionRound() {
    final random = math.Random();
    final minDelay = state.config.customParams['minDelay'] as int;
    final maxDelay = state.config.customParams['maxDelay'] as int;
    
    final delay = minDelay + random.nextInt(maxDelay - minDelay);
    
    updateGameData({'isWaiting': true, 'showTarget': false});
    
    _reactionTimer = Timer(Duration(milliseconds: delay), () {
      if (state.canPlay) {
        updateGameData({
          'isWaiting': false,
          'showTarget': true,
          'roundStartTime': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Map<String, dynamic> _generateReactionStats() {
    final reactions = state.gameData['reactions'] as List<int>;
    final avgReaction = reactions.isEmpty ? 0 : reactions.reduce((a, b) => a + b) / reactions.length;
    
    return {
      'averageReaction': avgReaction,
      'bestReaction': reactions.isEmpty ? 0 : reactions.reduce(math.min),
      'worstReaction': reactions.isEmpty ? 0 : reactions.reduce(math.max),
    };
  }

  /// JOGO DE PUZZLE
  Map<String, dynamic> _initPuzzleData() {
    final pieceCount = state.config.customParams['pieceCount'] as int;
    final gridSize = math.sqrt(pieceCount).round();
    final pieces = _generateShuffledPuzzle(pieceCount);
    
    return {
      'gridSize': gridSize,
      'pieces': pieces,
      'solved': false,
      'totalMoves': 0,
      'rotationEnabled': state.config.customParams['rotationEnabled'] ?? false,
    };
  }

  void _setupPuzzleGame() {
    // Puzzle não precisa de setup adicional
  }

  List<int> _generateShuffledPuzzle(int pieceCount) {
    final pieces = List.generate(pieceCount, (i) => i);
    pieces.shuffle();
    return pieces;
  }

  Map<String, dynamic> _generatePuzzleStats() {
    return {
      'solvingEfficiency': _calculatePuzzleEfficiency(),
      'movesPerSecond': state.gameData['totalMoves'] / state.elapsed.inSeconds,
    };
  }

  // ========== MÉTODOS AUXILIARES ==========

  double _calculateAccuracy() {
    final correctMoves = state.gameData['correctMoves'] ?? 0;
    final totalMoves = state.gameData['totalMoves'] ?? 1;
    return correctMoves / totalMoves;
  }

  double _calculateAverageTime() {
    return state.elapsed.inMilliseconds / (state.gameData['totalMoves'] ?? 1);
  }

  double _calculatePuzzleEfficiency() {
    final pieceCount = state.config.customParams['pieceCount'] as int;
    final optimalMoves = pieceCount * 2; // Estimativa de movimentos ótimos
    final actualMoves = state.gameData['totalMoves'] ?? 1;
    return optimalMoves / actualMoves;
  }
}

/// Query helper para personal best
class GameTypeQuery {
  final String userId;
  final GameType type;
  final GameDifficulty difficulty;

  const GameTypeQuery({
    required this.userId,
    required this.type,
    required this.difficulty,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is GameTypeQuery &&
    userId == other.userId &&
    type == other.type &&
    difficulty == other.difficulty;

  @override
  int get hashCode => Object.hash(userId, type, difficulty);
}