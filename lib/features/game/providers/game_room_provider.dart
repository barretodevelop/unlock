import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/game/data/questions_data.dart';
import 'package:unlock/features/game/models/question_model.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/game_service.dart';

// Provedor para o GameService
final gameServiceProvider = Provider((ref) => GameService());

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
      return GameLogicNotifier(ref, gameRoom);
    });

// StreamProvider para as mensagens da sala de jogo
final gameMessagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, gameRoomId) {
      return ref
          .watch(gameServiceProvider)
          .getGameRoomMessagesStream(gameRoomId);
    });

class GameLogicNotifier extends StateNotifier<GameRoomModel> {
  final Ref _ref;
  final GameService _gameService;
  final FirestoreService _firestoreService;

  GameLogicNotifier(this._ref, GameRoomModel initialGameRoom)
    : _gameService = _ref.read(gameServiceProvider),
      _firestoreService = _ref.read(firestoreServiceProvider),
      super(initialGameRoom);

  // Inicia o jogo (se ainda estiver pendente)
  // Lista de chaves de perfil que podem ser reveladas
  static const List<String> _revealableKeys = [
    'photo_url',
    'favorite_bands',
    'social_media',
  ];
  Future<void> startGame() async {
    if (state.status == GameStatus.pending) {
      AppLogger.info('Iniciando jogo ${state.id}');
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.active.name,
      });
      // Selecionar a primeira pergunta
      await _selectNextQuestion();
    }
  }

  // Seleciona a próxima pergunta com base nos interesses em comum
  Future<void> _selectNextQuestion() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    final players = await _ref.read(gamePlayersProvider(state.id).future);
    final opponent = players.values.firstWhere((p) => p.uid != currentUser.uid);

    final commonInterests = currentUser.interesses
        .toSet()
        .intersection(opponent.interesses.toSet())
        .toList();

    // Filtrar perguntas que ainda não foram feitas
    final askedQuestionIds = state.questions.map((q) => q['id']).toSet();
    final availableQuestions = QuestionsData.allQuestions.where(
      (q) =>
          !askedQuestionIds.contains(q.id) &&
          q.relatedInterests.any(
            (interest) => commonInterests.contains(interest),
          ),
    );

    QuestionModel? nextQuestion;
    if (availableQuestions.isNotEmpty) {
      // Para MVP, apenas pegue a primeira disponível. Em um app real, seria mais sofisticado.
      nextQuestion = availableQuestions.first;
    } else {
      // Se não houver mais perguntas baseadas em interesses, pegue qualquer uma não feita
      nextQuestion = QuestionsData.allQuestions
          .where((q) => !askedQuestionIds.contains(q.id))
          .firstOrNull;
    }

    if (nextQuestion != null) {
      final updatedQuestions = List<Map<String, dynamic>>.from(state.questions)
        ..add(nextQuestion.toJson());
      await _gameService.updateGameRoom(state.id, {
        'questions': updatedQuestions,
        'currentTurnPlayerId':
            currentUser.uid, // O jogador atual faz a pergunta
      });
      AppLogger.info('Nova pergunta selecionada: ${nextQuestion.text}');
    } else {
      AppLogger.info(
        'Todas as perguntas foram feitas ou não há mais perguntas relevantes.',
      );
      // TODO: Lidar com o fim do quiz, talvez ir para a fase de chat
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.finished.name,
      });
    }
  }

  // Submete uma resposta para a pergunta atual
  Future<void> submitAnswer(String answer) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null || state.currentTurnPlayerId != currentUser.uid) {
      AppLogger.warning('Não é o turno do usuário para responder.');
      return;
    }

    final currentQuestion = state.questions.lastOrNull;
    if (currentQuestion == null) {
      AppLogger.warning('Nenhuma pergunta ativa para responder.');
      return;
    }

    final updatedAnswers = Map<String, Map<String, dynamic>>.from(
      state.answers,
    );
    updatedAnswers[currentQuestion['id']] = {
      ...(updatedAnswers[currentQuestion['id']] ?? {}),
      currentUser.uid: answer,
    };

    // Lógica de revelação progressiva
    final currentProgress = Map<String, double>.from(state.progress);
    final newProgressValue =
        (currentProgress[currentUser.uid] ?? 0.0) + 0.25; // Aumenta 25%
    currentProgress[currentUser.uid] = newProgressValue;

    // Determinar qual informação revelar ao oponente
    final opponent = (await _ref.read(
      gamePlayersProvider(state.id).future,
    )).values.firstWhere((p) => p.uid != currentUser.uid);

    // Calcular o índice da próxima revelação com base no progresso
    final revelationIndex = ((newProgressValue * _revealableKeys.length) - 1)
        .toInt()
        .clamp(0, _revealableKeys.length - 1);

    final String keyToReveal = _revealableKeys[revelationIndex];

    // Obter o valor real a ser revelado do perfil do oponente
    dynamic valueToReveal;
    switch (keyToReveal) {
      case 'photo_url':
        valueToReveal = opponent.actualPhotoUrl;
        break;
      case 'favorite_bands':
        valueToReveal = opponent.actualFavoriteBands;
        break;
      case 'social_media':
        valueToReveal = opponent.actualSocialMediaHandle;
        break;
    }

    // Atualizar o perfil revelado do oponente no Firestore
    final Map<String, dynamic> updatedOpponentRevealedProfile =
        Map<String, dynamic>.from(opponent.revealedProfile);
    if (valueToReveal != null &&
        updatedOpponentRevealedProfile[keyToReveal] == null) {
      updatedOpponentRevealedProfile[keyToReveal] = valueToReveal;
      await _firestoreService.updateUser(opponent.uid, {
        'revealedProfile': updatedOpponentRevealedProfile,
      });
      AppLogger.info('Informação revelada para ${opponent.uid}: $keyToReveal');
    }

    await _gameService.updateGameRoom(state.id, {
      'answers': updatedAnswers,
      'progress': currentProgress,
      'currentTurnPlayerId': state.playerIds.firstWhere(
        (id) => id != currentUser.uid,
      ), // Passa o turno
    });

    AppLogger.info('Resposta submetida e progresso atualizado.');
    // Verificar se o jogo terminou (ambos 100%)
    final inviterProgress = currentProgress[state.playerIds[0]] ?? 0.0;
    final inviteeProgress = currentProgress[state.playerIds[1]] ?? 0.0;

    if (inviterProgress >= 1.0 && inviteeProgress >= 1.0) {
      AppLogger.info('Progresso de ${currentUser.uid} atingiu 100%.');
      await _gameService.updateGameRoom(state.id, {
        'status': GameStatus.finished.name,
      });
      // Registrar conexão mútua nos perfis dos usuários
      final players = await _ref.read(gamePlayersProvider(state.id).future);
      final opponent = players.values.firstWhere(
        (p) => p.uid != currentUser.uid,
      );

      // Adicionar o UID do oponente à lista de conectados do usuário atual
      await _firestoreService.updateUser(currentUser.uid, {
        'connectedUsers': FieldValue.arrayUnion([opponent.uid]),
      });
      // Adicionar o UID do usuário atual à lista de conectados do oponente
      await _firestoreService.updateUser(opponent.uid, {
        'connectedUsers': FieldValue.arrayUnion([currentUser.uid]),
      });
    }
  }

  // Envia uma mensagem no chat
  Future<void> sendMessage(String content) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) {
      AppLogger.warning(
        'Não é possível enviar mensagem: usuário não autenticado.',
      );
      return;
    }

    final message = MessageModel(
      id: _firestoreService
          .generateDocId(), // Gerar um ID único para a mensagem
      senderId: currentUser.uid,
      content: content,
      // timestamp: DateTime.now(),
    );
    await _gameService.sendMessage(gameRoomId: state.id, message: message);
  }
}
