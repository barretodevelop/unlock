// lib/providers/user_provider.dart - SECURE REFACTOR
// ✅ SEGURANÇA: Substitui operações diretas por validadas
import 'dart:async'; // Add this for StreamSubscription

import 'package:firebase_auth/firebase_auth.dart'; // Avoid conflict with your User model if any
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/auth_service.dart'; // Import AuthService
import 'package:unlock/services/firestore_service.dart';
import 'package:unlock/services/security/secure_firestore_service.dart'
    show SecureFirestoreService;

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  // The UserNotifier will now internally listen to auth state changes.
  // It still needs FirestoreService for non-secure updates like XP.
  return UserNotifier(FirestoreService());
});

class UserNotifier extends StateNotifier<UserModel?> {
  final FirestoreService _firestoreService;
  StreamSubscription<User?>? _authStateSubscription;

  UserNotifier(this._firestoreService) : super(null) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authStateSubscription = AuthService.authStateChanges.listen(
      (firebaseUser) async {
        if (kDebugMode) {
          print(
            '[UserNotifier] Auth state changed. Firebase user: ${firebaseUser?.uid}',
          );
        }
        if (firebaseUser != null) {
          try {
            // Use AuthService.getOrCreateUserInFirestore to ensure user data is in Firestore
            // and get the UserModel.
            final userModel = await AuthService.getOrCreateUserInFirestore(
              firebaseUser,
            );
            if (kDebugMode) {
              print(
                '[UserNotifier] Fetched/Created UserModel: ${userModel?.uid} for ${firebaseUser.uid}',
              );
            }
            state = userModel;
          } catch (e, s) {
            if (kDebugMode) {
              print(
                '[UserNotifier] Error fetching/creating user from Firestore: $e\n$s',
              );
            }
            state = null; // Or handle error state appropriately
          }
        } else {
          if (kDebugMode) {
            print(
              '[UserNotifier] Firebase user is null. Setting state to null.',
            );
          }
          state = null;
        }
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print(
            '[UserNotifier] Error in authStateChanges stream: $error\n$stackTrace',
          );
        }
        state = null; // Clear user state on auth stream error
      },
    );
  }

  void setUser(UserModel? user) {
    state = user;
  }

  // ✅ SEGURO: Operação de coins agora usa validação server-side
  Future<void> updateCoins(int newCoinAmount, {String? reason}) async {
    if (state == null) {
      throw Exception('User not logged in');
    }

    final currentCoins = state!.coins;
    final coinsDelta = newCoinAmount - currentCoins;

    try {
      // ✅ USA OPERAÇÃO SEGURA em vez de FirestoreService direto
      final success = await SecureFirestoreService.updateUserEconomy(
        userId: state!.uid,
        coinsDelta: coinsDelta,
        reason: reason ?? 'Manual coins update',
      );

      if (success) {
        // ✅ Atualiza estado local apenas APÓS confirmação server-side
        state = state!.copyWith(coins: newCoinAmount);
        if (kDebugMode) {
          print(
            '✅ UserProvider: Coins updated securely: $currentCoins → $newCoinAmount',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider: Secure coins update failed: $e');
      }
    }
  }

  // ✅ SEGURO: Operação de gems com validação
  Future<void> updateGems(int newGemAmount, {String? reason}) async {
    if (state == null) {
      throw Exception('User not logged in');
    }

    final currentGems = state!.gems;
    final gemsDelta = newGemAmount - currentGems;

    try {
      final success = await SecureFirestoreService.updateUserEconomy(
        userId: state!.uid,
        gemsDelta: gemsDelta,
        reason: reason ?? 'Manual gems update',
      );

      if (success) {
        state = state!.copyWith(gems: newGemAmount);
        if (kDebugMode) {
          print(
            '✅ UserProvider: Gems updated securely: $currentGems → $newGemAmount',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider: Secure gems update failed: $e');
      }
    }
  }

  // ✅ NOVO: Método seguro para completar missões
  Future<void> completeMission(int missionId, int rewardCoins) async {
    if (state == null) {
      throw Exception('User not logged in');
    }

    try {
      final success = await SecureFirestoreService.completeMission(
        userId: state!.uid,
        missionId: missionId,
        rewardCoins: rewardCoins,
      );

      if (success) {
        state = state!.copyWith(coins: state!.coins + rewardCoins);
        if (kDebugMode) {
          print(
            '✅ UserProvider: Mission $missionId completed for $rewardCoins coins',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserProvider: Mission completion failed: $e');
      }
      rethrow;
    }
  }

  // ✅ MANTIDO: Operações não-econômicas usam método original
  Future<void> updateXP(int newXp) async {
    if (state != null) {
      final newLevel = (newXp / 100).floor() + 1;
      try {
        await _firestoreService.updateUser(state!.uid, {
          'xp': newXp,
          'level': newLevel,
        });
        state = state!.copyWith(xp: newXp, level: newLevel);
        if (kDebugMode) {
          print('✅ UserProvider: XP updated: $newXp (Level $newLevel)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ UserProvider: XP update failed: $e');
        }
        rethrow;
      }
    }
  }

  Future<void> updateAIConfig(Map<String, dynamic> config) async {
    if (state != null) {
      try {
        await _firestoreService.updateUser(state!.uid, {'aiConfig': config});
        state = state!.copyWith(aiConfig: config);
        if (kDebugMode) {
          print('✅ UserProvider: AI config updated');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ UserProvider: AI config update failed: $e');
        }
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    if (kDebugMode) {
      print('[UserNotifier] Disposed and cancelled auth state subscription.');
    }
    super.dispose();
  }
}
