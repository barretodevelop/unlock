import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/core/utils/utils.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

/// Provedor que busca os perfis dos usuários conectados.
final connectionsProvider = FutureProvider<List<UserModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final currentUser = authState.user;

  if (currentUser == null || currentUser.connectedUsers.isEmpty) {
    return [];
  }

  AppLogger.info(
    'Buscando perfis de ${currentUser.connectedUsers.length} conexões.',
    data: {'connected_uids': currentUser.connectedUsers},
  );

  final firestoreService = ref.read(firestoreServiceProvider);
  final List<UserModel> connections = [];

  // O Firestore suporta 'whereIn' com até 30 itens.
  // Buscamos os usuários em lotes para maior eficiência.
  final uidsToFetch = currentUser.connectedUsers;
  final uidBatches = uidsToFetch.slices(30);

  for (final batch in uidBatches) {
    if (batch.isNotEmpty) {
      final users = await firestoreService.getUsers(batch);
      connections.addAll(users);
    }
  }

  // Ordenar para manter uma ordem consistente, se necessário
  connections.sort((a, b) => a.displayName.compareTo(b.displayName));

  return connections;
});
