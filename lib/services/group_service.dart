// lib/services/group_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/group_model.dart';

class GroupService {
  static final _db = FirebaseFirestore.instance;
  static const String _collection = 'groups';
  static const String _membersSubcollection = 'members';

  /// Criar novo grupo
  static Future<String?> createGroup(GroupModel group) async {
    try {
      AppLogger.info('🎯 Criando grupo: ${group.name}');

      final docRef = await _db.collection(_collection).add(group.toJson());

      // Atualizar o documento com o ID gerado
      await docRef.update({'id': docRef.id});

      // Criar subcoleção de membros para queries otimizadas
      await _createMemberDocument(docRef.id, group.creatorId, isCreator: true);

      AppLogger.info('✅ Grupo criado com sucesso: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao criar grupo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Buscar grupos do usuário
  static Stream<List<GroupModel>> getUserGroups(String userId) {
    try {
      AppLogger.debug('🔍 Buscando grupos do usuário: $userId');

      return _db
          .collection(_collection)
          .where('memberIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastActivity', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return GroupModel.fromJson({...doc.data(), 'id': doc.id});
            }).toList();
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar grupos do usuário', error: e);
      return Stream.value([]);
    }
  }

  /// Buscar grupo por ID
  static Future<GroupModel?> getGroupById(String groupId) async {
    try {
      AppLogger.debug('🔍 Buscando grupo: $groupId');

      final doc = await _db.collection(_collection).doc(groupId).get();

      if (!doc.exists) {
        AppLogger.warning('⚠️ Grupo não encontrado: $groupId');
        return null;
      }

      return GroupModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao buscar grupo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Adicionar membro ao grupo
  static Future<bool> addMember(String groupId, String userId) async {
    try {
      AppLogger.info('👤 Adicionando membro $userId ao grupo $groupId');

      return await _db.runTransaction((transaction) async {
        final groupRef = _db.collection(_collection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Grupo não encontrado');
        }

        final group = GroupModel.fromJson({...groupDoc.data()!, 'id': groupId});

        // Verificações
        if (group.isMember(userId)) {
          throw Exception('Usuário já é membro do grupo');
        }

        if (group.isFull) {
          throw Exception('Grupo está cheio');
        }

        // Adicionar à lista de membros
        final newMemberIds = [...group.memberIds, userId];
        transaction.update(groupRef, {
          'memberIds': newMemberIds,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        // Criar documento do membro
        await _createMemberDocument(groupId, userId);

        return true;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao adicionar membro',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Remover membro do grupo
  static Future<bool> removeMember(String groupId, String userId) async {
    try {
      AppLogger.info('❌ Removendo membro $userId do grupo $groupId');

      return await _db.runTransaction((transaction) async {
        final groupRef = _db.collection(_collection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Grupo não encontrado');
        }

        final group = GroupModel.fromJson({...groupDoc.data()!, 'id': groupId});

        // Verificar se é membro
        if (!group.isMember(userId)) {
          throw Exception('Usuário não é membro do grupo');
        }

        // Não permitir remoção do criador
        if (group.isCreator(userId)) {
          throw Exception('Criador não pode ser removido');
        }

        // Remover das listas
        final newMemberIds = group.memberIds
            .where((id) => id != userId)
            .toList();
        final newAdminIds = group.adminIds.where((id) => id != userId).toList();

        transaction.update(groupRef, {
          'memberIds': newMemberIds,
          'adminIds': newAdminIds,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        // Remover documento do membro
        await _removeMemberDocument(groupId, userId);

        return true;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao remover membro',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Promover membro a admin
  static Future<bool> promoteToAdmin(
    String groupId,
    String userId,
    String promoterId,
  ) async {
    try {
      AppLogger.info('👑 Promovendo $userId a admin no grupo $groupId');

      return await _db.runTransaction((transaction) async {
        final groupRef = _db.collection(_collection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Grupo não encontrado');
        }

        final group = GroupModel.fromJson({...groupDoc.data()!, 'id': groupId});

        // Verificações
        if (!group.isAdmin(promoterId)) {
          throw Exception('Apenas admins podem promover outros usuários');
        }

        if (!group.isMember(userId)) {
          throw Exception('Usuário não é membro do grupo');
        }

        if (group.isAdmin(userId)) {
          throw Exception('Usuário já é admin');
        }

        // Adicionar à lista de admins
        final newAdminIds = [...group.adminIds, userId];
        transaction.update(groupRef, {
          'adminIds': newAdminIds,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao promover membro',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Atualizar informações do grupo
  static Future<bool> updateGroup(
    String groupId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.info('📝 Atualizando grupo: $groupId');

      // Adicionar timestamp de última atividade
      updates['lastActivity'] = FieldValue.serverTimestamp();

      await _db.collection(_collection).doc(groupId).update(updates);

      AppLogger.info('✅ Grupo atualizado com sucesso');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao atualizar grupo',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Buscar grupos públicos
  static Stream<List<GroupModel>> getPublicGroups({int limit = 20}) {
    try {
      AppLogger.debug('🌍 Buscando grupos públicos');

      return _db
          .collection(_collection)
          .where('privacy', isEqualTo: 'public')
          .where('isActive', isEqualTo: true)
          .orderBy('lastActivity', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return GroupModel.fromJson({...doc.data(), 'id': doc.id});
            }).toList();
          });
    } catch (e) {
      AppLogger.error('❌ Erro ao buscar grupos públicos', error: e);
      return Stream.value([]);
    }
  }

  /// Gerar código de convite único
  static Future<String?> generateInviteCode(String groupId) async {
    try {
      AppLogger.info('🎫 Gerando código de convite para grupo: $groupId');

      final inviteCode = _generateRandomCode();

      await _db.collection(_collection).doc(groupId).update({
        'inviteCode': inviteCode,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Código gerado: $inviteCode');
      return inviteCode;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao gerar código de convite',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Entrar no grupo via código de convite
  static Future<String?> joinByInviteCode(
    String inviteCode,
    String userId,
  ) async {
    try {
      AppLogger.info('🎫 Entrando no grupo via código: $inviteCode');

      final querySnapshot = await _db
          .collection(_collection)
          .where('inviteCode', isEqualTo: inviteCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Código de convite inválido');
      }

      final groupDoc = querySnapshot.docs.first;
      final groupId = groupDoc.id;

      // Adicionar membro
      final success = await addMember(groupId, userId);

      if (success) {
        AppLogger.info('✅ Usuário $userId entrou no grupo $groupId');
        return groupId;
      } else {
        throw Exception('Não foi possível entrar no grupo');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao entrar via código',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Desativar grupo (soft delete)
  static Future<bool> deactivateGroup(String groupId, String userId) async {
    try {
      AppLogger.info('🗑️ Desativando grupo: $groupId');

      return await _db.runTransaction((transaction) async {
        final groupRef = _db.collection(_collection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Grupo não encontrado');
        }

        final group = GroupModel.fromJson({...groupDoc.data()!, 'id': groupId});

        // Apenas criador pode desativar
        if (!group.isCreator(userId)) {
          throw Exception('Apenas o criador pode desativar o grupo');
        }

        transaction.update(groupRef, {
          'isActive': false,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Erro ao desativar grupo',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Criar documento de membro na subcoleção
  static Future<void> _createMemberDocument(
    String groupId,
    String userId, {
    bool isCreator = false,
  }) async {
    await _db
        .collection(_collection)
        .doc(groupId)
        .collection(_membersSubcollection)
        .doc(userId)
        .set({
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
          'isCreator': isCreator,
          'isAdmin': isCreator,
        });
  }

  /// Remover documento de membro da subcoleção
  static Future<void> _removeMemberDocument(
    String groupId,
    String userId,
  ) async {
    await _db
        .collection(_collection)
        .doc(groupId)
        .collection(_membersSubcollection)
        .doc(userId)
        .delete();
  }

  /// Gerar código aleatório de 6 caracteres
  static String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
