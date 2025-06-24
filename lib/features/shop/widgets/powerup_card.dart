// lib/features/shop/widgets/powerup_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/models/shop_item_model.dart';
import 'package:unlock/providers/currency_provider.dart';
import 'package:unlock/providers/shop_provider.dart';

/// Card para exibir power-ups na loja
class PowerUpCard extends ConsumerWidget {
  final ShopItem item;
  final bool isFeatured;
  final VoidCallback? onPurchase;
  final VoidCallback? onTap;

  const PowerUpCard({
    super.key,
    required this.item,
    this.isFeatured = false,
    this.onPurchase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyState = ref.watch(currencyProvider);
    final canAfford = ref.watch(canPurchaseItemProvider(item.id));

    return GestureDetector(
      onTap: onTap ?? onPurchase,
      child: Container(
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getRarityColor().withOpacity(0.3),
            width: isFeatured ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor().withOpacity(0.2),
              blurRadius: isFeatured ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: _BackgroundPattern(
                color: _getRarityColor().withOpacity(0.1),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with emoji and badges
                  Row(
                    children: [
                      // Emoji with glow effect
                      Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getRarityColor().withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              item.emoji,
                              style: TextStyle(fontSize: isFeatured ? 32 : 28),
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 2000.ms,
                            color: _getRarityColor().withOpacity(0.3),
                          ),

                      const Spacer(),

                      // Badges
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (item.isFeatured)
                            _Badge(
                              text: 'DESTAQUE',
                              color: AppColors.warning,
                              icon: Icons.star,
                            ),
                          if (item.isOnSale) ...[
                            const SizedBox(height: 4),
                            _Badge(
                              text: '${item.discountPercentage!.toInt()}% OFF',
                              color: AppColors.error,
                              icon: Icons.local_offer,
                            ),
                          ],
                          if (item.isLimited) ...[
                            const SizedBox(height: 4),
                            _Badge(
                              text: 'LIMITADO',
                              color: AppColors.accent,
                              icon: Icons.timer,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title and rarity
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  _RarityIndicator(rarity: item.rarity),

                  const SizedBox(height: 12),

                  // Description
                  Expanded(
                    child: Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: isFeatured ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price and purchase button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price display
                      _PriceDisplay(item: item, canAfford: canAfford),

                      const SizedBox(height: 12),

                      // Purchase button
                      SizedBox(
                        width: double.infinity,
                        child: _PurchaseButton(
                          item: item,
                          canAfford: canAfford,
                          onPressed: onPurchase,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stock indicator for limited items
            if (item.isLimited && item.stockQuantity != null)
              Positioned(
                top: 12,
                left: 12,
                child: _StockIndicator(stock: item.stockQuantity!),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor() {
    return Color(item.rarity.colorValue);
  }

  LinearGradient _getGradient() {
    final rarityColor = _getRarityColor();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        rarityColor.withOpacity(0.05),
        rarityColor.withOpacity(0.1),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
  }
}

/// Badge personalizado
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Badge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de raridade
class _RarityIndicator extends StatelessWidget {
  final ShopItemRarity rarity;

  const _RarityIndicator({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ...List.generate(5, (index) {
          final isFilled = index < _getRarityStars();
          return Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: Color(rarity.colorValue),
            size: 12,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rarity.displayName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Color(rarity.colorValue),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  int _getRarityStars() {
    switch (rarity) {
      case ShopItemRarity.common:
        return 1;
      case ShopItemRarity.rare:
        return 2;
      case ShopItemRarity.epic:
        return 3;
      case ShopItemRarity.legendary:
        return 4;
      case ShopItemRarity.exclusive:
        return 5;
    }
  }
}

/// Display de preço
class _PriceDisplay extends StatelessWidget {
  final ShopItem item;
  final bool canAfford;

  const _PriceDisplay({required this.item, required this.canAfford});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryPrice = item.primaryPrice;

    if (primaryPrice == null) {
      return const Text('Preço indisponível');
    }

    final finalPrice = item.isOnSale
        ? item.getDiscountedPrice(primaryPrice)!
        : primaryPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current price
        Row(
          children: [
            Text(
              finalPrice.currencyType.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              finalPrice.amount.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: canAfford ? AppColors.success : AppColors.error,
              ),
            ),
            if (finalPrice.label != null) ...[
              const SizedBox(width: 8),
              Text(
                finalPrice.label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),

        // Original price (if on sale)
        if (item.isOnSale && primaryPrice.amount != finalPrice.amount) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                primaryPrice.currencyType.emoji,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                primaryPrice.amount.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],

        // Alternative prices
        if (item.prices.length > 1) ...[
          const SizedBox(height: 4),
          Text(
            'ou ${item.prices.length - 1} outra${item.prices.length > 2 ? 's' : ''} opçõ${item.prices.length > 2 ? 'es' : 'ão'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Botão de compra
class _PurchaseButton extends ConsumerWidget {
  final ShopItem item;
  final bool canAfford;
  final VoidCallback? onPressed;

  const _PurchaseButton({
    required this.item,
    required this.canAfford,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final isLoading = shopState.isLoading;

    String buttonText;
    Color? buttonColor;
    Color? textColor;

    if (!item.isCurrentlyAvailable) {
      buttonText = 'Indisponível';
      buttonColor = Colors.grey;
      textColor = Colors.white;
    } else if (!canAfford) {
      buttonText = 'Moedas Insuficientes';
      buttonColor = AppColors.error.withOpacity(0.2);
      textColor = AppColors.error;
    } else {
      buttonText = 'Comprar';
      buttonColor = AppColors.primary;
      textColor = Colors.white;
    }

    return ElevatedButton(
      onPressed: item.isCurrentlyAvailable && canAfford && !isLoading
          ? onPressed
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
    );
  }
}

/// Indicador de estoque
class _StockIndicator extends StatelessWidget {
  final int stock;

  const _StockIndicator({required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = stock <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowStock ? AppColors.warning : AppColors.info,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            stock.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Padrão de fundo decorativo
class _BackgroundPattern extends StatelessWidget {
  final Color color;

  const _BackgroundPattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(color: color),
      child: Container(),
    );
  }
}

/// Painter para criar padrão decorativo
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cria círculos decorativos
    final radius = size.width * 0.1;

    // Círculo superior direito
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      radius,
      paint,
    );

    // Círculo inferior esquerdo
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      radius * 0.7,
      paint,
    );

    // Círculo central menor
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      radius * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card compacto para inventário
class CompactPowerUpCard extends ConsumerWidget {
  final ShopItem item;
  final int quantity;
  final VoidCallback? onTap;

  const CompactPowerUpCard({
    super.key,
    required this.item,
    required this.quantity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(item.rarity.colorValue).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(item.rarity.colorValue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.rarity.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Color(item.rarity.colorValue),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x$quantity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
