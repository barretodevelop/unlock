// lib/providers/group_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/group_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/group_service.dart';

// ========== STREAM PROVIDERS ==========

/// Provider para grupos do usuário atual
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return Stream.value([]);
  }
  
  AppLogger.debug('🔄 userGroupsProvider: Carregando grupos do usuário ${authState.user!.uid}');
  return GroupService.getUserGroups(authState.user!.uid);
});

/// Provider para grupos públicos
final publicGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  AppLogger.debug('🔄 publicGroupsProvider: Carregando grupos públicos');
  return GroupService.getPublicGroups();
});

/// Provider para grupo específico por ID
final groupByIdProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  AppLogger.debug('🔄 groupByIdProvider: Carregando grupo $groupId');
  return GroupService.getGroupById(groupId).asStream();
});

// ========== STATE PROVIDERS ==========

/// Estado para ações dos grupos
class GroupActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? lastCreatedGroupId;

  const GroupActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.lastCreatedGroupId,
  });

  GroupActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    String? lastCreatedGroupId,
  }) {
    return GroupActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      lastCreatedGroupId: lastCreatedGroupId ?? this.lastCreatedGroupId,
    );
  }

  /// Reset de mensagens
  GroupActionState clearMessages() {
    return copyWith(error: null, successMessage: null);
  }
}

/// Provider para ações dos grupos
final groupActionProvider = StateNotifierProvider<GroupActionNotifier, GroupActionState>((ref) {
  return GroupActionNotifier(ref);
});

/// Notifier para ações dos grupos
class GroupActionNotifier extends StateNotifier<GroupActionState> {
  final Ref _ref;
  Timer? _messageTimer;

  GroupActionNotifier(this._ref) : super(const GroupActionState());

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  /// Criar novo grupo
  Future<String?> createGroup({
    required String name,
    required String description,
    String? avatar,
    GroupType? type,
    GroupPrivacy? privacy,
    int? maxMembers,
  }) async {
    if (state.isLoading) {
      AppLogger.warning('⚠️ Criação de grupo já em andamento');
      return null;
    }

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _setError('Usuário não autenticado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🎯 Iniciando criação do grupo: $name');

      final group = GroupModel.create(
        name: name,
        description: description,
        creatorId: authState.user!.uid,
        avatar: avatar,
        type: type,
        privacy: privacy,
        maxMembers: maxMembers,
      );

      final groupId = await GroupService.createGroup(group);

      if (groupId != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Grupo "$name" criado com sucesso! 🎉',
          lastCreatedGroupId: groupId,
        );
        
        _clearMessageAfterDelay();
        AppLogger.info('✅ Grupo criado com sucesso: $groupId');
        return groupId;
      } else {
        _setError('Não foi possível criar o grupo');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao criar grupo', error: e);
      _setError('Erro ao criar grupo: ${e.toString()}');
      return null;
    }
  }

  /// Entrar em grupo
  Future<bool> joinGroup(String groupId) async {
    if (state.isLoading) return false;

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _setError('Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('👤 Entrando no grupo: $groupId');

      final success = await GroupService.addMember(groupId, authState.user!.uid);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Você entrou no grupo! 🎉',
        );
        _clearMessageAfterDelay();
        return true;
      } else {
        _setError('Não foi possível entrar no grupo');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao entrar no grupo', error: e);
      _setError('Erro ao entrar no grupo: ${e.toString()}');
      return false;
    }
  }

  /// Sair do grupo
  Future<bool> leaveGroup(String groupId) async {
    if (state.isLoading) return false;

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _setError('Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('❌ Saindo do grupo: $groupId');

      final success = await GroupService.removeMember(groupId, authState.user!.uid);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Você saiu do grupo.',
        );
        _clearMessageAfterDelay();
        return true;
      } else {
        _setError('Não foi possível sair do grupo');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao sair do grupo', error: e);
      _setError('Erro ao sair do grupo: ${e.toString()}');
      return false;
    }
  }

  /// Entrar via código de convite
  Future<String?> joinByInviteCode(String inviteCode) async {
    if (state.isLoading) return null;

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _setError('Usuário não autenticado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🎫 Entrando via código: $inviteCode');

      final groupId = await GroupService.joinByInviteCode(inviteCode, authState.user!.uid);

      if (groupId != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Entrou no grupo com sucesso! 🎉',
        );
        _clearMessageAfterDelay();
        return groupId;
      } else {
        _setError('Código de convite inválido ou expirado');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao entrar via código', error: e);
      _setError('Erro: ${e.toString()}');
      return null;
    }
  }

  /// Gerar código de convite
  Future<String?> generateInviteCode(String groupId) async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('🎫 Gerando código de convite para: $groupId');

      final inviteCode = await GroupService.generateInviteCode(groupId);

      if (inviteCode != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Código gerado: $inviteCode',
        );
        _clearMessageAfterDelay();
        return inviteCode;
      } else {
        _setError('Não foi possível gerar código de convite');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao gerar código', error: e);
      _setError('Erro ao gerar código: ${e.toString()}');
      return null;
    }
  }

  /// Promover membro a admin
  Future<bool> promoteToAdmin(String groupId, String userId) async {
    if (state.isLoading) return false;

    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _setError('Usuário não autenticado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('👑 Promovendo usuário $userId no grupo $groupId');

      final success = await GroupService.promoteToAdmin(groupId, userId, authState.user!.uid);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuário promovido a administrador! 👑',
        );
        _clearMessageAfterDelay();
        return true;
      } else {
        _setError('Não foi possível promover o usuário');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao promover usuário', error: e);
      _setError('Erro: ${e.toString()}');
      return false;
    }
  }

  /// Atualizar grupo
  Future<bool> updateGroup(String groupId, Map<String, dynamic> updates) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      AppLogger.info('📝 Atualizando grupo: $groupId');

      final success = await GroupService.updateGroup(groupId, updates);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Grupo atualizado com sucesso! ✅',
        );
        _clearMessageAfterDelay();
        return true;
      } else {
        _setError('Não foi possível atualizar o grupo');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao atualizar grupo', error: e);
      _setError('Erro ao atualizar: ${e.toString()}');
      return false;
    }
  }

  /// Limpar mensagens manualmente
  void clearMessages() {
    state = state.clearMessages();
    _messageTimer?.cancel();
  }

  // ========== MÉTODOS PRIVADOS ==========

  void _setError(String message) {
    state = state.copyWith(isLoading: false, error: message);
    _clearMessageAfterDelay();
  }

  void _clearMessageAfterDelay() {
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        state = state.clearMessages();
      }
    });
  }
}

// ========== PROVIDERS UTILITÁRIOS ==========

/// Provider para verificar se usuário está em um grupo
final isUserInGroupProvider = Provider.family<bool, String>((ref, groupId) {
  final userGroups = ref.watch(userGroupsProvider);
  
  return userGroups.when(
    data: (groups) => groups.any((group) => group.id == groupId),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider para contar grupos do usuário
final userGroupsCountProvider = Provider<int>((ref) {
  final userGroups = ref.watch(userGroupsProvider);
  
  return userGroups.when(
    data: (groups) => groups.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});