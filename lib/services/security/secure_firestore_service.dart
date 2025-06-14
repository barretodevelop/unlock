// lib/services/secure_firestore_service.dart
// Server-side validation layer mantendo funcionalidades existentes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/firestore_service.dart';

class SecureFirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _baseService = FirestoreService();

  // ========================
  // SECURE USER OPERATIONS
  // ========================

  /// Operação segura para atualizar economia do usuário
  /// Valida transação antes de executar
  static Future<bool> updateUserEconomy({
    required String userId,
    int? coinsDelta,
    int? gemsDelta,
    required String reason,
    String? transactionId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser?.uid != userId) {
      throw SecurityException(
        'Usuário não pode alterar dados de outros usuários',
      );
    }

    try {
      // Usar transaction para consistência
      return await _db.runTransaction<bool>((transaction) async {
        final userRef = _db.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Usuário não encontrado');
        }

        final userData = userDoc.data()!;
        final currentCoins = userData['coins'] as int? ?? 0;
        final currentGems = userData['gems'] as int? ?? 0;

        // Calcular novos valores
        final newCoins = currentCoins + (coinsDelta ?? 0);
        final newGems = currentGems + (gemsDelta ?? 0);

        // Validações de negócio
        if (newCoins < 0) {
          throw InsufficientFundsException('Coins insuficientes');
        }
        if (newGems < 0) {
          throw InsufficientFundsException('Gemas insuficientes');
        }

        // Validar limites de incremento (anti-cheat)
        if (coinsDelta != null && coinsDelta > 200) {
          throw SecurityException('Incremento de coins muito alto');
        }
        if (gemsDelta != null && gemsDelta > 50) {
          throw SecurityException('Incremento de gemas muito alto');
        }

        // Log da transação para auditoria
        await _logEconomyTransaction(
          transaction: transaction,
          userId: userId,
          coinsDelta: coinsDelta,
          gemsDelta: gemsDelta,
          reason: reason,
          transactionId: transactionId,
        );

        // Executar update
        transaction.update(userRef, {
          'coins': newCoins,
          'gems': newGems,
          'lastEconomyUpdate': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print(
            '✅ [SecureFirestore] Economy update: User $userId, Coins: $currentCoins→$newCoins, Gems: $currentGems→$newGems, Reason: $reason',
          );
        }
        return true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureFirestore] Economy update failed: $e');
      }
      rethrow;
    }
  }

  /// Operação segura para recompensar missão
  static Future<bool> completeMission({
    required String userId,
    required int missionId,
    required int rewardCoins,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser?.uid != userId) {
      throw SecurityException('Usuário não autorizado');
    }

    // Validar reward (anti-cheat)
    if (rewardCoins > 200) {
      throw SecurityException('Recompensa muito alta');
    }

    try {
      return await updateUserEconomy(
        userId: userId,
        coinsDelta: rewardCoins,
        reason: 'Mission completion: $missionId',
        transactionId: 'mission_$missionId',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SecureFirestore] Mission completion failed: $e');
      }
      rethrow;
    }
  }

  /// Log transações de economia para auditoria
  static Future<void> _logEconomyTransaction({
    required Transaction transaction,
    required String userId,
    int? coinsDelta,
    int? gemsDelta,
    required String reason,
    String? transactionId,
  }) async {
    final logRef = _db.collection('audit_logs').doc();
    transaction.set(logRef, {
      'type': 'economy_update',
      'userId': userId,
      'coinsDelta': coinsDelta,
      'gemsDelta': gemsDelta,
      'reason': reason,
      'transactionId': transactionId,
      'timestamp': FieldValue.serverTimestamp(),
      'userAgent': 'Flutter App',
    });
  }

  ///// Log transações de compra para auditoria
  // static Future<void> _logPurchaseTransaction({
  //   required Transaction transaction,
  //   required String userId,
  //   required ItemModel item,
  //   required int quantity,
  //   required int totalCost,
  // }) async {
  //   final logRef = _db.collection('audit_logs').doc();
  //   transaction.set(logRef, {
  //     'type': 'item_purchase',
  //     'userId': userId,
  //     'itemId': item.id,
  //     'itemName': item.name,
  //     'quantity': quantity,
  //     'unitPrice': item.cost,
  //     'totalCost': totalCost,
  //     'timestamp': FieldValue.serverTimestamp(),
  //   });
  // }

  // ========================
  // READONLY OPERATIONS (usando serviço existente)
  // ========================

  static Future<UserModel?> getUser(String uid) => _baseService.getUser(uid);
}

// ========================
// CUSTOM EXCEPTIONS
// ========================

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}

class InsufficientFundsException implements Exception {
  final String message;
  InsufficientFundsException(this.message);
  @override
  String toString() => 'InsufficientFundsException: $message';
}

class BusinessRuleException implements Exception {
  final String message;
  BusinessRuleException(this.message);
  @override
  String toString() => 'BusinessRuleException: $message';
}
