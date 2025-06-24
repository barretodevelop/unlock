// lib/models/mini_game_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tipos de mini-games disponíveis
enum GameType {
  memory('memory', '🧠', 'Memória', 'Teste sua memória visual'),
  reaction('reaction', '⚡', 'Reação', 'Velocidade de reflexos'),
  puzzle('puzzle', '🧩', 'Puzzle', 'Resolva o quebra-cabeça');

  const GameType(this.id, this.icon, this.name, this.description);
  final String id;
  final String icon;
  final String name;
  final String description;

  /// Cor temática do jogo
  Color get themeColor {
    switch (this) {
      case GameType.memory:
        return Colors.purple;
      case GameType.reaction:
        return Colors.orange;
      case GameType.puzzle:
        return Colors.green;
    }
  }

  /// Dificuldade padrão
  GameDifficulty get defaultDifficulty => GameDifficulty.normal;
}

/// Níveis de dificuldade
enum GameDifficulty {
  easy('easy', 'Fácil', 1.0),
  normal('normal', 'Normal', 1.5),
  hard('hard', 'Difícil', 2.0),
  expert('expert', 'Expert', 3.0);

  const GameDifficulty(this.id, this.label, this.multiplier);
  final String id;
  final String label;
  final double multiplier; // Multiplicador de pontos
}

/// Status da partida
enum GameStatus {
  waiting('waiting', 'Aguardando'),
  playing('playing', 'Jogando'),
  paused('paused', 'Pausado'),
  completed('completed', 'Concluído'),
  failed('failed', 'Falhou');

  const GameStatus(this.id, this.label);
  final String id;
  final String label;
}

/// Resultado de uma partida
class GameResult {
  final String gameId;
  final String userId;
  final GameType type;
  final GameDifficulty difficulty;
  final int score;
  final int finalScore; // Score com multiplicador aplicado
  final Duration duration;
  final DateTime completedAt;
  final Map<String, dynamic> stats;
  final bool isPersonalBest;

  const GameResult({
    required this.gameId,
    required this.userId,
    required this.type,
    required this.difficulty,
    required this.score,
    required this.finalScore,
    required this.duration,
    required this.completedAt,
    this.stats = const {},
    this.isPersonalBest = false,
  });

  /// Criar resultado a partir de pontuação
  factory GameResult.fromScore({
    required String gameId,
    required String userId,
    required GameType type,
    required GameDifficulty difficulty,
    required int score,
    required Duration duration,
    Map<String, dynamic>? stats,
  }) {
    final finalScore = (score * difficulty.multiplier).round();
    
    return GameResult(
      gameId: gameId,
      userId: userId,
      type: type,
      difficulty: difficulty,
      score: score,
      finalScore: finalScore,
      duration: duration,
      completedAt: DateTime.now(),
      stats: stats ?? {},
    );
  }

  /// Converter de JSON
  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      gameId: json['gameId'] ?? '',
      userId: json['userId'] ?? '',
      type: GameType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => GameType.memory,
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (d) => d.id == json['difficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      score: json['score'] ?? 0,
      finalScore: json['finalScore'] ?? 0,
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      isPersonalBest: json['isPersonalBest'] ?? false,
    );
  }

  /// Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'userId': userId,
      'type': type.id,
      'difficulty': difficulty.id,
      'score': score,
      'finalScore': finalScore,
      'durationMs': duration.inMilliseconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'stats': stats,
      'isPersonalBest': isPersonalBest,
    };
  }

  /// Calcular rank baseado no score
  String get rank {
    if (finalScore >= 1000) return 'S';
    if (finalScore >= 800) return 'A';
    if (finalScore >= 600) return 'B';
    if (finalScore >= 400) return 'C';
    return 'D';
  }

  /// Cor do rank
  Color get rankColor {
    switch (rank) {
      case 'S': return Colors.amber;
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      default: return Colors.grey;
    }
  }

  GameResult copyWith({
    bool? isPersonalBest,
    Map<String, dynamic>? stats,
  }) {
    return GameResult(
      gameId: gameId,
      userId: userId,
      type: type,
      difficulty: difficulty,
      score: score,
      finalScore: finalScore,
      duration: duration,
      completedAt: completedAt,
      stats: stats ?? this.stats,
      isPersonalBest: isPersonalBest ?? this.isPersonalBest,
    );
  }
}

/// Configuração de um mini-game
class GameConfig {
  final GameType type;
  final GameDifficulty difficulty;
  final Duration? timeLimit;
  final int? targetScore;
  final Map<String, dynamic> customParams;

  const GameConfig({
    required this.type,
    required this.difficulty,
    this.timeLimit,
    this.targetScore,
    this.customParams = const {},
  });

  /// Configurações por tipo de jogo
  factory GameConfig.forType(GameType type, {GameDifficulty? difficulty}) {
    final diff = difficulty ?? type.defaultDifficulty;
    
    switch (type) {
      case GameType.memory:
        return GameConfig(
          type: type,
          difficulty: diff,
          timeLimit: Duration(seconds: _getMemoryTimeLimit(diff)),
          customParams: {
            'gridSize': _getMemoryGridSize(diff),
            'showTime': _getMemoryShowTime(diff),
          },
        );
        
      case GameType.reaction:
        return GameConfig(
          type: type,
          difficulty: diff,
          timeLimit: const Duration(minutes: 2),
          customParams: {
            'rounds': _getReactionRounds(diff),
            'minDelay': _getReactionMinDelay(diff),
            'maxDelay': _getReactionMaxDelay(diff),
          },
        );
        
      case GameType.puzzle:
        return GameConfig(
          type: type,
          difficulty: diff,
          customParams: {
            'pieceCount': _getPuzzlePieces(diff),
            'rotationEnabled': diff.index >= 1,
          },
        );
    }
  }

  // Configurações específicas de memória
  static int _getMemoryTimeLimit(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 90;
      case GameDifficulty.normal: return 60;
      case GameDifficulty.hard: return 45;
      case GameDifficulty.expert: return 30;
    }
  }

  static int _getMemoryGridSize(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 3; // 3x3
      case GameDifficulty.normal: return 4; // 4x4
      case GameDifficulty.hard: return 5; // 5x5
      case GameDifficulty.expert: return 6; // 6x6
    }
  }

  static int _getMemoryShowTime(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 3000; // 3s
      case GameDifficulty.normal: return 2000; // 2s
      case GameDifficulty.hard: return 1500; // 1.5s
      case GameDifficulty.expert: return 1000; // 1s
    }
  }

  // Configurações específicas de reação
  static int _getReactionRounds(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 5;
      case GameDifficulty.normal: return 8;
      case GameDifficulty.hard: return 12;
      case GameDifficulty.expert: return 15;
    }
  }

  static int _getReactionMinDelay(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 2000; // 2s
      case GameDifficulty.normal: return 1500; // 1.5s
      case GameDifficulty.hard: return 1000; // 1s
      case GameDifficulty.expert: return 500; // 0.5s
    }
  }

  static int _getReactionMaxDelay(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 5000; // 5s
      case GameDifficulty.normal: return 4000; // 4s
      case GameDifficulty.hard: return 3000; // 3s
      case GameDifficulty.expert: return 2000; // 2s
    }
  }

  // Configurações específicas de puzzle
  static int _getPuzzlePieces(GameDifficulty diff) {
    switch (diff) {
      case GameDifficulty.easy: return 9; // 3x3
      case GameDifficulty.normal: return 16; // 4x4
      case GameDifficulty.hard: return 25; // 5x5
      case GameDifficulty.expert: return 36; // 6x6
    }
  }
}

/// Estado atual do jogo
class GameState {
  final String id;
  final GameType type;
  final GameConfig config;
  final GameStatus status;
  final int currentScore;
  final Duration elapsed;
  final Map<String, dynamic> gameData;
  final String? error;

  const GameState({
    required this.id,
    required this.type,
    required this.config,
    required this.status,
    this.currentScore = 0,
    this.elapsed = Duration.zero,
    this.gameData = const {},
    this.error,
  });

  /// Estado inicial
  factory GameState.initial(GameType type, {GameDifficulty? difficulty}) {
    final config = GameConfig.forType(type, difficulty: difficulty);
    
    return GameState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      config: config,
      status: GameStatus.waiting,
    );
  }

  GameState copyWith({
    GameStatus? status,
    int? currentScore,
    Duration? elapsed,
    Map<String, dynamic>? gameData,
    String? error,
  }) {
    return GameState(
      id: id,
      type: type,
      config: config,
      status: status ?? this.status,
      currentScore: currentScore ?? this.currentScore,
      elapsed: elapsed ?? this.elapsed,
      gameData: gameData ?? this.gameData,
      error: error,
    );
  }

  /// Verificar se tem tempo limite
  bool get hasTimeLimit => config.timeLimit != null;

  /// Tempo restante
  Duration? get timeRemaining {
    if (!hasTimeLimit) return null;
    final remaining = config.timeLimit! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Verificar se tempo esgotou
  bool get isTimeUp => hasTimeLimit && timeRemaining == Duration.zero;

  /// Verificar se pode jogar
  bool get canPlay => status == GameStatus.playing && !isTimeUp;
}