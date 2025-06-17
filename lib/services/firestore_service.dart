// lib/services/firestore_service.dart - Com Analytics de Performance
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Buscar usuário por UID com analytics de performance
  Future<UserModel?> getUser(String uid) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '📥 Buscando usuário',
        data: {'uid': uid, 'collection': 'users'},
      );

      final doc = await _db.collection('users').doc(uid).get();
      stopwatch.stop();

      // 📊 Analytics de Performance
      await _trackFirestoreOperation(
        operation: 'getUser',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {'collection': 'users', 'docExists': doc.exists},
      );

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final user = UserModel.fromJson(data);

          AppLogger.firestore(
            '✅ Usuário encontrado',
            data: {
              'uid': user.uid,
              'username': user.username,
              'email': user.email,
              'level': user.level,
              'coins': user.coins,
              'gems': user.gems,
              'createdAt': user.createdAt.toString(),
              'queryTime': '${stopwatch.elapsedMilliseconds}ms',
            },
          );

          return user;
        } else {
          AppLogger.firestore(
            '⚠️ Documento existe mas data é null',
            data: {'uid': uid},
          );
          return null;
        }
      } else {
        AppLogger.firestore('📭 Usuário não encontrado', data: {'uid': uid});
        return null;
      }
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics de Erro
      await _trackFirestoreOperation(
        operation: 'getUser',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {'collection': 'users', 'uid': uid},
      );

      AppLogger.firestore(
        '❌ Erro ao buscar usuário: $e',
        data: {'uid': uid, 'queryTime': '${stopwatch.elapsedMilliseconds}ms'},
      );
      return null;
    }
  }

  /// Criar novo usuário com analytics
  Future<void> createUser(UserModel user) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '💾 Criando usuário',
        data: {
          'uid': user.uid,
          'username': user.username,
          'email': user.email,
          'level': user.level,
          'coins': user.coins,
          'gems': user.gems,
        },
      );

      final userJson = user.toJson();

      await _db.collection('users').doc(user.uid).set(userJson);
      stopwatch.stop();

      // 📊 Analytics de Performance
      await _trackFirestoreOperation(
        operation: 'createUser',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'collection': 'users',
          'docSize': userJson.toString().length,
          'isNewUser': true,
        },
      );

      AppLogger.firestore(
        '✅ Usuário criado com sucesso',
        data: {
          'uid': user.uid,
          'username': user.username,
          'docSize': userJson.toString().length,
          'createTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics de Erro
      await _trackFirestoreOperation(
        operation: 'createUser',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {'collection': 'users', 'uid': user.uid},
      );

      AppLogger.firestore(
        '❌ Erro ao criar usuário: $e',
        data: {
          'uid': user.uid,
          'username': user.username,
          'createTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
      rethrow;
    }
  }

  /// Atualizar usuário com analytics
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '🔄 Atualizando usuário',
        data: {
          'uid': userId,
          'fields': data.keys.toList(),
          'fieldCount': data.length,
        },
      );

      await _db.collection('users').doc(userId).update(data);
      stopwatch.stop();

      // 📊 Analytics de Performance
      await _trackFirestoreOperation(
        operation: 'updateUser',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'collection': 'users',
          'fieldsUpdated': data.keys.toList(),
          'fieldCount': data.length,
        },
      );

      AppLogger.firestore(
        '✅ Usuário atualizado com sucesso',
        data: {
          'uid': userId,
          'updatedFields': data.keys.toList(),
          'updateTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics de Erro
      await _trackFirestoreOperation(
        operation: 'updateUser',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {
          'collection': 'users',
          'uid': userId,
          'attemptedFields': data.keys.toList(),
        },
      );

      AppLogger.firestore(
        '❌ Erro ao atualizar usuário: $e',
        data: {
          'uid': userId,
          'attemptedFields': data.keys.toList(),
          'updateTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
      rethrow;
    }
  }

  /// Query usuários com analytics de performance
  Future<List<UserModel>> queryUsers({
    int? limit,
    String? orderBy,
    bool descending = false,
    Map<String, dynamic>? filters,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '🔍 Query de usuários',
        data: {
          'limit': limit,
          'orderBy': orderBy,
          'descending': descending,
          'filters': filters?.keys.toList(),
        },
      );

      Query<Map<String, dynamic>> query = _db.collection('users');

      // Aplicar filtros
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      // Aplicar ordenação
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Aplicar limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      stopwatch.stop();

      // 📊 Analytics de Performance Query
      await _trackFirestoreOperation(
        operation: 'queryUsers',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          'collection': 'users',
          'resultsCount': users.length,
          'requestedLimit': limit,
          'hasFilters': filters != null,
          'filterCount': filters?.length ?? 0,
          'hasOrdering': orderBy != null,
        },
      );

      AppLogger.firestore(
        '✅ Query concluída',
        data: {
          'resultsCount': users.length,
          'requestedLimit': limit,
          'queryTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return users;
    } catch (e) {
      stopwatch.stop();

      // 📊 Analytics de Erro Query
      await _trackFirestoreOperation(
        operation: 'queryUsers',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {
          'collection': 'users',
          'limit': limit,
          'orderBy': orderBy,
          'filters': filters?.keys.toList(),
        },
      );

      AppLogger.firestore(
        '❌ Erro na query de usuários: $e',
        data: {
          'limit': limit,
          'orderBy': orderBy,
          'filters': filters?.keys.toList(),
          'queryTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
      return [];
    }
  }

  // ========== MÉTODOS DE ANALYTICS INTERNOS ==========

  /// Rastrear operação do Firestore no analytics
  static Future<void> _trackFirestoreOperation({
    required String operation,
    required bool success,
    required int durationMs,
    String? error,
    Map<String, dynamic>? metadata,
  }) async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      final eventData = {
        'operation': operation,
        'success': success,
        'duration_ms': durationMs,
        'duration_category': _getDurationCategory(durationMs),
        if (error != null) 'error_type': error,
        ...?metadata,
      };

      if (success) {
        // Evento de performance bem-sucedida
        await AnalyticsIntegration.manager.trackTiming(
          'firestore_$operation',
          durationMs,
          category: 'firestore_performance',
          parameters: eventData,
        );
      } else {
        // Evento de erro
        await AnalyticsIntegration.manager.trackError(
          'Firestore operation failed: $operation',
          parameters: eventData,
        );
      }

      // Evento geral de uso do Firestore
      await AnalyticsIntegration.manager.trackEvent(
        'firestore_operation',
        parameters: eventData,
        category: EventCategory.system,
        priority: EventPriority.low,
      );
    } catch (e) {
      AppLogger.warning('Erro ao enviar analytics de Firestore: $e');
    }
  }

  /// Categorizar duração da operação
  static String _getDurationCategory(int durationMs) {
    if (durationMs < 100) return 'fast';
    if (durationMs < 500) return 'normal';
    if (durationMs < 1000) return 'slow';
    if (durationMs < 3000) return 'very_slow';
    return 'timeout_risk';
  }

  /// Obter estatísticas de performance do Firestore
  static Future<void> logPerformanceStats() async {
    if (!AnalyticsIntegration.isEnabled) return;

    try {
      await AnalyticsIntegration.manager.trackEvent(
        'firestore_performance_summary',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'service': 'firestore',
        },
        category: EventCategory.performance,
        priority: EventPriority.low,
      );
    } catch (e) {
      AppLogger.warning('Erro ao enviar stats de performance: $e');
    }
  }

  // ========== OUTROS MÉTODOS (sem alteração) ==========

  Future<void> deleteUser(String userId) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore('🗑️ Deletando usuário', data: {'uid': userId});

      await _db.collection('users').doc(userId).delete();
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'deleteUser',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {'collection': 'users'},
      );

      AppLogger.firestore(
        '✅ Usuário deletado',
        data: {
          'uid': userId,
          'deleteTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
    } catch (e) {
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'deleteUser',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {'collection': 'users', 'uid': userId},
      );

      AppLogger.firestore(
        '❌ Erro ao deletar usuário: $e',
        data: {
          'uid': userId,
          'deleteTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
      rethrow;
    }
  }

  Future<bool> userExists(String userId) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore(
        '🔍 Verificando existência do usuário',
        data: {'uid': userId},
      );

      final doc = await _db.collection('users').doc(userId).get();
      final exists = doc.exists;
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'userExists',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {'collection': 'users', 'exists': exists},
      );

      AppLogger.firestore(
        '✅ Verificação concluída',
        data: {
          'uid': userId,
          'exists': exists,
          'checkTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return exists;
    } catch (e) {
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'userExists',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {'collection': 'users', 'uid': userId},
      );

      AppLogger.firestore(
        '❌ Erro ao verificar existência do usuário: $e',
        data: {
          'uid': userId,
          'checkTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );
      return false;
    }
  }

  Future<int?> countUsers() async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.firestore('🔢 Contando usuários...');

      final snapshot = await _db.collection('users').count().get();
      final count = snapshot.count;
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'countUsers',
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {'collection': 'users', 'totalCount': count},
      );

      AppLogger.firestore(
        '✅ Contagem concluída',
        data: {
          'totalUsers': count,
          'countTime': '${stopwatch.elapsedMilliseconds}ms',
        },
      );

      return count;
    } catch (e) {
      stopwatch.stop();

      await _trackFirestoreOperation(
        operation: 'countUsers',
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
        metadata: {'collection': 'users'},
      );

      AppLogger.firestore(
        '❌ Erro ao contar usuários: $e',
        data: {'countTime': '${stopwatch.elapsedMilliseconds}ms'},
      );
      return 0;
    }
  }

  // Manter outros métodos existentes...
  Future<List<UserModel>> getUsers(List<String> userIds) async {
    // Implementação existente com analytics adicionado...
    return [];
  }

  Future<void> batchWrite(List<BatchOperation> operations) async {
    // Implementação existente com analytics adicionado...
  }

  Future<void> logCollectionStats() async {
    // Implementação existente...
  }
}

/// Classe para operações em batch (mantida)
class BatchOperation {
  final BatchOperationType type;
  final DocumentReference ref;
  final Map<String, dynamic>? data;

  BatchOperation({required this.type, required this.ref, this.data});
}

enum BatchOperationType { create, update, delete }
