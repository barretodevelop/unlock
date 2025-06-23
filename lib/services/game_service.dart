import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/message_model.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Cria um convite para um jogo, resultando em um novo `game_room`.
  ///
  /// Retorna o ID da sala de jogo criada ou `null` em caso de falha.
  Future<String?> sendGameInvite({
    required String inviterId,
    required String inviteeId,
  }) async {
    try {
      AppLogger.info(
        '💌 Enviando convite de jogo',
        data: {'from': inviterId, 'to': inviteeId},
      );

      final gameRoomData = {
        'playerIds': [inviterId, inviteeId],
        'status': GameStatus.pending.name,
        'revealedInfo': {inviterId: {}, inviteeId: {}},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'currentTurnPlayerId': inviterId, // O convidante começa
      };

      final docRef = await _db
          .collection(FirestoreCollections.game_rooms)
          .add(gameRoomData);

      AppLogger.info('✅ Sala de jogo criada com sucesso: ${docRef.id}');
      // ✅ LOGGING APRIMORADO: Confirma o ID da sala retornado.
      AppLogger.info('Returning gameRoomId: ${docRef.id}');

      // TODO: Implementar envio de notificação via Cloud Function
      // A Cloud Function deve ser acionada na criação de um documento em 'game_rooms'
      // e enviar uma notificação para o 'inviteeId'.
      // NotificationService.sendGameInviteNotification(inviteeId: inviteeId, inviterId: inviterId);

      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao enviar convite de jogo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Obtém um stream de uma sala de jogo específica.
  Stream<GameRoomModel> getGameRoomStream(String gameRoomId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .doc(gameRoomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Sala de jogo não encontrada: $gameRoomId');
          }
          return GameRoomModel.fromJson(snapshot.id, snapshot.data()!);
        });
  }

  /// Obtém um stream de convites de jogos pendentes para um usuário específico.
  ///
  /// Filtra as salas onde o usuário é um dos jogadores e o status é 'pending'.
  /// A lógica para determinar se o usuário é o convidado (e não o convidante)
  /// é feita no provider que consome este stream.
  // ✅ CORREÇÃO: O tipo de retorno foi corrigido de Stream<List> para Stream<List<GameRoomModel>> e doc.data() para doc.data()!
  Stream<List<GameRoomModel>> getPendingInvitesStream(String userId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .where('playerIds', arrayContains: userId)
        .where('status', isEqualTo: GameStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return <GameRoomModel>[];
          }
          return snapshot.docs
              .map((doc) => GameRoomModel.fromJson(doc.id, doc.data()!))
              .toList();
        })
        .handleError((Object error, StackTrace stackTrace) {
          AppLogger.error(
            'Erro ao buscar convites pendentes',
            error: error,
            stackTrace: stackTrace,
          );
          return <
            GameRoomModel
          >[]; // Explicitly return an empty list of GameRoomModel
        });
  }

  /// Atualiza campos específicos de uma sala de jogo.
  Future<void> updateGameRoom(
    String gameRoomId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .update(data);
      AppLogger.info('✅ Sala de jogo atualizada: $gameRoomId', data: data);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao atualizar sala de jogo: $gameRoomId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Envia uma mensagem para a sala de jogo de forma atômica.
  Future<void> sendMessage({
    required String gameRoomId,
    required MessageModel message,
  }) async {
    try {
      AppLogger.info(
        '💬 Enviando mensagem para sala $gameRoomId',
        data: {'senderId': message.senderId, 'content': message.content},
      );

      // Usar um WriteBatch para garantir que ambas as operações (adicionar
      // a mensagem e atualizar o timestamp) sejam atômicas.
      final batch = _db.batch();

      // 1. Adiciona a nova mensagem na subcoleção 'messages'
      final messageRef = _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId)
          .collection('messages')
          .doc(message.id);
      batch.set(messageRef, message.toJson());

      // 2. Atualiza o timestamp 'updatedAt' da sala principal
      final gameRoomRef = _db
          .collection(FirestoreCollections.game_rooms)
          .doc(gameRoomId);
      batch.update(gameRoomRef, {'updatedAt': FieldValue.serverTimestamp()});

      // Executa o batch
      await batch.commit();

      AppLogger.info('✅ Mensagem enviada com sucesso de forma atômica.');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao enviar mensagem para a sala $gameRoomId',
        error: e,
        stackTrace: stackTrace,
      );
      // Relançar a exceção para que a camada de UI possa lidar com o erro
      // (ex: mostrar uma mensagem para o usuário).
      rethrow;
    }
  }

  /// Obtém um stream das mensagens de uma sala de jogo, ordenadas por tempo.
  Stream<List<MessageModel>> getGameRoomMessagesStream(String gameRoomId) {
    return _db
        .collection(FirestoreCollections.game_rooms)
        .doc(gameRoomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Encontra uma sala de jogo com base nos UIDs dos dois jogadores.
  Future<String?> findGameRoomByPlayers(String uid1, String uid2) async {
    try {
      // Tenta encontrar a sala com as duas ordens possíveis de playerIds
      final query = await _db
          .collection(FirestoreCollections.game_rooms)
          .where(
            'playerIds',
            whereIn: [
              [uid1, uid2],
              [uid2, uid1],
            ],
          )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao encontrar sala de jogo por jogadores',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
