// lib/providers/currency_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/firestore_service.dart';

/// Provider para gerenciar o estado das moedas do usuário
final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>(
  (ref) {
    final authState = ref.watch(authProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);

    return CurrencyNotifier(
      firestoreService: firestoreService,
      userId: authState.user?.uid,
      ref: ref,
    );
  },
);

/// Provider para histórico de transações
final currencyTransactionsProvider =
    StreamProvider.family<List<CurrencyTransaction>, String>((ref, userId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getCurrencyTransactionsStream(userId);
    });

/// Provider para verificar se pode gastar uma quantidade específica
final canAffordProvider =
    Provider.family<bool, ({int amount, CurrencyType type})>((ref, params) {
      final currencyState = ref.watch(currencyProvider);
      return currencyState.canAfford(params.amount, params.type);
    });

/// Notifier para gerenciar operações de moeda
class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final FirestoreService _firestoreService;
  final String? _userId;
  final Ref _ref;
  Timer? _syncTimer;

  CurrencyNotifier({
    required FirestoreService firestoreService,
    required String? userId,
    required Ref ref,
  }) : _firestoreService = firestoreService,
       _userId = userId,
       _ref = ref,
       super(CurrencyState.initial()) {
    if (_userId != null) {
      _initializeUserCurrency();
      _startPeriodicSync();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Inicializa as moedas do usuário
  Future<void> _initializeUserCurrency() async {
    if (_userId == null) return;

    try {
      state = state.loading();

      final user = await _firestoreService.getUser(_userId!);
      if (user != null) {
        state = state.withBalances(user.coins, user.gems);
        AppLogger.info(
          '💰 Currency initialized',
          data: {'userId': _userId, 'coins': user.coins, 'gems': user.gems},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize currency',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.withError('Erro ao carregar moedas');
    }
  }

  /// Sincronização periódica para evitar inconsistências
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_userId != null) {
        _syncWithFirestore();
      }
    });
  }

  /// Sincroniza com Firestore
  Future<void> _syncWithFirestore() async {
    if (_userId == null) return;

    try {
      final user = await _firestoreService.getUser(_userId!);
      if (user != null && mounted) {
        // Só atualiza se houver diferença significativa
        if (user.coins != state.coins || user.gems != state.gems) {
          state = state.withBalances(user.coins, user.gems);
          AppLogger.debug('🔄 Currency synced from Firestore');
        }
      }
    } catch (e) {
      AppLogger.warning('⚠️ Currency sync failed', error: e);
    }
  }

  /// Adiciona moedas ao usuário
  Future<bool> addCoins(int amount, String reason, {String? gameId}) async {
    return await _addCurrency(
      amount: amount,
      type: CurrencyType.coins,
      reason: CurrencyReason.values.firstWhere(
        (r) => r.name == reason.replaceAll(' ', '').toLowerCase(),
        orElse: () => CurrencyReason.unknown,
      ),
      gameId: gameId,
    );
  }

  /// Adiciona gemas ao usuário
  Future<bool> addGems(int amount, String reason, {String? gameId}) async {
    return await _addCurrency(
      amount: amount,
      type: CurrencyType.gems,
      reason: CurrencyReason.values.firstWhere(
        (r) => r.name == reason.replaceAll(' ', '').toLowerCase(),
        orElse: () => CurrencyReason.unknown,
      ),
      gameId: gameId,
    );
  }

  /// Remove moedas do usuário (para compras)
  Future<bool> spendCoins(int amount, String reason, {String? gameId}) async {
    if (!state.canAfford(amount, CurrencyType.coins)) {
      AppLogger.warning(
        '💸 Insufficient coins',
        data: {'requested': amount, 'available': state.coins},
      );
      return false;
    }

    return await _addCurrency(
      amount: -amount,
      type: CurrencyType.coins,
      reason: CurrencyReason.values.firstWhere(
        (r) => r.name == reason.replaceAll(' ', '').toLowerCase(),
        orElse: () => CurrencyReason.powerupPurchased,
      ),
      gameId: gameId,
    );
  }

  /// Remove gemas do usuário (para compras premium)
  Future<bool> spendGems(int amount, String reason, {String? gameId}) async {
    if (!state.canAfford(amount, CurrencyType.gems)) {
      AppLogger.warning(
        '💎 Insufficient gems',
        data: {'requested': amount, 'available': state.gems},
      );
      return false;
    }

    return await _addCurrency(
      amount: -amount,
      type: CurrencyType.gems,
      reason: CurrencyReason.values.firstWhere(
        (r) => r.name == reason.replaceAll(' ', '').toLowerCase(),
        orElse: () => CurrencyReason.powerupPurchased,
      ),
      gameId: gameId,
    );
  }

  /// Método principal para adicionar/remover moedas
  Future<bool> _addCurrency({
    required int amount,
    required CurrencyType type,
    required CurrencyReason reason,
    String? gameId,
  }) async {
    if (_userId == null) {
      AppLogger.warning('❌ No user ID for currency transaction');
      return false;
    }

    try {
      state = state.loading();

      // Calcula novos valores
      int newCoins = state.coins;
      int newGems = state.gems;

      switch (type) {
        case CurrencyType.coins:
          newCoins = (state.coins + amount).clamp(0, 999999);
          break;
        case CurrencyType.gems:
          newGems = (state.gems + amount).clamp(0, 999999);
          break;
      }

      // Cria a transação
      final transaction = CurrencyTransaction(
        id: _firestoreService.generateId(),
        userId: _userId!,
        amount: amount,
        type: type,
        reason: reason,
        gameId: gameId,
        description: reason.description,
        timestamp: DateTime.now(),
        metadata: {
          'previousCoins': state.coins,
          'previousGems': state.gems,
          'newCoins': newCoins,
          'newGems': newGems,
        },
      );

      // Salva no Firestore usando transação
      await _firestoreService.updateUserCurrency(
        userId: _userId!,
        newCoins: newCoins,
        newGems: newGems,
        transaction: transaction,
      );

      // Atualiza estado local
      state = state.withBalances(newCoins, newGems);

      AppLogger.info(
        '💰 Currency transaction completed',
        data: {
          'amount': amount,
          'type': type.name,
          'reason': reason.name,
          'newCoins': newCoins,
          'newGems': newGems,
        },
      );

      // Trigger para achievements se necessário
      _checkForAchievements(amount, type, reason);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Currency transaction failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.withError('Erro na transação');

      // Reverte para estado anterior
      await _syncWithFirestore();
      return false;
    }
  }

  /// Processa recompensas automáticas para ações do usuário
  Future<void> processAutomaticReward(
    CurrencyReason reason, {
    String? gameId,
  }) async {
    if (reason.isReward) {
      switch (reason.defaultType) {
        case CurrencyType.coins:
          await addCoins(reason.defaultAmount, reason.name, gameId: gameId);
          break;
        case CurrencyType.gems:
          await addGems(reason.defaultAmount, reason.name, gameId: gameId);
          break;
      }
    }
  }

  /// Verifica por conquistas baseadas nas transações
  void _checkForAchievements(
    int amount,
    CurrencyType type,
    CurrencyReason reason,
  ) {
    // Triggers para o sistema de achievements (implementar na próxima semana)
    if (type == CurrencyType.coins && amount > 0) {
      final totalCoins = state.coins;

      // Achievements por quantidade total de moedas
      if (totalCoins >= 1000) {
        AppLogger.info('🏆 Achievement trigger: Rich Player (1000+ coins)');
        // _ref.read(achievementsProvider.notifier).unlockAchievement('rich_player');
      }

      if (totalCoins >= 5000) {
        AppLogger.info('🏆 Achievement trigger: Coin Master (5000+ coins)');
        // _ref.read(achievementsProvider.notifier).unlockAchievement('coin_master');
      }
    }

    // Trigger para first connection achievement
    if (reason == CurrencyReason.firstConnection) {
      AppLogger.info('🏆 Achievement trigger: First Connection');
      // _ref.read(achievementsProvider.notifier).unlockAchievement('first_connection');
    }
  }

  /// Força um refresh manual das moedas
  Future<void> refresh() async {
    await _syncWithFirestore();
  }

  /// Retorna informações de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'userId': _userId,
      'state': state.toString(),
      'lastUpdated': state.lastUpdated.toIso8601String(),
      'syncTimerActive': _syncTimer?.isActive ?? false,
    };
  }
}
