// lib/providers/user_provider.dart - Versão Corrigida com Logs
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/auth_service.dart';
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/security/secure_firestore_service.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier(FirestoreService());
});

class UserNotifier extends StateNotifier<UserModel?> {
  final FirestoreService _firestoreService;
  StreamSubscription<User?>? _authStateSubscription;

  UserNotifier(this._firestoreService) : super(null) {
    AppLogger.debug('🎬 UserNotifier: Inicializando...');
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    AppLogger.debug('👂 UserNotifier: Escutando mudanças de auth...');

    _authStateSubscription = AuthService.authStateChanges.listen(
      (firebaseUser) async {
        AppLogger.debug(
          '🔄 UserNotifier: Auth state changed',
          data: {
            'hasUser': firebaseUser != null,
            'userUid': firebaseUser?.uid ?? 'null',
          },
        );

        if (firebaseUser != null) {
          try {
            AppLogger.debug(
              '📥 UserNotifier: Carregando dados do usuário...',
              data: {'uid': firebaseUser.uid},
            );

            final userModel = await AuthService.getOrCreateUserInFirestore(
              firebaseUser,
            );

            if (userModel != null) {
              AppLogger.debug(
                '✅ UserNotifier: UserModel carregado',
                data: {
                  'uid': userModel.uid,
                  'username': userModel.username,
                  'level': userModel.level,
                  'coins': userModel.coins,
                  'gems': userModel.gems,
                  'xp': userModel.xp,
                },
              );
              state = userModel;
            } else {
              AppLogger.warning('⚠️ UserNotifier: UserModel retornou null');
              state = null;
            }
          } catch (e) {
            AppLogger.error(
              'UserNotifier: Erro ao carregar usuário do Firestore: $e',
            );
            state = null;
          }
        } else {
          AppLogger.debug(
            '👤 UserNotifier: Firebase user é null, limpando state',
          );
          state = null;
        }
      },
      onError: (error, stackTrace) {
        AppLogger.error(
          'UserNotifier: Erro no stream de authStateChanges: $error',
        );
        state = null;
      },
    );
  }

  void setUser(UserModel? user) {
    AppLogger.debug(
      '👤 UserNotifier: setUser chamado',
      data: {
        'hasUser': user != null,
        'userUid': user?.uid ?? 'null',
        'username': user?.username ?? 'null',
      },
    );
    state = user;
  }

  // ✅ SEGURO: Operação de coins com validação server-side
  Future<void> updateCoins(int newCoinAmount, {String? reason}) async {
    if (state == null) {
      AppLogger.warning('⚠️ UserNotifier: updateCoins - usuário não logado');
      throw Exception('User not logged in');
    }

    final currentCoins = state!.coins;
    final coinsDelta = newCoinAmount - currentCoins;

    AppLogger.info(
      '💰 UserNotifier: Atualizando coins',
      data: {
        'uid': state!.uid,
        'currentCoins': currentCoins,
        'newCoinAmount': newCoinAmount,
        'coinsDelta': coinsDelta,
        'reason': reason ?? 'Manual coins update',
      },
    );

    try {
      // Usar operação segura
      final success = await SecureFirestoreService.updateUserEconomy(
        userId: state!.uid,
        coinsDelta: coinsDelta,
        reason: reason ?? 'Manual coins update',
      );

      if (success) {
        // Atualizar estado local apenas APÓS confirmação server-side
        final updatedUser = state!.copyWith(coins: newCoinAmount);
        state = updatedUser;

        AppLogger.info(
          '✅ UserNotifier: Coins atualizados com sucesso',
          data: {
            'uid': state!.uid,
            'oldCoins': currentCoins,
            'newCoins': newCoinAmount,
            'delta': coinsDelta,
          },
        );
      } else {
        AppLogger.warning(
          '⚠️ UserNotifier: Falha na atualização segura de coins',
        );
      }
    } catch (e) {
      AppLogger.error(
        '❌ UserNotifier: Erro na atualização segura de coins: $e',
      );
      rethrow;
    }
  }

  // ✅ SEGURO: Operação de gems com validação
  Future<void> updateGems(int newGemAmount, {String? reason}) async {
    if (state == null) {
      AppLogger.warning('⚠️ UserNotifier: updateGems - usuário não logado');
      throw Exception('User not logged in');
    }

    final currentGems = state!.gems;
    final gemsDelta = newGemAmount - currentGems;

    AppLogger.info(
      '💎 UserNotifier: Atualizando gems',
      data: {
        'uid': state!.uid,
        'currentGems': currentGems,
        'newGemAmount': newGemAmount,
        'gemsDelta': gemsDelta,
        'reason': reason ?? 'Manual gems update',
      },
    );

    try {
      final success = await SecureFirestoreService.updateUserEconomy(
        userId: state!.uid,
        gemsDelta: gemsDelta,
        reason: reason ?? 'Manual gems update',
      );

      if (success) {
        final updatedUser = state!.copyWith(gems: newGemAmount);
        state = updatedUser;

        AppLogger.info(
          '✅ UserNotifier: Gems atualizadas com sucesso',
          data: {
            'uid': state!.uid,
            'oldGems': currentGems,
            'newGems': newGemAmount,
            'delta': gemsDelta,
          },
        );
      } else {
        AppLogger.warning(
          '⚠️ UserNotifier: Falha na atualização segura de gems',
        );
      }
    } catch (e) {
      AppLogger.error('❌ UserNotifier: Erro na atualização segura de gems: $e');
      rethrow;
    }
  }

  // ✅ NOVO: Método seguro para completar missões
  Future<void> completeMission(int missionId, int rewardCoins) async {
    if (state == null) {
      AppLogger.warning(
        '⚠️ UserNotifier: completeMission - usuário não logado',
      );
      throw Exception('User not logged in');
    }

    AppLogger.missions(
      '🎯 UserNotifier: Completando missão',
      data: {
        'uid': state!.uid,
        'missionId': missionId,
        'rewardCoins': rewardCoins,
        'currentCoins': state!.coins,
      },
    );

    try {
      final success = await SecureFirestoreService.completeMission(
        userId: state!.uid,
        missionId: missionId,
        rewardCoins: rewardCoins,
      );

      if (success) {
        final newCoins = state!.coins + rewardCoins;
        final updatedUser = state!.copyWith(coins: newCoins);
        state = updatedUser;

        AppLogger.missions(
          '✅ UserNotifier: Missão completada',
          data: {
            'uid': state!.uid,
            'missionId': missionId,
            'rewardCoins': rewardCoins,
            'newCoins': newCoins,
          },
        );
      } else {
        AppLogger.warning('⚠️ UserNotifier: Falha ao completar missão');
      }
    } catch (e) {
      AppLogger.error('❌ UserNotifier: Erro ao completar missão: $e');
      rethrow;
    }
  }

  // ✅ MANTIDO: Operações não-econômicas usam método original
  Future<void> updateXP(int newXp) async {
    if (state == null) {
      AppLogger.warning('⚠️ UserNotifier: updateXP - usuário não logado');
      return;
    }

    final currentXp = state!.xp;
    final currentLevel = state!.level;
    final newLevel = (newXp / 100).floor() + 1;
    final leveledUp = newLevel > currentLevel;

    AppLogger.info(
      '⭐ UserNotifier: Atualizando XP',
      data: {
        'uid': state!.uid,
        'currentXp': currentXp,
        'newXp': newXp,
        'currentLevel': currentLevel,
        'newLevel': newLevel,
        'leveledUp': leveledUp,
      },
    );

    try {
      await _firestoreService.updateUser(state!.uid, {
        'xp': newXp,
        'level': newLevel,
      });

      final updatedUser = state!.copyWith(xp: newXp, level: newLevel);
      state = updatedUser;

      if (leveledUp) {
        AppLogger.info(
          '🎉 UserNotifier: Level up!',
          data: {
            'uid': state!.uid,
            'oldLevel': currentLevel,
            'newLevel': newLevel,
            'xp': newXp,
          },
        );
      } else {
        AppLogger.debug(
          '✅ UserNotifier: XP atualizado',
          data: {'uid': state!.uid, 'xp': newXp, 'level': newLevel},
        );
      }
    } catch (e) {
      AppLogger.error('❌ UserNotifier: Erro na atualização de XP: $e');
      rethrow;
    }
  }

  Future<void> updateAIConfig(Map<String, dynamic> config) async {
    if (state == null) {
      AppLogger.warning('⚠️ UserNotifier: updateAIConfig - usuário não logado');
      return;
    }

    AppLogger.debug(
      '🤖 UserNotifier: Atualizando config AI',
      data: {'uid': state!.uid, 'configKeys': config.keys.toList()},
    );

    try {
      await _firestoreService.updateUser(state!.uid, {'aiConfig': config});

      final updatedUser = state!.copyWith(aiConfig: config);
      state = updatedUser;

      AppLogger.debug(
        '✅ UserNotifier: AI config atualizado',
        data: {'uid': state!.uid},
      );
    } catch (e) {
      AppLogger.error('❌ UserNotifier: Erro na atualização de AI config: $e');
      rethrow;
    }
  }

  // Métodos utilitários
  void logCurrentState() {
    if (state != null) {
      AppLogger.debug(
        '👤 UserNotifier: Estado atual',
        data: {
          'uid': state!.uid,
          'username': state!.username,
          'level': state!.level,
          'xp': state!.xp,
          'coins': state!.coins,
          'gems': state!.gems,
          'email': state!.email,
        },
      );
    } else {
      AppLogger.debug('👤 UserNotifier: Estado atual - sem usuário');
    }
  }

  @override
  void dispose() {
    AppLogger.debug('🧹 UserNotifier: Disposing...');
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
