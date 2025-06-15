import 'package:flutter/material.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinAnimation;

  int _selectedTabIndex = 0;
  String? _lastPurchasedItem;

  final currentUser = null;

  final List<String> _categories = ['avatars', 'borders', 'badges', 'themes'];
  final List<String> _categoryNames = [
    'Avatares',
    'Bordas',
    'Emblemas',
    'Temas',
  ];
  final List<IconData> _categoryIcons = [
    Icons.face,
    Icons.border_all,
    Icons.star,
    Icons.palette,
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _categories.length, vsync: this);

    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _coinAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _coinAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  void _purchaseItem(String category, Map<String, dynamic> item) {
    final cost = item['cost'] as int;
    final currency = item['currency'] as String;
    final itemId = item['id'] as String;

    if (currentUser.ownsItem(category, itemId)) {
      // Se já possui, apenas equipa
      currentUser.equipItem(category, itemId);
      AppHelpers.showCustomSnackBar(
        context,
        '${item['name']} equipado!',
        backgroundColor: Colors.blue,
        icon: Icons.check_circle,
      );
      return;
    }

    if (AppHelpers.canAfford(cost, currency)) {
      final success = currentUser.purchaseItem(
        category,
        itemId,
        cost,
        currency,
      );

      if (success) {
        setState(() {
          _lastPurchasedItem = itemId;
        });

        _animatePurchase();
        currentUser.updateMissionProgress('m6', 1);

        AppHelpers.showCustomSnackBar(
          context,
          '🎉 ${item['name']} comprado e equipado!',
          backgroundColor: Colors.green,
          icon: Icons.shopping_bag,
        );
      }
    } else {
      AppHelpers.showCustomSnackBar(
        context,
        'Você não tem $currency suficiente!',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  void _animatePurchase() {
    _coinAnimationController.forward().then((_) {
      _coinAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: currentUser,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('🛍️ Loja de Itens'),
            elevation: 0,
            actions: [
              // Recursos do usuário
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _coinAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _coinAnimation.value,
                          child: _buildResourceChip(
                            Icons.monetization_on,
                            currentUser.moedas.toString(),
                            Colors.orange,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildResourceChip(
                      Icons.diamond,
                      currentUser.gemas.toString(),
                      Colors.cyan,
                    ),
                  ],
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: List.generate(_categories.length, (index) {
                return Tab(
                  icon: Icon(_categoryIcons[index]),
                  text: _categoryNames[index],
                );
              }),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final items = MockDataProvider.shopItems[category] ?? [];
              return _buildCategoryGrid(category, items);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildResourceChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(String category, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhum item disponível nesta categoria.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildItemCard(category, item);
        },
      ),
    );
  }

  Widget _buildItemCard(String category, Map<String, dynamic> item) {
    final isOwned = currentUser.ownsItem(category, item['id']);
    final isEquipped = currentUser.isItemEquipped(category, item['id']);
    final canAfford = AppHelpers.canAfford(
      item['cost'] as int,
      item['currency'] as String,
    );
    final rarityColor = dataProvider.getRarityColor(item['rarity']);
    final isNewPurchase = _lastPurchasedItem == item['id'];

    return AnimatedContainer(
      duration: Duration(milliseconds: isNewPurchase ? 300 : 0),
      transform: Matrix4.identity()..scale(isNewPurchase ? 1.05 : 1.0),
      child: Card(
        elevation: isEquipped ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isEquipped
                ? Theme.of(context).primaryColor
                : (isOwned ? Colors.green : Colors.transparent),
            width: isEquipped ? 3 : (isOwned ? 2 : 0),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEquipped
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Badge de raridade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['rarity'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Preview do item
              Expanded(child: Center(child: _buildItemPreview(category, item))),

              const SizedBox(height: 8),

              // Nome do item
              Text(
                item['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Descrição
              Text(
                item['description'] as String,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Preço
              if (item['cost'] > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['currency'] == 'moedas'
                          ? Icons.monetization_on
                          : Icons.diamond,
                      size: 16,
                      color: item['currency'] == 'moedas'
                          ? Colors.orange
                          : Colors.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['cost'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Botão de ação
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: (isEquipped || (!canAfford && !isOwned))
                      ? null
                      : () => _purchaseItem(category, item),
                  backgroundColor: _getButtonColor(
                    isOwned,
                    isEquipped,
                    canAfford,
                  ),
                  foregroundColor: Colors.white,
                  child: Text(
                    _getButtonText(isOwned, isEquipped, canAfford),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemPreview(String category, Map<String, dynamic> item) {
    switch (category) {
      case 'avatars':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'] as IconData,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
        );

      case 'borders':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: item['color'] as Color, width: 4),
          ),
          child: const Icon(Icons.person, size: 30, color: Colors.grey),
        );

      case 'badges':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.brown.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item['icon'] as IconData,
            size: 32,
            color: Colors.brown.shade600,
          ),
        );

      case 'themes':
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: item['primaryColor'] as Color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (item['primaryColor'] as Color).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.palette,
            size: 24,
            color: (item['primaryColor'] as Color).computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
          ),
        );

      default:
        return const Icon(Icons.help, size: 32);
    }
  }

  Color _getButtonColor(bool isOwned, bool isEquipped, bool canAfford) {
    if (isEquipped) return Colors.grey;
    if (isOwned) return Colors.blue;
    if (!canAfford) return Colors.grey;
    return Colors.green;
  }

  String _getButtonText(bool isOwned, bool isEquipped, bool canAfford) {
    if (isEquipped) return 'EQUIPADO';
    if (isOwned) return 'EQUIPAR';
    if (!canAfford) return 'SEM RECURSOS';
    return 'COMPRAR';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _coinAnimationController.dispose();
    super.dispose();
  }
}
