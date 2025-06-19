// lib/features/profile/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';

/// Estado do perfil
class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final bool isEditing;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isEditing = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isEditing,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ProfileState(user: ${user?.uid}, isLoading: $isLoading, isEditing: $isEditing, error: $error)';
  }
}

/// Provider para gerenciar estado do perfil
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState()) {
    // Escutar mudanças no AuthProvider
    _ref.listen<AuthState>(authProvider, (previous, next) {
      _onAuthStateChanged(next);
    });

    // Inicializar com dados atuais do auth
    final authState = _ref.read(authProvider);
    _onAuthStateChanged(authState);
  }

  /// Reagir a mudanças no estado de autenticação
  void _onAuthStateChanged(AuthState authState) {
    if (authState.user != null) {
      state = state.copyWith(
        user: authState.user,
        isLoading: false,
        error: null,
      );
      AppLogger.debug(
        '👤 ProfileNotifier: Usuário atualizado',
        data: {'uid': authState.user!.uid},
      );
    } else {
      state = const ProfileState();
      AppLogger.debug('👤 ProfileNotifier: Usuário removido');
    }
  }

  /// Entrar no modo de edição
  void startEditing() {
    if (state.user == null) return;

    state = state.copyWith(isEditing: true);
    AppLogger.debug('✏️ ProfileNotifier: Modo de edição ativado');
  }

  /// Cancelar edição
  void cancelEditing() {
    state = state.copyWith(isEditing: false, error: null);
    AppLogger.debug('❌ ProfileNotifier: Edição cancelada');
  }

  /// Atualizar avatar
  Future<void> updateAvatar(String newAvatar) async {
    if (state.user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      AppLogger.info('🎭 ProfileNotifier: Atualizando avatar');

      // Atualizar o modelo local
      final updatedUser = state.user!.copyWith(avatar: newAvatar);

      // Atualizar no AuthProvider (que salvará no Firestore)
      await _ref.read(authProvider.notifier).updateUserData(updatedUser);

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        isEditing: false,
      );

      AppLogger.info('✅ ProfileNotifier: Avatar atualizado');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar avatar: $e',
      );
      AppLogger.error('❌ ProfileNotifier: Erro ao atualizar avatar: $e');
    }
  }

  /// Atualizar codinome
  Future<void> updateCodinome(String newCodinome) async {
    if (state.user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      AppLogger.info('📝 ProfileNotifier: Atualizando codinome');

      final updatedUser = state.user!.copyWith(codinome: newCodinome);

      await _ref.read(authProvider.notifier).updateUserData(updatedUser);

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        isEditing: false,
      );

      AppLogger.info('✅ ProfileNotifier: Codinome atualizado');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar codinome: $e',
      );
      AppLogger.error('❌ ProfileNotifier: Erro ao atualizar codinome: $e');
    }
  }

  /// Atualizar interesses
  Future<void> updateInteresses(List<String> newInteresses) async {
    if (state.user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      AppLogger.info('🎯 ProfileNotifier: Atualizando interesses');

      final updatedUser = state.user!.copyWith(interesses: newInteresses);

      await _ref.read(authProvider.notifier).updateUserData(updatedUser);

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        isEditing: false,
      );

      AppLogger.info('✅ ProfileNotifier: Interesses atualizados');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar interesses: $e',
      );
      AppLogger.error('❌ ProfileNotifier: Erro ao atualizar interesses: $e');
    }
  }

  /// Refresh dos dados do perfil
  Future<void> refresh() async {
    try {
      AppLogger.info('🔄 ProfileNotifier: Atualizando dados do perfil');

      await _ref.read(authProvider.notifier).refreshUser();

      AppLogger.info('✅ ProfileNotifier: Dados atualizados');
    } catch (e) {
      state = state.copyWith(error: 'Erro ao atualizar dados: $e');
      AppLogger.error('❌ ProfileNotifier: Erro ao refresh: $e');
    }
  }

  /// Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Calcular progresso para próximo nível
  double get progressToNextLevel {
    if (state.user == null) return 0.0;

    final currentXP = state.user!.xp;
    final currentLevel = state.user!.level;

    // Fórmula simples: cada nível precisa de level * 100 XP
    final xpForCurrentLevel = (currentLevel - 1) * 100;
    final xpForNextLevel = currentLevel * 100;

    final progressXP = currentXP - xpForCurrentLevel;
    final totalXPNeeded = xpForNextLevel - xpForCurrentLevel;

    if (totalXPNeeded <= 0) return 1.0;

    return (progressXP / totalXPNeeded).clamp(0.0, 1.0);
  }

  /// XP necessário para próximo nível
  int get xpNeededForNextLevel {
    if (state.user == null) return 0;

    final currentXP = state.user!.xp;
    final currentLevel = state.user!.level;
    final xpForNextLevel = currentLevel * 100;

    return (xpForNextLevel - currentXP).clamp(0, double.infinity).toInt();
  }

  /// Verificar se pode completar onboarding
  bool get canCompleteOnboarding {
    final user = state.user;
    if (user == null) return false;

    return user.codinome?.isNotEmpty == true &&
        user.avatarId?.isNotEmpty == true &&
        user.birthDate != null &&
        user.interesses.length >= 3 &&
        user.relationshipGoal?.isNotEmpty == true;
  }
}
