// lib/features/game/providers/game_room_provider_updated.dart
// Atualização do GameRoomProvider para incluir sistema de recompensas

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/game/data/questions_data.dart';
import 'package:unlock/features/game/models/question_model.dart';
import 'package:unlock/features/matchmaking/providers/matchmaking_provider.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/currency_provider.dart'; // ✅ NOVO IMPORT
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/game_service.dart';

// Provedor para o FirestoreService
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// StreamProvider para a sala de jogo atual
final gameRoomStreamProvider = StreamProvider.family<GameRoomModel, String>((
  ref,
  gameRoomId,
) {
  return ref.watch(gameServiceProvider).getGameRoomStream(gameRoomId);
});

// Provedor para os dados dos jogadores na sala de jogo
final gamePlayersProvider =
    FutureProvider.family<Map<String, UserModel>, String>((
      ref,
      gameRoomId,
    ) async {
      final gameRoom = await ref.watch(
        gameRoomStreamProvider(gameRoomId).future,
      );
      final firestoreService = ref.watch(firestoreServiceProvider);

      final player1Id = gameRoom.playerIds[0];
      final player2Id = gameRoom.playerIds[1];

      final player1 = await firestoreService.getUser(player1Id);
      final player2 = await firestoreService.getUser(player2Id);

      if (player1 == null || player2 == null) {
        throw Exception('Um ou ambos os jogadores não foram encontrados.');
      }

      return {player1Id: player1, player2Id: player2};
    });

// StateNotifierProvider para a lógica do jogo
final gameLogicProvider =
    StateNotifierProvider.family<GameLogicNotifier, GameRoomModel, String>((
      ref,
      gameRoomId,
    ) {
      final gameRoom = ref.watch(gameRoomStreamProvider(gameRoomId)).value;
      if (gameRoom == null) {
        throw Exception('Sala de jogo não carregada para GameLogicNotifier.');
      }
      return GameLogicNotifier(gameRoom, ref);
    });

/// Notifier para lógica do jogo com sistema de recompensas integrado
class GameLogicNotifier extends StateNotifier<GameRoomModel> {
  final Ref _ref;
  final GameService _gameService = GameService();

  GameLogicNotifier(GameRoomModel initialGameRoom, this._ref)
    : super(initialGameRoom);

  /// Submete uma resposta e processa recompensas
  Future<void> submitAnswer(String playerId, String selectedAnswer) async {
    try {
      AppLogger.info(
        '🎮 Submitting answer',
        data: {
          'gameId': state.id,
          'playerId': playerId,
          'answer': selectedAnswer,
        },
      );

      final updatedRoom = await _gameService.submitAnswer(
        state.id,
        playerId,
        selectedAnswer,
      );

      if (updatedRoom != null) {
        state = updatedRoom;

        // ✅ SISTEMA DE RECOMPENSAS - Verifica se a pergunta foi respondida corretamente
        await _processAnswerRewards(playerId, selectedAnswer, updatedRoom);

        // ✅ Verifica se o jogo foi completado
        if (updatedRoom.isCompleted) {
          await _processGameCompletionRewards(updatedRoom);
        }

        // ✅ Verifica se uma conexão foi formada
        if (updatedRoom.revealPercentage >= 100.0 &&
            !updatedRoom.connectionFormed) {
          await _processConnectionRewards(updatedRoom);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to submit answer',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Processa recompensas por resposta correta
  Future<void> _processAnswerRewards(
    String playerId,
    String selectedAnswer,
    GameRoomModel gameRoom,
  ) async {
    try {
      // Verifica se a resposta está correta
      final currentQuestion = gameRoom.currentQuestion;
      if (currentQuestion != null &&
          selectedAnswer == currentQuestion.correctAnswer) {
        // Pequena recompensa por resposta correta (5 moedas)
        final currencyNotifier = _ref.read(currencyProvider.notifier);
        await currencyNotifier.addCoins(
          5,
          'correct_answer',
          gameId: gameRoom.id,
        );

        AppLogger.info(
          '💰 Reward given for correct answer',
          data: {'playerId': playerId, 'gameId': gameRoom.id, 'reward': 5},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process answer rewards',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processa recompensas por completar o jogo
  Future<void> _processGameCompletionRewards(GameRoomModel gameRoom) async {
    try {
      final currencyNotifier = _ref.read(currencyProvider.notifier);

      // Recompensa para ambos os jogadores que completaram o quiz
      for (final playerId in gameRoom.playerIds) {
        await currencyNotifier.addCoins(
          50,
          'gameCompleted',
          gameId: gameRoom.id,
        );
      }

      AppLogger.info(
        '🎉 Game completion rewards distributed',
        data: {
          'gameId': gameRoom.id,
          'players': gameRoom.playerIds,
          'reward': 50,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process game completion rewards',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Processa recompensas por formar uma conexão
  Future<void> _processConnectionRewards(GameRoomModel gameRoom) async {
    try {
      final currencyNotifier = _ref.read(currencyProvider.notifier);
      final authState = _ref.read(authProvider);
      final currentUserId = authState.user?.uid;

      if (currentUserId == null) return;

      // Recompensa grande por formar conexão (100 moedas)
      await currencyNotifier.addCoins(
        100,
        'connectionFormed',
        gameId: gameRoom.id,
      );

      // ✅ Verifica se é a primeira conexão do usuário
      final user = await _ref
          .read(firestoreServiceProvider)
          .getUser(currentUserId);
      if (user != null && user.connectedUsers.isEmpty) {
        // Bônus especial para primeira conexão (200 moedas extras)
        await currencyNotifier.addCoins(
          200,
          'firstConnection',
          gameId: gameRoom.id,
        );

        AppLogger.info(
          '🌟 First connection bonus awarded',
          data: {'userId': currentUserId, 'gameId': gameRoom.id, 'bonus': 200},
        );
      }

      // ✅ Marca a conexão como formada no jogo
      await _gameService.markConnectionFormed(gameRoom.id);

      AppLogger.info(
        '💕 Connection rewards distributed',
        data: {
          'gameId': gameRoom.id,
          'players': gameRoom.playerIds,
          'reward': 100,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process connection rewards',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Envia mensagem no chat da sala
  Future<void> sendMessage(String content, MessageType type) async {
    try {
      final authState = _ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      await _gameService.sendMessage(
        gameRoomId: state.id,
        senderId: currentUser.uid,
        content: content,
        type: type,
      );

      AppLogger.info(
        '💬 Message sent',
        data: {
          'gameId': state.id,
          'senderId': currentUser.uid,
          'type': type.name,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to send message',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtém a próxima pergunta baseada nos interesses
  QuestionModel? getNextQuestion() {
    try {
      final players = state.playerIds;
      if (players.length < 2) return null;

      // Busca interesses comuns dos jogadores
      // Esta lógica pode ser expandida para usar os interesses reais dos usuários
      final commonInterests = ['música', 'filmes', 'games', 'viagem'];

      // Filtra perguntas já respondidas
      final answeredQuestionIds =
          state.gameProgress?.values
              .expand((progress) => progress.answeredQuestions.keys)
              .toSet() ??
          <String>{};

      // Busca uma pergunta não respondida
      final availableQuestions = QuestionsData.getAllQuestions()
          .where((q) => !answeredQuestionIds.contains(q.id))
          .where((q) => commonInterests.contains(q.category.toLowerCase()))
          .toList();

      if (availableQuestions.isEmpty) {
        // Se não há mais perguntas específicas, usa perguntas gerais
        final generalQuestions = QuestionsData.getAllQuestions()
            .where((q) => !answeredQuestionIds.contains(q.id))
            .toList();

        return generalQuestions.isNotEmpty ? generalQuestions.first : null;
      }

      // Seleciona uma pergunta aleatória
      availableQuestions.shuffle();
      return availableQuestions.first;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to get next question',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Finaliza o jogo e distribui recompensas finais
  Future<void> finishGame() async {
    try {
      await _gameService.finishGame(state.id);

      // Processa quaisquer recompensas finais adicionais
      if (state.revealPercentage >= 100.0) {
        await _processGameCompletionRewards(state);
      }

      AppLogger.info(
        '🏁 Game finished successfully',
        data: {'gameId': state.id, 'revealPercentage': state.revealPercentage},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to finish game',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Abandona o jogo (sem recompensas)
  Future<void> leaveGame() async {
    try {
      final authState = _ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      await _gameService.leaveGame(state.id, currentUser.uid);

      AppLogger.info(
        '🚪 Player left game',
        data: {'gameId': state.id, 'playerId': currentUser.uid},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to leave game',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtém estatísticas do jogo atual
  Map<String, dynamic> getGameStats() {
    final totalQuestions =
        state.gameProgress?.values
            .expand((progress) => progress.answeredQuestions.keys)
            .length ??
        0;

    final correctAnswers =
        state.gameProgress?.values
            .expand((progress) => progress.answeredQuestions.values)
            .where((correct) => correct)
            .length ??
        0;

    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': totalQuestions > 0
          ? (correctAnswers / totalQuestions) * 100
          : 0,
      'revealPercentage': state.revealPercentage,
      'isCompleted': state.isCompleted,
      'connectionFormed': state.connectionFormed,
      'estimatedCoinsEarned': _calculateEstimatedRewards(),
    };
  }

  /// Calcula as recompensas estimadas para o jogo atual
  int _calculateEstimatedRewards() {
    int totalRewards = 0;

    // Recompensas por respostas corretas (5 moedas cada)
    final correctAnswers =
        state.gameProgress?.values
            .expand((progress) => progress.answeredQuestions.values)
            .where((correct) => correct)
            .length ??
        0;
    totalRewards += correctAnswers * 5;

    // Recompensa por completar o jogo (50 moedas)
    if (state.isCompleted) {
      totalRewards += 50;
    }

    // Recompensa por formar conexão (100 moedas)
    if (state.revealPercentage >= 100.0) {
      totalRewards += 100;
    }

    return totalRewards;
  }
}
