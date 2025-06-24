// lib/providers/shop_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/powerup_model.dart';
import 'package:unlock/models/shop_item_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/services/firestore_service.dart';

/// Provider para gerenciar a loja
final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  final authState = ref.watch(authProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  return ShopNotifier(
    firestoreService: firestoreService,
    userId: authState.user?.uid,
    ref: ref,
  );
});

/// Provider para inventário de power-ups do usuário
final powerUpInventoryProvider = StateNotifierProvider<PowerUpInventoryNotifier, PowerUpInventoryState>((ref) {
  final authState = ref.watch(authProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  return PowerUpInventoryNotifier(
    firestoreService: firestoreService,
    userId: authState.user?.uid,
    ref: ref,
  );
});

/// Provider para itens em destaque
final featuredItemsProvider = Provider<List<ShopItem>>((ref) {
  final shopState = ref.watch(shopProvider);
  return shopState.featuredItems;
});

/// Provider para itens por categoria
final itemsByCategoryProvider = Provider.family<List<ShopItem>, ShopItemCategory>((ref, category) {
  final shopState = ref.watch(shopProvider);
  return shopState.itemsByCategory[category] ?? [];
});

/// Provider para verificar se pode comprar um item
final canPurchaseItemProvider = Provider.family<bool, String>((ref, itemId) {
  final shopState = ref.watch(shopProvider);
  final currencyState = ref.watch(currencyProvider);
  
  final item = shopState.items.firstWhere(
    (item) => item.id == itemId,
    orElse: () => throw Exception('Item não encontrado'),
  );
  
  return item.canAffordWith(currencyState.coins, currencyState.gems);
});

/// Notifier para gerenciar a loja
class ShopNotifier extends StateNotifier<ShopState> {
  final FirestoreService _firestoreService;
  final String? _userId;
  final Ref _ref;
  Timer? _refreshTimer;

  ShopNotifier({
    required FirestoreService firestoreService,
    required String? userId,
    required Ref ref,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _ref = ref,
        super(ShopState(lastUpdated: DateTime.now())) {
    _initializeShop();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Inicializa a loja
  Future<void> _initializeShop() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Carrega itens da loja (por enquanto usa dados padrão)
      final items = ShopData.defaultItems;
      final featuredItems = items.where((item) => item.isFeatured).toList();
      
      // Carrega compras recentes se houver usuário
      List<ShopPurchase> recentPurchases = [];
      if (_userId != null) {
        recentPurchases = await _loadRecentPurchases();
      }

      state = state.copyWith(
        items: items,
        featuredItems: featuredItems,
        recentPurchases: recentPurchases,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('🛍️ Loja inicializada', data: {
        'itemsCount': items.length,
        'featuredCount': featuredItems.length,
        'purchasesCount': recentPurchases.length,
      });

      // Agenda refresh periódico
      _schedulePeriodicRefresh();
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao inicializar loja', 
        error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar loja',
      );
    }
  }

  /// Agenda refresh periódico da loja
  void _schedulePeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      refresh();
    });
  }

  /// Carrega compras recentes do usuário
  Future<List<ShopPurchase>> _loadRecentPurchases() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shop_purchases')
          .where('userId', isEqualTo: _userId)
          .orderBy('purchasedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        return ShopPurchase.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      AppLogger.error('❌ Erro ao carregar compras recentes', error: e);
      return [];
    }
  }

  /// Compra um item da loja
  Future<bool> purchaseItem(
    String itemId, {
    CurrencyType? preferredCurrency,
    int quantity = 1,
  }) async {
    if (_userId == null) {
      state = state.copyWith(error: 'Usuário não autenticado');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Encontra o item
      final item = state.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item não encontrado'),
      );

      if (!item.isCurrentlyAvailable) {
        throw Exception('Item não está disponível');
      }

      // Seleciona preço baseado na preferência ou disponibilidade
      final price = _selectBestPrice(item, preferredCurrency);
      if (price == null) {
        throw Exception('Preço não encontrado');
      }

      // Verifica se pode pagar
      final currencyState = _ref.read(currencyProvider);
      final totalCost = price.amount * quantity;
      
      if (!currencyState.canAfford(totalCost, price.currencyType)) {
        throw Exception('Moedas insuficientes');
      }

      // Aplica desconto se houver
      final finalPrice = item.isOnSale ? item.getDiscountedPrice(price)! : price;
      final finalCost = finalPrice.amount * quantity;

      // Processa a compra
      final purchaseId = await _processPurchase(item, finalPrice, quantity);
      
      if (purchaseId != null) {
        // Deduz o valor das moedas
        final currencyNotifier = _ref.read(currencyProvider.notifier);
        bool paymentSuccess = false;
        
        switch (finalPrice.currencyType) {
          case CurrencyType.coins:
            paymentSuccess = await currencyNotifier.spendCoins(
              finalCost, 
              'shop_purchase',
              gameId: purchaseId,
            );
            break;
          case CurrencyType.gems:
            paymentSuccess = await currencyNotifier.spendGems(
              finalCost, 
              'shop_purchase',
              gameId: purchaseId,
            );
            break;
        }

        if (paymentSuccess) {
          // Adiciona item ao inventário
          await _addItemToInventory(item, quantity, purchaseId);
          
          // Atualiza lista de compras recentes
          await _refreshRecentPurchases();
          
          state = state.copyWith(isLoading: false);
          
          AppLogger.info('✅ Compra realizada com sucesso', data: {
            'itemId': itemId,
            'quantity': quantity,
            'cost': finalCost,
            'currency': finalPrice.currencyType.name,
            'purchaseId': purchaseId,
          });

          return true;
        } else {
          throw Exception('Falha no pagamento');
        }
      } else {
        throw Exception('Falha ao processar compra');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro na compra', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Seleciona o melhor preço baseado na preferência
  ShopPrice? _selectBestPrice(ShopItem item, CurrencyType? preferredCurrency) {
    if (item.prices.isEmpty) return null;

    // Se há preferência, tenta usar ela
    if (preferredCurrency != null) {
      try {
        return item.prices.firstWhere((p) => p.currencyType == preferredCurrency);
      } catch (e) {
        // Se não encontrar, continua para lógica padrão
      }
    }

    // Prioriza moedas sobre gemas por padrão
    final coinsPrice = item.prices.where((p) => p.currencyType == CurrencyType.coins).firstOrNull;
    if (coinsPrice != null) return coinsPrice;

    // Se não há preço em moedas, retorna o primeiro
    return item.prices.first;
  }

  /// Processa a compra no Firestore
  Future<String?> _processPurchase(
    ShopItem item, 
    ShopPrice price, 
    int quantity,
  ) async {
    try {
      final purchase = ShopPurchase(
        id: _firestoreService.generateId(),
        userId: _userId!,
        itemId: item.id,
        pricePaid: price,
        quantity: quantity,
        purchasedAt: DateTime.now(),
        status: ShopPurchaseStatus.processing,
        metadata: {
          'itemName': item.name,
          'itemType': item.type.name,
          'discountApplied': item.isOnSale,
          'originalPrice': item.primaryPrice?.amount,
        },
      );

      await FirebaseFirestore.instance
          .collection('shop_purchases')
          .doc(purchase.id)
          .set(purchase.toJson());

      return purchase.id;
    } catch (e) {
      AppLogger.error('❌ Erro ao processar compra', error: e);
      return null;
    }
  }

  /// Adiciona item ao inventário do usuário
  Future<void> _addItemToInventory(
    ShopItem item, 
    int quantity, 
    String purchaseId,
  ) async {
    try {
      switch (item.type) {
        case ShopItemType.powerUp:
          await _addPowerUpToInventory(item, quantity, purchaseId);
          break;
        case ShopItemType.currency:
          await _addCurrencyToWallet(item, quantity);
          break;
        case ShopItemType.bundle:
          await _processBundleItems(item, quantity, purchaseId);
          break;
        default:
          AppLogger.warning('Tipo de item não implementado: ${item.type}');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao adicionar item ao inventário', error: e);
    }
  }

  /// Adiciona power-up ao inventário
  Future<void> _addPowerUpToInventory(
    ShopItem item, 
    int quantity, 
    String purchaseId,
  ) async {
    final powerUpInventoryNotifier = _ref.read(powerUpInventoryProvider.notifier);
    
    // Determina o tipo de power-up baseado no ID do item
    PowerUpType? powerUpType;
    for (final type in PowerUpType.values) {
      if (item.id.contains(type.name) || item.metadata['powerUpType'] == type.name) {
        powerUpType = type;
        break;
      }
    }

    if (powerUpType != null) {
      await powerUpInventoryNotifier.addPowerUp(
        powerUpType, 
        quantity,
        purchaseId: purchaseId,
      );
    }
  }

  /// Adiciona moedas à carteira
  Future<void> _addCurrencyToWallet(ShopItem item, int quantity) async {
    final currencyNotifier = _ref.read(currencyProvider.notifier);
    final coinAmount = (item.metadata['coinAmount'] as int?) ?? 0;
    
    if (coinAmount > 0) {
      await currencyNotifier.addCoins(
        coinAmount * quantity, 
        'shop_currency_purchase',
      );
    }
  }

  /// Processa itens de um pacote
  Future<void> _processBundleItems(
    ShopItem bundle, 
    int quantity, 
    String purchaseId,
  ) async {
    // Power-ups do pacote
    final powerUps = bundle.metadata['powerUps'] as List<dynamic>?;
    if (powerUps != null) {
      final powerUpInventoryNotifier = _ref.read(powerUpInventoryProvider.notifier);
      
      for (final powerUpId in powerUps) {
        final powerUpType = PowerUpType.values.firstWhere(
          (type) => type.name == powerUpId,
          orElse: () => PowerUpType.extraHint,
        );
        
        await powerUpInventoryNotifier.addPowerUp(
          powerUpType, 
          quantity,
          purchaseId: purchaseId,
        );
      }
    }

    // Moedas do pacote
    final coins = bundle.metadata['coins'] as int?;
    if (coins != null && coins > 0) {
      final currencyNotifier = _ref.read(currencyProvider.notifier);
      await currencyNotifier.addCoins(
        coins * quantity, 
        'shop_bundle_purchase',
      );
    }
  }

  /// Atualiza lista de compras recentes
  Future<void> _refreshRecentPurchases() async {
    if (_userId != null) {
      final recentPurchases = await _loadRecentPurchases();
      state = state.copyWith(recentPurchases: recentPurchases);
    }
  }

  /// Define categoria selecionada
  void setSelectedCategory(ShopItemCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Define query de busca
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Limpa filtros
  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      searchQuery: null,
    );
  }

  /// Força refresh da loja
  Future<void> refresh() async {
    await _initializeShop();
  }

  /// Limpa erro
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Notifier para inventário de power-ups
class PowerUpInventoryNotifier extends StateNotifier<PowerUpInventoryState> {
  final FirestoreService _firestoreService;
  final String? _userId;
  final Ref _ref;

  PowerUpInventoryNotifier({
    required FirestoreService firestoreService,
    required String? userId,
    required Ref ref,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _ref = ref,
        super(PowerUpInventoryState(lastUpdated: DateTime.now())) {
    if (_userId != null) {
      _loadInventory();
    }
  }

  /// Carrega inventário do usuário
  Future<void> _loadInventory() async {
    if (_userId == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final snapshot = await FirebaseFirestore.instance
          .collection('user_powerups')
          .where('userId', isEqualTo: _userId)
          .where('isActive', isEqualTo: true)
          .get();

      final inventory = snapshot.docs.map((doc) {
        return UserPowerUp.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      state = state.copyWith(
        inventory: inventory,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('📦 Inventário carregado', data: {
        'userId': _userId,
        'itemCount': inventory.length,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao carregar inventário', 
        error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar inventário',
      );
    }
  }

  /// Adiciona power-up ao inventário
  Future<void> addPowerUp(
    PowerUpType type, 
    int quantity, {
    String? purchaseId,
    DateTime? expiresAt,
  }) async {
    if (_userId == null) return;

    try {
      // Verifica se já existe um power-up deste tipo
      final existingIndex = state.inventory.indexWhere(
        (p) => p.type == type && p.isAvailable,
      );

      if (existingIndex != -1) {
        // Atualiza quantidade existente
        final existing = state.inventory[existingIndex];
        final updatedPowerUp = existing.copyWith(
          quantity: existing.quantity + quantity,
        );

        await FirebaseFirestore.instance
            .collection('user_powerups')
            .doc(existing.id)
            .update(updatedPowerUp.toJson());

        // Atualiza estado local
        final updatedInventory = List<UserPowerUp>.from(state.inventory);
        updatedInventory[existingIndex] = updatedPowerUp;
        
        state = state.copyWith(inventory: updatedInventory);
      } else {
        // Cria novo power-up
        final newPowerUp = UserPowerUp(
          id: _firestoreService.generateId(),
          userId: _userId!,
          type: type,
          quantity: quantity,
          acquiredAt: DateTime.now(),
          expiresAt: expiresAt,
          metadata: {
            'purchaseId': purchaseId,
            'source': 'shop_purchase',
          },
        );

        await FirebaseFirestore.instance
            .collection('user_powerups')
            .doc(newPowerUp.id)
            .set(newPowerUp.toJson());

        // Atualiza estado local
        state = state.copyWith(
          inventory: [...state.inventory, newPowerUp],
        );
      }

      AppLogger.info('✅ Power-up adicionado ao inventário', data: {
        'type': type.name,
        'quantity': quantity,
        'userId': _userId,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao adicionar power-up', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Usa um power-up
  Future<bool> usePowerUp(
    PowerUpType type, 
    String gameRoomId, {
    int quantity = 1,
  }) async {
    if (_userId == null) return false;

    try {
      // Encontra power-up disponível
      final powerUpIndex = state.inventory.indexWhere(
        (p) => p.type == type && p.isAvailable && p.quantity >= quantity,
      );

      if (powerUpIndex == -1) {
        AppLogger.warning('Power-up não disponível', data: {
          'type': type.name,
          'requested': quantity,
        });
        return false;
      }

      final powerUp = state.inventory[powerUpIndex];
      
      // Registra uso do power-up
      final usage = GamePowerUpUsage(
        id: _firestoreService.generateId(),
        gameRoomId: gameRoomId,
        userId: _userId!,
        type: type,
        usedAt: DateTime.now(),
        effect: {
          'quantity': quantity,
          'powerUpId': powerUp.id,
        },
      );

      await FirebaseFirestore.instance
          .collection('game_powerup_usage')
          .doc(usage.id)
          .set(usage.toJson());

      // Atualiza quantidade no inventário
      final updatedQuantity = powerUp.quantity - quantity;
      
      if (updatedQuantity <= 0) {
        // Remove do inventário se acabou
        await FirebaseFirestore.instance
            .collection('user_powerups')
            .doc(powerUp.id)
            .update({'isActive': false});
            
        final updatedInventory = state.inventory
            .where((p) => p.id != powerUp.id)
            .toList();
        
        state = state.copyWith(inventory: updatedInventory);
      } else {
        // Atualiza quantidade
        final updatedPowerUp = powerUp.copyWith(quantity: updatedQuantity);
        
        await FirebaseFirestore.instance
            .collection('user_powerups')
            .doc(powerUp.id)
            .update(updatedPowerUp.toJson());
            
        final updatedInventory = List<UserPowerUp>.from(state.inventory);
        updatedInventory[powerUpIndex] = updatedPowerUp;
        
        state = state.copyWith(inventory: updatedInventory);
      }

      AppLogger.info('🔥 Power-up usado', data: {
        'type': type.name,
        'gameId': gameRoomId,
        'quantity': quantity,
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao usar power-up', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Força refresh do inventário
  Future<void> refresh() async {
    await _loadInventory();
  }
}

/// Extensão para adicionar firstOrNull se não existir
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}