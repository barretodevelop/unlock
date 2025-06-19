// lib/features/home/screens/home_screen.dart
// Home Screen com Feature de Missões Integrada e exibição de dados do usuário ajustada

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/level_calculator.dart'; // Importa o LevelCalculator
import 'package:unlock/features/missions/screens/missions_list_screen.dart'; // Importa a tela de missões
import 'package:unlock/models/user_model.dart'; // Importa o UserModel
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);

    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            // Avatar do usuário: usa user.avatar se for um URL, senão um fallback com a primeira letra
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: user.avatar.startsWith('http')
                  ? NetworkImage(user.avatar) as ImageProvider
                  : null,
              child: user.avatar.startsWith('http')
                  ? null
                  : Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.split(' ').first ?? 'Usuário',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nível ${user.level}', // Utiliza user.level diretamente do UserModel
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botão para alternar tema
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          // Botão de Logout
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              // Opcional: Navegar para a tela de login após o logout,
              // mas geralmente o sistema de roteamento já lida com isso
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Atualiza o usuário e, consequentemente, as missões e recompensas
          await ref.read(authProvider.notifier).refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Boas-vindas
              _WelcomeCard(user: user),

              const SizedBox(height: 16),

              // Card de Economia
              _EconomyCard(user: user),

              const SizedBox(height: 16),

              // Card Principal - Descobrir Conexões
              _DiscoveryCard(),

              const SizedBox(height: 16),

              // Card de Progresso (agora usando LevelCalculator)
              _ProgressCard(user: user),

              const SizedBox(height: 16),

              // Nova seção: Lista de Missões
              Text(
                'Suas Missões',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height:
                    300, // Altura fixa para a lista de missões dentro do SingleChildScrollView
                child: MissionsListScreen(), // Integra a tela de missões
              ),

              const SizedBox(height: 16), // Espaço após a lista de missões
              // Ações Rápidas (o ActionButton de missões será removido ou redirecionado)
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user});
  final UserModel user; // Usar UserModel tipado

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = user.displayName?.split(' ').first ?? 'Usuário';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pronto para novas conexões? 🔓',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lock_open_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}

class _EconomyCard extends StatelessWidget {
  const _EconomyCard({required this.user});
  final UserModel user; // Usar UserModel tipado

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EconomyItem(
              icon: '⚡',
              label: 'XP',
              value: user.xp, // Utiliza user.xp diretamente
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _EconomyItem(
              icon: '🪙',
              label: 'Coins',
              value: user.coins, // Utiliza user.coins diretamente
              color: Colors.amber,
            ),
          ),
          Expanded(
            child: _EconomyItem(
              icon: '�',
              label: 'Gems',
              value: user.gems, // Utiliza user.gems diretamente
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _EconomyItem extends StatelessWidget {
  const _EconomyItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          _formatValue(value),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatValue(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _DiscoveryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.radar, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localizar Conexões',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Encontre pessoas próximas com interesses similares',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔍 Iniciando busca por conexões...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Text(
                    'Começar Busca',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.user});
  final UserModel user; // Usar UserModel tipado

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xp = user.xp;
    final level = user.level; // user.level já é calculado no UserModel

    // Usar LevelCalculator para cálculos precisos
    final xpNeededForNextLevel = LevelCalculator.calculateXPToNextLevel(xp);
    final progress = LevelCalculator.calculateLevelProgress(xp);
    final nextLevel = level + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Progresso do Nível',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nível $level'),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam $xpNeededForNextLevel XP para o Nível $nextLevel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.assignment,
                label: 'Missões',
                // Removido o SnackBar e agora ele pode navegar para a tela de missões
                // Se a MissionsListScreen já está no body, você pode remover este botão
                // ou fazê-lo rolar para a seção de missões, se implementado.
                // Por agora, manterá o SnackBar para evitar navegação complexa de rota.
                onTap: () => _showSnackBar(context, 'Missões'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.people,
                label: 'Amigos',
                onTap: () => _showSnackBar(context, 'Amigos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.settings,
                label: 'Config',
                onTap: () => _showSnackBar(context, 'Configurações'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action será implementado em breve')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
