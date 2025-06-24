// lib/shared/widgets/currency_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/models/currency_model.dart';
import 'package:unlock/providers/currency_provider.dart';

/// Widget para exibir as moedas do usuário
class CurrencyDisplay extends ConsumerWidget {
  final CurrencyDisplayStyle style;
  final bool showBoth;
  final CurrencyType? onlyShow;
  final VoidCallback? onTap;
  final bool showLoading;

  const CurrencyDisplay({
    super.key,
    this.style = CurrencyDisplayStyle.header,
    this.showBoth = true,
    this.onlyShow,
    this.onTap,
    this.showLoading = true,
  });

  const CurrencyDisplay.compact({super.key, this.onlyShow, this.onTap})
    : style = CurrencyDisplayStyle.compact,
      showBoth = false,
      showLoading = false;

  const CurrencyDisplay.large({super.key, this.showBoth = true, this.onTap})
    : style = CurrencyDisplayStyle.large,
      onlyShow = null,
      showLoading = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    if (currencyState.isLoading && showLoading) {
      return _LoadingDisplay(style: style);
    }

    if (currencyState.error != null) {
      return _ErrorDisplay(
        error: currencyState.error!,
        style: style,
        onRetry: () => ref.read(currencyProvider.notifier).refresh(),
      );
    }

    final shouldShowCoins = showBoth || onlyShow == CurrencyType.coins;
    final shouldShowGems = showBoth || onlyShow == CurrencyType.gems;

    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: _getPadding(),
            decoration: _getDecoration(theme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shouldShowCoins) ...[
                  _CurrencyItem(
                    type: CurrencyType.coins,
                    amount: currencyState.coins,
                    style: style,
                  ),
                  if (shouldShowGems) SizedBox(width: _getSpacing()),
                ],
                if (shouldShowGems)
                  _CurrencyItem(
                    type: CurrencyType.gems,
                    amount: currencyState.gems,
                    style: style,
                  ),
              ],
            ),
          ),
        )
        .animate(key: ValueKey(currencyState.lastUpdated))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }

  EdgeInsets _getPadding() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CurrencyDisplayStyle.compact:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CurrencyDisplayStyle.large:
        return const EdgeInsets.all(16);
    }
  }

  BoxDecoration? _getDecoration(ThemeData theme) {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        );
      case CurrencyDisplayStyle.compact:
        return null;
      case CurrencyDisplayStyle.large:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        );
    }
  }

  double _getSpacing() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return 12;
      case CurrencyDisplayStyle.compact:
        return 8;
      case CurrencyDisplayStyle.large:
        return 16;
    }
  }
}

/// Item individual de moeda
class _CurrencyItem extends StatelessWidget {
  final CurrencyType type;
  final int amount;
  final CurrencyDisplayStyle style;

  const _CurrencyItem({
    required this.type,
    required this.amount,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(type.emoji, style: TextStyle(fontSize: _getEmojiSize())),
        const SizedBox(width: 4),
        Text(_formatAmount(amount), style: _getTextStyle(theme)),
      ],
    );
  }

  double _getEmojiSize() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return 16;
      case CurrencyDisplayStyle.compact:
        return 14;
      case CurrencyDisplayStyle.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ) ??
            const TextStyle();
      case CurrencyDisplayStyle.compact:
        return theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ) ??
            const TextStyle();
      case CurrencyDisplayStyle.large:
        return theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: type == CurrencyType.coins
                  ? AppColors.warning
                  : AppColors.accent,
            ) ??
            const TextStyle();
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }
}

/// Widget de loading
class _LoadingDisplay extends StatelessWidget {
  final CurrencyDisplayStyle style;

  const _LoadingDisplay({required this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: _getPadding(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _getSize(),
            height: _getSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Carregando...', style: _getTextStyle(theme)),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CurrencyDisplayStyle.compact:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CurrencyDisplayStyle.large:
        return const EdgeInsets.all(16);
    }
  }

  double _getSize() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return 16;
      case CurrencyDisplayStyle.compact:
        return 14;
      case CurrencyDisplayStyle.large:
        return 20;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return theme.textTheme.bodyMedium ?? const TextStyle();
      case CurrencyDisplayStyle.compact:
        return theme.textTheme.bodySmall ?? const TextStyle();
      case CurrencyDisplayStyle.large:
        return theme.textTheme.headlineSmall ?? const TextStyle();
    }
  }
}

/// Widget de erro
class _ErrorDisplay extends StatelessWidget {
  final String error;
  final CurrencyDisplayStyle style;
  final VoidCallback? onRetry;

  const _ErrorDisplay({required this.error, required this.style, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: _getPadding(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: _getIconSize(),
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text('Erro', style: _getTextStyle(theme)),
          ],
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CurrencyDisplayStyle.compact:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CurrencyDisplayStyle.large:
        return const EdgeInsets.all(16);
    }
  }

  double _getIconSize() {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return 16;
      case CurrencyDisplayStyle.compact:
        return 14;
      case CurrencyDisplayStyle.large:
        return 20;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (style) {
      case CurrencyDisplayStyle.header:
        return theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ) ??
            const TextStyle();
      case CurrencyDisplayStyle.compact:
        return theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ) ??
            const TextStyle();
      case CurrencyDisplayStyle.large:
        return theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ) ??
            const TextStyle();
    }
  }
}

/// Widget animado para recompensas
class CurrencyRewardAnimation extends StatefulWidget {
  final int amount;
  final CurrencyType type;
  final VoidCallback? onCompleted;

  const CurrencyRewardAnimation({
    super.key,
    required this.amount,
    required this.type,
    this.onCompleted,
  });

  @override
  State<CurrencyRewardAnimation> createState() =>
      _CurrencyRewardAnimationState();
}

class _CurrencyRewardAnimationState extends State<CurrencyRewardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -2)).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward().then((_) {
      widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.type == CurrencyType.coins
                      ? AppColors.warning.withOpacity(0.9)
                      : AppColors.accent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (widget.type == CurrencyType.coins
                                  ? AppColors.warning
                                  : AppColors.accent)
                              .withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.type.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.amount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Estilos disponíveis para o display de moedas
enum CurrencyDisplayStyle {
  header, // Para o header principal
  compact, // Para espaços pequenos
  large, // Para destaque/perfil
}
