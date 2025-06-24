// lib/shared/widgets/app_header_with_currency.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/currency_display.dart';

/// AppBar personalizado com display de moedas
class AppHeaderWithCurrency extends ConsumerWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final bool showBackButton;
  final bool centerTitle;
  final VoidCallback? onCurrencyTap;

  const AppHeaderWithCurrency({
    super.key,
    required this.title,
    this.additionalActions,
    this.showBackButton = true,
    this.centerTitle = true,
    this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => context.pop(),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        // Currency Display
        if (authState.isAuthenticated) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CurrencyDisplay(
              style: CurrencyDisplayStyle.header,
              onTap:
                  onCurrencyTap ?? () => _showCurrencyBottomSheet(context, ref),
            ),
          ),
        ],

        // Additional actions
        if (additionalActions != null) ...additionalActions!,

        // Profile button
        if (authState.isAuthenticated)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _ProfileButton(user: authState.user!),
          ),
      ],
    );
  }

  /// Mostra bottom sheet com detalhes das moedas
  void _showCurrencyBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyBottomSheet(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Botão de perfil no header
class _ProfileButton extends ConsumerWidget {
  final dynamic user; // UserModel from auth

  const _ProfileButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            user.displayName?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet com detalhes das moedas
class _CurrencyBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Suas Moedas',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Currency display large
          Center(child: CurrencyDisplay.large()),
          const SizedBox(height: 32),

          // Recent transactions
          Text(
            'Transações Recentes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Transaction list
          _RecentTransactionsList(),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/shop');
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Loja'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/currency-history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico'),
                ),
              ),
            ],
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Lista de transações recentes
class _RecentTransactionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final transactionsAsync = ref.watch(currencyTransactionsProvider(userId));

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const _EmptyTransactions();
        }

        final recentTransactions = transactions.take(3).toList();

        return Column(
          children: recentTransactions.map((transaction) {
            return _TransactionTile(transaction: transaction);
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Erro ao carregar transações',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

/// Tile individual de transação
class _TransactionTile extends StatelessWidget {
  final dynamic transaction; // CurrencyTransaction

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = transaction.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Emoji da moeda
          Text(transaction.type.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),

          // Descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.reason.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimestamp(transaction.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Valor
          Text(
            '${isPositive ? '+' : ''}${transaction.amount}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isPositive ? AppColors.success : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}

/// Widget para quando não há transações
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma transação ainda',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete jogos para ganhar moedas!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
