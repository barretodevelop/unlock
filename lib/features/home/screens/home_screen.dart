// lib/features/home/screens/home_screen.dart - CORRIGIDA PARA EVITAR OVERFLOW
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/challenge_carousel.dart';
import 'package:unlock/features/home/widgets/featured_groups_widget.dart';
import 'package:unlock/features/home/widgets/home_header.dart';
import 'package:unlock/features/home/widgets/quick_stats_widget.dart';
import 'package:unlock/features/home/widgets/recent_activity_widget.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/challenge_provider.dart';
import 'package:unlock/providers/group_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showElevatedAppBar = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🏠 HomeScreen: Iniciada');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Listener para scroll
    _scrollController.addListener(_onScroll);

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    AppLogger.info('🧹 HomeScreen: Disposed');
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showElevatedAppBar) {
      setState(() {
        _showElevatedAppBar = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((state) => state.user));

    if (user == null) {
      return _buildNotAuthenticatedState(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // ✅ CORRIGIDO: Não estender body atrás da AppBar para evitar problemas de layout
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(context),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(context, user),
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  /// App bar adaptável
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: AnimatedOpacity(
        opacity: _showElevatedAppBar ? 1.0 : 0.0,
        duration: AppConstants.animationDuration,
        child: const Text('ClashUp'),
      ),
      backgroundColor: _showElevatedAppBar
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      elevation: _showElevatedAppBar ? 2 : 0,
      scrolledUnderElevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotificationsDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/profile'),
        ),
      ],
    );
  }

  /// Conteúdo principal
  Widget _buildContent(BuildContext context, UserModel user) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header com gradiente e saudação - ✅ CORRIGIDO: Usar SliverToBoxAdapter
          SliverToBoxAdapter(child: HomeHeader(user: user)),

          // Estatísticas rápidas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickStatsWidget(user: user),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Desafios em destaque
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Desafios em Destaque',
              subtitle: 'Competições acontecendo agora',
              icon: Icons.emoji_events,
              onSeeAll: () => context.push('/challenges'),
              child: const ChallengeCarousel(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Grupos em destaque
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Seus Grupos',
              subtitle: 'Conecte-se e compete',
              icon: Icons.group,
              onSeeAll: () => context.push('/groups'),
              child: const FeaturedGroupsWidget(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Atividade recente
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              title: 'Atividade Recente',
              subtitle: 'O que está rolando',
              icon: Icons.timeline,
              child: const RecentActivityWidget(),
            ),
          ),

          // Quick Actions Grid
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(child: _buildQuickActionsSection(context)),

          // Espaço final
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Construir seção com título
  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(context, title, subtitle, icon, onSeeAll),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Cabeçalho da seção
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? subtitle,
    IconData icon,
    VoidCallback? onSeeAll,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Ver Todos')),
      ],
    );
  }

  /// Seção de ações rápidas
  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            context,
            'Ações Rápidas',
            'O que você quer fazer?',
            Icons.flash_on,
            null,
          ),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(context),
        ],
      ),
    );
  }

  /// Grid de ações rápidas
  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Criar Desafio',
        icon: Icons.add_task,
        color: Colors.orange,
        onTap: () => context.push('/challenges/create'),
      ),
      _QuickAction(
        title: 'Novo Grupo',
        icon: Icons.group_add,
        color: Colors.blue,
        onTap: () => context.push('/groups/create'),
      ),
      _QuickAction(
        title: 'Mini-Games',
        icon: Icons.games,
        color: Colors.purple,
        onTap: () => _showComingSoonDialog(context, 'Mini-Games'),
      ),
      _QuickAction(
        title: 'Rankings',
        icon: Icons.leaderboard,
        color: Colors.green,
        onTap: () => _showComingSoonDialog(context, 'Rankings'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(context, action);
      },
    );
  }

  /// Card de ação rápida
  Widget _buildQuickActionCard(BuildContext context, _QuickAction action) {
    return Container(
      decoration: BoxDecoration(
        color: action.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: action.color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: action.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// FAB principal
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateMenu(context),
      icon: const Icon(Icons.add),
      label: const Text('Criar'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
    );
  }

  /// Estado não autenticado
  Widget _buildNotAuthenticatedState(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Não Autenticado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login para acessar o dashboard',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Fazer Login'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTODOS ==========

  /// Atualizar dados
  Future<void> _refreshData() async {
    AppLogger.info('🔄 Atualizando dados da home');

    // Invalidar providers para forçar reload
    ref.invalidate(userGroupsProvider);
    ref.invalidate(activeChallengesProvider);

    // Simular delay para mostrar loading
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Mostrar menu de criação
  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'O que deseja criar?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('Novo Desafio'),
              subtitle: const Text('Crie um desafio para a comunidade'),
              onTap: () {
                Navigator.pop(context);
                context.push('/challenges/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Novo Grupo'),
              subtitle: const Text('Conecte-se com amigos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/create');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Mostrar diálogo de notificações
  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificações'),
        content: const Text('Sistema de notificações em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo "Em breve"
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature estará disponível em breve!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Classe para ações rápidas
class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
