// lib/models/shop_item_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/powerup_model.dart';

/// Item da loja no sistema Unlock
class ShopItem {
  final String id;
  final ShopItemType type;
  final String name;
  final String description;
  final String emoji;
  final List<ShopPrice> prices;
  final ShopItemCategory category;
  final ShopItemRarity rarity;
  final bool isAvailable;
  final bool isLimited;
  final int? stockQuantity;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final int sortOrder;
  final bool isFeatured;
  final double? discountPercentage;

  const ShopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.prices,
    required this.category,
    this.rarity = ShopItemRarity.common,
    this.isAvailable = true,
    this.isLimited = false,
    this.stockQuantity,
    this.availableFrom,
    this.availableUntil,
    this.tags = const [],
    this.metadata = const {},
    this.sortOrder = 0,
    this.isFeatured = false,
    this.discountPercentage,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] ?? '',
      type: ShopItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ShopItemType.powerUp,
      ),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '🛍️',
      prices: (json['prices'] as List<dynamic>?)
          ?.map((p) => ShopPrice.fromJson(Map<String, dynamic>.from(p)))
          .toList() ?? [],
      category: ShopItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShopItemCategory.powerUps,
      ),
      rarity: ShopItemRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => ShopItemRarity.common,
      ),
      isAvailable: json['isAvailable'] ?? true,
      isLimited: json['isLimited'] ?? false,
      stockQuantity: json['stockQuantity'],
      availableFrom: (json['availableFrom'] as Timestamp?)?.toDate(),
      availableUntil: (json['availableUntil'] as Timestamp?)?.toDate(),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      sortOrder: json['sortOrder'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'description': description,
      'emoji': emoji,
      'prices': prices.map((p) => p.toJson()).toList(),
      'category': category.name,
      'rarity': rarity.name,
      'isAvailable': isAvailable,
      'isLimited': isLimited,
      'stockQuantity': stockQuantity,
      'availableFrom': availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableUntil': availableUntil != null ? Timestamp.fromDate(availableUntil!) : null,
      'tags': tags,
      'metadata': metadata,
      'sortOrder': sortOrder,
      'isFeatured': isFeatured,
      'discountPercentage': discountPercentage,
    };
  }

  ShopItem copyWith({
    String? id,
    ShopItemType? type,
    String? name,
    String? description,
    String? emoji,
    List<ShopPrice>? prices,
    ShopItemCategory? category,
    ShopItemRarity? rarity,
    bool? isAvailable,
    bool? isLimited,
    int? stockQuantity,
    DateTime? availableFrom,
    DateTime? availableUntil,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? sortOrder,
    bool? isFeatured,
    double? discountPercentage,
  }) {
    return ShopItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      prices: prices ?? this.prices,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      isAvailable: isAvailable ?? this.isAvailable,
      isLimited: isLimited ?? this.isLimited,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      sortOrder: sortOrder ?? this.sortOrder,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }

  /// Verifica se o item está disponível no momento
  bool get isCurrentlyAvailable {
    if (!isAvailable) return false;
    
    final now = DateTime.now();
    
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false;
    }
    
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return false;
    }
    
    if (isLimited && stockQuantity != null && stockQuantity! <= 0) {
      return false;
    }
    
    return true;
  }

  /// Verifica se o item está em promoção
  bool get isOnSale => discountPercentage != null && discountPercentage! > 0;

  /// Retorna o preço principal (primeiro da lista)
  ShopPrice? get primaryPrice => prices.isNotEmpty ? prices.first : null;

  /// Retorna preço com desconto aplicado
  ShopPrice? getDiscountedPrice(ShopPrice original) {
    if (!isOnSale) return original;
    
    final discountedAmount = (original.amount * (1 - discountPercentage! / 100)).round();
    return original.copyWith(amount: discountedAmount);
  }

  /// Verifica se o usuário pode comprar com as moedas disponíveis
  bool canAffordWith(int coins, int gems) {
    if (!isCurrentlyAvailable) return false;
    
    return prices.any((price) {
      final finalPrice = isOnSale ? getDiscountedPrice(price)! : price;
      
      switch (finalPrice.currencyType) {
        case CurrencyType.coins:
          return coins >= finalPrice.amount;
        case CurrencyType.gems:
          return gems >= finalPrice.amount;
      }
    });
  }
}

/// Preço de um item da loja
class ShopPrice {
  final CurrencyType currencyType;
  final int amount;
  final String? label; // ex: "Oferta especial"

  const ShopPrice({
    required this.currencyType,
    required this.amount,
    this.label,
  });

  factory ShopPrice.fromJson(Map<String, dynamic> json) {
    return ShopPrice(
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == json['currencyType'],
        orElse: () => CurrencyType.coins,
      ),
      amount: json['amount'] ?? 0,
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencyType': currencyType.name,
      'amount': amount,
      'label': label,
    };
  }

  ShopPrice copyWith({
    CurrencyType? currencyType,
    int? amount,
    String? label,
  }) {
    return ShopPrice(
      currencyType: currencyType ?? this.currencyType,
      amount: amount ?? this.amount,
      label: label ?? this.label,
    );
  }

  /// Formata o preço para exibição
  String get formattedPrice {
    return '${currencyType.emoji} $amount';
  }
}

/// Compra realizada pelo usuário
class ShopPurchase {
  final String id;
  final String userId;
  final String itemId;
  final ShopPrice pricePaid;
  final int quantity;
  final DateTime purchasedAt;
  final ShopPurchaseStatus status;
  final String? transactionId;
  final Map<String, dynamic> metadata;

  const ShopPurchase({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.pricePaid,
    this.quantity = 1,
    required this.purchasedAt,
    this.status = ShopPurchaseStatus.completed,
    this.transactionId,
    this.metadata = const {},
  });

  factory ShopPurchase.fromJson(Map<String, dynamic> json) {
    return ShopPurchase(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      itemId: json['itemId'] ?? '',
      pricePaid: ShopPrice.fromJson(Map<String, dynamic>.from(json['pricePaid'] ?? {})),
      quantity: json['quantity'] ?? 1,
      purchasedAt: (json['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ShopPurchaseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ShopPurchaseStatus.completed,
      ),
      transactionId: json['transactionId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'pricePaid': pricePaid.toJson(),
      'quantity': quantity,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'status': status.name,
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }
}

/// Tipos de itens da loja
enum ShopItemType {
  powerUp('Power-up', 'Itens para usar nos jogos'),
  currency('Moeda', 'Pacotes de moedas e gemas'),
  cosmetic('Cosmético', 'Itens visuais e personalizações'),
  bundle('Pacote', 'Conjunto de itens com desconto'),
  subscription('Assinatura', 'Benefícios mensais premium');

  const ShopItemType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Categorias da loja
enum ShopItemCategory {
  powerUps('Power-ups', Icons.flash_on),
  currencies('Moedas', Icons.monetization_on),
  cosmetics('Cosméticos', Icons.palette),
  bundles('Pacotes', Icons.shopping_bag),
  premium('Premium', Icons.diamond),
  limited('Limitado', Icons.timer);

  const ShopItemCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Raridade dos itens da loja
enum ShopItemRarity {
  common('Comum', 0xFF4CAF50),
  rare('Raro', 0xFF2196F3),
  epic('Épico', 0xFF9C27B0),
  legendary('Lendário', 0xFFFF9800),
  exclusive('Exclusivo', 0xFFE91E63);

  const ShopItemRarity(this.displayName, this.colorValue);
  final String displayName;
  final int colorValue;
}

/// Status da compra
enum ShopPurchaseStatus {
  pending('Pendente'),
  processing('Processando'),
  completed('Concluída'),
  failed('Falhou'),
  refunded('Reembolsada');

  const ShopPurchaseStatus(this.displayName);
  final String displayName;
}

/// Estado da loja
class ShopState {
  final List<ShopItem> items;
  final List<ShopItem> featuredItems;
  final List<ShopPurchase> recentPurchases;
  final bool isLoading;
  final String? error;
  final ShopItemCategory? selectedCategory;
  final String? searchQuery;
  final DateTime lastUpdated;

  const ShopState({
    this.items = const [],
    this.featuredItems = const [],
    this.recentPurchases = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery,
    required this.lastUpdated,
  });

  ShopState copyWith({
    List<ShopItem>? items,
    List<ShopItem>? featuredItems,
    List<ShopPurchase>? recentPurchases,
    bool? isLoading,
    String? error,
    ShopItemCategory? selectedCategory,
    String? searchQuery,
    DateTime? lastUpdated,
  }) {
    return ShopState(
      items: items ?? this.items,
      featuredItems: featuredItems ?? this.featuredItems,
      recentPurchases: recentPurchases ?? this.recentPurchases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Retorna itens filtrados
  List<ShopItem> get filteredItems {
    var filtered = items.where((item) => item.isCurrentlyAvailable).toList();

    if (selectedCategory != null) {
      filtered = filtered.where((item) => item.category == selectedCategory).toList();
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((item) =>
        item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query) ||
        item.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    // Ordena por: featured primeiro, depois por sortOrder, depois por nome
    filtered.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      
      final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderComparison != 0) return sortOrderComparison;
      
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  /// Retorna itens por categoria
  Map<ShopItemCategory, List<ShopItem>> get itemsByCategory {
    final map = <ShopItemCategory, List<ShopItem>>{};
    for (final item in items.where((i) => i.isCurrentlyAvailable)) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }
}

/// Dados padrão da loja
class ShopData {
  static const List<ShopItem> defaultItems = [
    // Power-ups básicos
    ShopItem(
      id: 'power_extra_hint',
      type: ShopItemType.powerUp,
      name: 'Dica Extra',
      description: 'Revela uma dica adicional sobre a resposta correta',
      emoji: '💡',
      prices: [ShopPrice(currencyType: CurrencyType.coins, amount: 25)],
      category: ShopItemCategory.powerUps,
      rarity: ShopItemRarity.common,
      tags: ['dica', 'ajuda', 'básico'],
      sortOrder: 10,
    ),
    
    ShopItem(
      id: 'power_super_question',
      type: ShopItemType.powerUp,
      name: 'Super Pergunta',
      description: 'Faz uma pergunta que revela 25% a mais do perfil',
      emoji: '🔥',
      prices: [ShopPrice(currencyType: CurrencyType.coins, amount: 50)],
      category: ShopItemCategory.powerUps,
      rarity: ShopItemRarity.rare,
      tags: ['pergunta', 'revelação', 'raro'],
      sortOrder: 20,
    ),

    ShopItem(
      id: 'power_match_booster',
      type: ShopItemType.powerUp,
      name: 'Match Booster',
      description: 'Dobra a pontuação de revelação por 3 perguntas',
      emoji: '⚡',
      prices: [
        ShopPrice(currencyType: CurrencyType.coins, amount: 75),
        ShopPrice(currencyType: CurrencyType.gems, amount: 3, label: 'Oferta Gemas'),
      ],
      category: ShopItemCategory.powerUps,
      rarity: ShopItemRarity.epic,
      tags: ['boost', 'pontuação', 'épico'],
      sortOrder: 30,
      isFeatured: true,
    ),

    // Pacotes de moedas
    ShopItem(
      id: 'coins_small',
      type: ShopItemType.currency,
      name: 'Pacote Pequeno',
      description: '500 moedas para suas compras',
      emoji: '💰',
      prices: [ShopPrice(currencyType: CurrencyType.gems, amount: 10)],
      category: ShopItemCategory.currencies,
      metadata: {'coinAmount': 500},
      sortOrder: 100,
    ),

    ShopItem(
      id: 'coins_medium',
      type: ShopItemType.currency,
      name: 'Pacote Médio',
      description: '1200 moedas com 20% de bônus',
      emoji: '💰',
      prices: [ShopPrice(currencyType: CurrencyType.gems, amount: 20)],
      category: ShopItemCategory.currencies,
      metadata: {'coinAmount': 1200},
      sortOrder: 101,
      isFeatured: true,
    ),

    // Pacotes especiais
    ShopItem(
      id: 'starter_bundle',
      type: ShopItemType.bundle,
      name: 'Pacote Iniciante',
      description: '3 power-ups + 200 moedas por um preço especial',
      emoji: '🎁',
      prices: [ShopPrice(currencyType: CurrencyType.coins, amount: 100)],
      category: ShopItemCategory.bundles,
      rarity: ShopItemRarity.rare,
      metadata: {
        'powerUps': ['extra_hint', 'skip_question', 'double_chance'],
        'coins': 200,
      },
      sortOrder: 200,
      isFeatured: true,
      discountPercentage: 25.0,
    ),

    // Item limitado
    ShopItem(
      id: 'golden_powerup',
      type: ShopItemType.powerUp,
      name: 'Power-up Dourado',
      description: 'Power-up especial que combina 3 efeitos diferentes',
      emoji: '🏆',
      prices: [ShopPrice(currencyType: CurrencyType.gems, amount: 25)],
      category: ShopItemCategory.limited,
      rarity: ShopItemRarity.legendary,
      isLimited: true,
      stockQuantity: 100,
      tags: ['dourado', 'especial', 'limitado'],
      sortOrder: 1,
      isFeatured: true,
    ),
  ];

  /// Retorna item por ID
  static ShopItem? getItemById(String id) {
    try {
      return defaultItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna itens por categoria
  static List<ShopItem> getItemsByCategory(ShopItemCategory category) {
    return defaultItems.where((item) => item.category == category).toList();
  }

  /// Retorna itens em destaque
  static List<ShopItem> getFeaturedItems() {
    return defaultItems.where((item) => item.isFeatured).toList();
  }

  /// Retorna itens que o usuário pode comprar
  static List<ShopItem> getAffordableItems(int coins, int gems) {
    return defaultItems.where((item) => item.canAffordWith(coins, gems)).toList();
  }
}