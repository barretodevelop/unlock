// lib/features/shop/screens/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/features/shop/widgets/powerup_card.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/shop_item_model.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/providers/shop_provider.dart';
import 'package:unlock/shared/widgets/app_header_with_currency.dart';

/// Tela principal da loja
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ShopItemCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final currencyState = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppHeaderWithCurrency(title: 'Loja', showBackButton: true),
      body: shopState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                _SearchBar(controller: _searchController),

                // Featured items section
                if (shopState.featuredItems.isNotEmpty) ...[
                  _FeaturedSection(items: shopState.featuredItems),
                  const SizedBox(height: 16),
                ],

                // Categories tabs
                _CategoriesTabs(tabController: _tabController),

                // Items grid
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ShopItemCategory.values.map((category) {
                      return _CategoryView(category: category);
                    }).toList(),
                  ),
                ),
              ],
            ),

      // Error handling
      bottomSheet: shopState.error != null
          ? _ErrorBanner(
              error: shopState.error!,
              onDismiss: () => ref.read(shopProvider.notifier).clearError(),
            )
          : null,
    );
  }
}

/// Barra de busca
class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar itens na loja...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(shopProvider.notifier).setSearchQuery(null);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer,
        ),
        onChanged: (query) {
          ref
              .read(shopProvider.notifier)
              .setSearchQuery(query.isEmpty ? null : query);
        },
      ),
    );
  }
}

/// Seção de itens em destaque
class _FeaturedSection extends StatelessWidget {
  final List<ShopItem> items;

  const _FeaturedSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.star, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Em Destaque',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: PowerUpCard(item: items[index], isFeatured: true)
                    .animate(delay: (index * 100).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.2, end: 0),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Tabs das categorias
class _CategoriesTabs extends ConsumerWidget {
  final TabController tabController;

  const _CategoriesTabs({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        onTap: (index) {
          final category = ShopItemCategory.values[index];
          ref.read(shopProvider.notifier).setSelectedCategory(category);
        },
        tabs: ShopItemCategory.values.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16),
                const SizedBox(width: 8),
                Text(category.displayName),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// View de uma categoria específica
class _CategoryView extends ConsumerWidget {
  final ShopItemCategory category;

  const _CategoryView({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsByCategoryProvider(category));
    final shopState = ref.watch(shopProvider);

    // Aplica filtros se houver
    final filteredItems = shopState.filteredItems
        .where((item) => item.category == category)
        .toList();

    if (filteredItems.isEmpty) {
      return _EmptyCategory(category: category);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return PowerUpCard(
              item: item,
              onPurchase: () => _handlePurchase(context, ref, item),
            )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
      },
    );
  }

  void _handlePurchase(BuildContext context, WidgetRef ref, ShopItem item) {
    _showPurchaseDialog(context, ref, item);
  }
}

/// Categoria vazia
class _EmptyCategory extends StatelessWidget {
  final ShopItemCategory category;

  const _EmptyCategory({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum item encontrado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou volte mais tarde',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de erro
class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }
}

/// Dialog de confirmação de compra
void _showPurchaseDialog(BuildContext context, WidgetRef ref, ShopItem item) {
  showDialog(
    context: context,
    builder: (context) => _PurchaseDialog(item: item),
  );
}

/// Dialog de compra
class _PurchaseDialog extends ConsumerStatefulWidget {
  final ShopItem item;

  const _PurchaseDialog({required this.item});

  @override
  ConsumerState<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends ConsumerState<_PurchaseDialog> {
  int quantity = 1;
  ShopPrice? selectedPrice;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    selectedPrice = widget.item.primaryPrice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyState = ref.watch(currencyProvider);

    final finalPrice = widget.item.isOnSale && selectedPrice != null
        ? widget.item.getDiscountedPrice(selectedPrice!)!
        : selectedPrice;

    final totalCost = (finalPrice?.amount ?? 0) * quantity;

    final canAfford =
        finalPrice != null &&
        currencyState.canAfford(totalCost, finalPrice.currencyType);

    return AlertDialog(
      title: Row(
        children: [
          Text(widget.item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.item.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            widget.item.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Price selection
          if (widget.item.prices.length > 1) ...[
            Text(
              'Escolha a forma de pagamento:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.item.prices.map((price) {
              final isSelected = selectedPrice == price;
              final discountedPrice = widget.item.isOnSale
                  ? widget.item.getDiscountedPrice(price)!
                  : price;

              return RadioListTile<ShopPrice>(
                title: Text(
                  '${discountedPrice.formattedPrice}${price.label != null ? ' (${price.label})' : ''}',
                ),
                subtitle:
                    widget.item.isOnSale &&
                        price.amount != discountedPrice.amount
                    ? Text(
                        'Original: ${price.formattedPrice}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )
                    : null,
                value: price,
                groupValue: selectedPrice,
                onChanged: (value) {
                  setState(() {
                    selectedPrice = value;
                  });
                },
                activeColor: AppColors.primary,
                dense: true,
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Quantity selector
          Row(
            children: [
              Text(
                'Quantidade:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantity.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total cost
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  finalPrice != null
                      ? '${finalPrice.currencyType.emoji} $totalCost'
                      : 'N/A',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // Insufficient funds warning
          if (!canAfford) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Moedas insuficientes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: canAfford && !isProcessing && finalPrice != null
              ? () => _processPurchase(context, ref)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Comprar'),
        ),
      ],
    );
  }

  Future<void> _processPurchase(BuildContext context, WidgetRef ref) async {
    if (selectedPrice == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final success = await ref
          .read(shopProvider.notifier)
          .purchaseItem(
            widget.item.id,
            preferredCurrency: selectedPrice!.currencyType,
            quantity: quantity,
          );

      if (success && context.mounted) {
        Navigator.of(context).pop();

        // Mostra feedback de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Compra realizada! ${widget.item.name} foi adicionado ao seu inventário.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na compra: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
}
