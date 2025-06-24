// lib/services/firestore_currency_extension.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/services/firestore_service.dart';

/// Extensão do FirestoreService para operações de moeda
extension FirestoreCurrencyExtension on FirestoreService {
  /// Atualiza as moedas do usuário e registra a transação
  Future<void> updateUserCurrency({
    required String userId,
    required int newCoins,
    required int newGems,
    required CurrencyTransaction transaction,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Atualiza o documento do usuário
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      batch.update(userRef, {
        'coins': newCoins,
        'gems': newGems,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Adiciona a transação ao histórico
      final transactionRef = FirebaseFirestore.instance
          .collection('currency_transactions')
          .doc(transaction.id);

      batch.set(transactionRef, transaction.toJson());

      // Executa a transação atomic
      await batch.commit();

      AppLogger.info(
        '✅ Currency update completed',
        data: {
          'userId': userId,
          'newCoins': newCoins,
          'newGems': newGems,
          'transactionId': transaction.id,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to update user currency',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Stream para observar transações de moeda de um usuário
  Stream<List<CurrencyTransaction>> getCurrencyTransactionsStream(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('currency_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CurrencyTransaction.fromJson({'id': doc.id, ...doc.data()});
          }).toList();
        })
        .handleError((error, stackTrace) {
          AppLogger.error(
            '❌ Error in currency transactions stream',
            error: error,
            stackTrace: stackTrace,
          );
          return <CurrencyTransaction>[];
        });
  }

  /// Busca transações de moeda por período
  Future<List<CurrencyTransaction>> getCurrencyTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    CurrencyType? type,
    CurrencyReason? reason,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('currency_transactions')
          .where('userId', isEqualTo: userId);

      // Filtros opcionais
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (reason != null) {
        query = query.where('reason', isEqualTo: reason.name);
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return CurrencyTransaction.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to get currency transactions',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Busca estatísticas de moeda do usuário
  Future<Map<String, dynamic>> getCurrencyStats(String userId) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Transações da semana
      final weekTransactions = await getCurrencyTransactions(
        userId: userId,
        startDate: lastWeek,
        limit: 100,
      );

      // Transações do mês
      final monthTransactions = await getCurrencyTransactions(
        userId: userId,
        startDate: lastMonth,
        limit: 200,
      );

      // Cálculos
      final weekCoinsEarned = weekTransactions
          .where((t) => t.type == CurrencyType.coins && t.amount > 0)
          .fold(0, (sum, t) => sum + t.amount);

      final weekGemsEarned = weekTransactions
          .where((t) => t.type == CurrencyType.gems && t.amount > 0)
          .fold(0, (sum, t) => sum + t.amount);

      final monthCoinsEarned = monthTransactions
          .where((t) => t.type == CurrencyType.coins && t.amount > 0)
          .fold(0, (sum, t) => sum + t.amount);

      final monthGemsEarned = monthTransactions
          .where((t) => t.type == CurrencyType.gems && t.amount > 0)
          .fold(0, (sum, t) => sum + t.amount);

      final weekCoinsSpent = weekTransactions
          .where((t) => t.type == CurrencyType.coins && t.amount < 0)
          .fold(0, (sum, t) => sum + t.amount.abs());

      final weekGemsSpent = weekTransactions
          .where((t) => t.type == CurrencyType.gems && t.amount < 0)
          .fold(0, (sum, t) => sum + t.amount.abs());

      return {
        'week': {
          'coinsEarned': weekCoinsEarned,
          'gemsEarned': weekGemsEarned,
          'coinsSpent': weekCoinsSpent,
          'gemsSpent': weekGemsSpent,
          'netCoins': weekCoinsEarned - weekCoinsSpent,
          'netGems': weekGemsEarned - weekGemsSpent,
          'totalTransactions': weekTransactions.length,
        },
        'month': {
          'coinsEarned': monthCoinsEarned,
          'gemsEarned': monthGemsEarned,
          'totalTransactions': monthTransactions.length,
        },
        'topReasons': _getTopReasons(monthTransactions),
        'lastTransaction': monthTransactions.isNotEmpty
            ? monthTransactions.first.toJson()
            : null,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to get currency stats',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Calcula as principais razões para ganhar moedas
  Map<String, int> _getTopReasons(List<CurrencyTransaction> transactions) {
    final reasonCounts = <String, int>{};

    for (final transaction in transactions) {
      if (transaction.amount > 0) {
        // Apenas recompensas
        final reason = transaction.reason.description;
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }
    }

    // Ordena por frequência
    final sortedEntries = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(5));
  }

  /// Gera um ID único para transações
  String generateId() {
    return FirebaseFirestore.instance.collection('temp').doc().id;
  }

  /// Verifica a integridade das moedas do usuário
  Future<bool> verifyCurrencyIntegrity(String userId) async {
    try {
      // Busca o usuário atual
      final user = await getUser(userId);
      if (user == null) return false;

      // Busca todas as transações
      final allTransactions = await getCurrencyTransactions(
        userId: userId,
        limit: 1000,
      );

      // Calcula o total baseado nas transações
      int calculatedCoins = 200; // Bônus inicial
      int calculatedGems = 20; // Bônus inicial

      for (final transaction in allTransactions.reversed) {
        switch (transaction.type) {
          case CurrencyType.coins:
            calculatedCoins += transaction.amount;
            break;
          case CurrencyType.gems:
            calculatedGems += transaction.amount;
            break;
        }
      }

      // Compara com os valores atuais
      final isValid =
          user.coins == calculatedCoins && user.gems == calculatedGems;

      if (!isValid) {
        AppLogger.warning(
          '⚠️ Currency integrity check failed',
          data: {
            'userId': userId,
            'stored': {'coins': user.coins, 'gems': user.gems},
            'calculated': {'coins': calculatedCoins, 'gems': calculatedGems},
            'transactionCount': allTransactions.length,
          },
        );
      }

      return isValid;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Currency integrity check error',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Corrige inconsistências nas moedas (uso administrativo)
  Future<void> fixCurrencyIntegrity(String userId) async {
    try {
      // Busca todas as transações
      final allTransactions = await getCurrencyTransactions(
        userId: userId,
        limit: 1000,
      );

      // Recalcula os totais
      int correctCoins = 200; // Bônus inicial
      int correctGems = 20; // Bônus inicial

      for (final transaction in allTransactions.reversed) {
        switch (transaction.type) {
          case CurrencyType.coins:
            correctCoins += transaction.amount;
            break;
          case CurrencyType.gems:
            correctGems += transaction.amount;
            break;
        }
      }

      // Atualiza diretamente no Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'coins': correctCoins,
        'gems': correctGems,
        'lastCurrencyFix': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        '✅ Currency integrity fixed',
        data: {
          'userId': userId,
          'fixedCoins': correctCoins,
          'fixedGems': correctGems,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to fix currency integrity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
