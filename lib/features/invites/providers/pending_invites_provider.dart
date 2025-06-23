import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/game_room_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/game_service.dart';

/// Um modelo combinado para representar um convite de jogo com os dados do remetente.
class GameInvite {
  final GameRoomModel gameRoom;
  final UserModel inviter;

  GameInvite({required this.gameRoom, required this.inviter});
}

final gameServiceProvider = Provider((ref) => GameService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

/// Provedor que fornece um stream de convites de jogos pendentes.
///
/// Filtra os jogos para mostrar apenas aqueles em que o usuário atual é o convidado
/// e enriquece os dados com as informações do perfil de quem convidou.
final pendingInvitesProvider = StreamProvider<List<GameInvite>>((ref) async* {
  final authState = ref.watch(authProvider);
  final currentUser = authState.user;

  if (currentUser == null) {
    yield [];
    return;
  }

  final gameService = ref.read(gameServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);

  // Escuta o stream de salas de jogo pendentes onde o usuário está envolvido.
  await for (final gameRooms in gameService.getPendingInvitesStream(currentUser.uid)) {
    // Filtra para manter apenas as salas onde o usuário é o convidado (índice 1).
    final pendingInvites = gameRooms.where((room) => room.playerIds.length > 1 && room.playerIds[1] == currentUser.uid).toList();

    if (pendingInvites.isEmpty) {
      yield [];
      continue;
    }

    // Busca os perfis de todos os remetentes de uma vez.
    final inviterIds = pendingInvites.map((room) => room.playerIds[0] as String).toList();
    final inviters = await firestoreService.getUsers(inviterIds);
    final invitersMap = {for (var user in inviters) user.uid: user};

    // Combina os dados da sala de jogo com os dados do remetente.
    yield pendingInvites.map((room) => GameInvite(gameRoom: room, inviter: invitersMap[room.playerIds[0]]!)).toList();
  }
});