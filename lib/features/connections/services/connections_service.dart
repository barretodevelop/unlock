// lib/features/connections/services/connections_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart'; // Supondo que você tenha AppLogger

final connectionsServiceProvider = Provider<ConnectionsService>((ref) {
  return ConnectionsService(FirebaseFirestore.instance);
});

class ConnectionsService {
  final FirebaseFirestore _firestore;

  // Cache em memória para contagem de conexões
  final Map<String, int> _connectionsCache = {};

  ConnectionsService(this._firestore);

  Future<int> getConnectionsCount(String userId) async {
    // Verifica se a contagem já está no cache
    if (_connectionsCache.containsKey(userId)) {
      AppLogger.debug(
        '🔗 Conexões obtidas do cache para $userId: ${_connectionsCache[userId]}',
      );
      return _connectionsCache[userId]!;
    }

    try {
      // Exemplo: Se você tem uma subcoleção 'connections' para cada usuário
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('connections')
          // Opcional: adicione um .where('status', isEqualTo: 'accepted') se necessário
          .count() // Usa o agregador count() do Firestore para eficiência
          .get();
      final count = snapshot.count ?? 0;

      // Atualiza o cache com a nova contagem
      _connectionsCache[userId] = count;
      AppLogger.debug(
        '🔗 Contagem de conexões obtida do Firestore para $userId: $count',
      );
      return count;
    } catch (e) {
      AppLogger.error(
        '❌ Erro ao obter contagem de conexões para $userId',
        error: e,
      );
      return 0; // Retorna 0 em caso de erro para não bloquear a lógica de requisitos
    }
  }

  /// Limpa o cache para um usuário específico (ex: ao fazer/desfazer conexão)
  void invalidateUserCache(String userId) {
    _connectionsCache.remove(userId);
    AppLogger.debug('🔗 Cache de conexões invalidado para $userId');
  }

  /// Limpa todo o cache de conexões (ex: no logout)
  void clearAllCache() {
    _connectionsCache.clear();
    AppLogger.debug('🔗 Cache de conexões limpo completamente.');
  }
}
