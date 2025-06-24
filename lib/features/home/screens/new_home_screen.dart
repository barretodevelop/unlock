// lib/features/home/screens/new_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/challenge_carousel.dart';
import 'package:unlock/features/home/widgets/custom_bottom_nav.dart';
import 'package:unlock/features/home/widgets/featured_groups_widget.dart';
import 'package:unlock/features/home/widgets/floating_action_menu.dart';
import 'package:unlock/features/home/widgets/home_header.dart';
import 'package:unlock/features/home/widgets/modern_app_bar.dart';
import 'package:unlock/features/home/widgets/quick_stats_widget.dart';
import 'package:unlock/features/home/widgets/recent_activity_widget.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/challenge_provider.dart';
import 'package:unlock/providers/group_provider.dart';

/// Nova home screen refinada com AppBar moderna, NavigationBar e FAB central
class NewHomeScreen extends ConsumerStatefulWidget {
  const NewHomeScreen({super.key});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends ConsumerState<NewHomeScreen>
    with TickerProviderStateMixin {
  // Controladores de animação
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Scroll controller para AppBar dinâmica
  final ScrollController _scrollController = ScrollController();
  bool _showElevatedAppBar = false;

  // Controle de navegação bottom
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();

    AppLogger.info('🏠 NewHomeScreen: Iniciada');

    // Configurar animações principais
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    // Controlador específico para FAB
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    // Listener para scroll e AppBar dinâmica
    _scrollController.addListener(_onScroll);

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    AppLogger.info('🧹 NewHomeScreen: Disposed');
    super.dispose();
  }

  /// Detectar scroll para AppBar dinâmica
  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showElevatedAppBar) {
      setState(() {
        _showElevatedAppBar = shouldShow;
      });
    }
  }

  /// Handler para navegação bottom
  void _onBottomNavTapped(int index) {
    AppLogger.navigation('🧭 Bottom nav tapped: $index');

    setState(() {
      _currentBottomIndex = index;
    });

    // Navegar para rotas correspondentes
    switch (index) {
      case 0: // Home - já estamos aqui
        break;
      case 1: // Grupos
        context.push('/groups');
        break;
      case 3: // Rankings
        context.push('/rankings');
        break;
      case 4: // Perfil
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.whenState(
      data: (state) {
        if (!state.isAuthenticated || state.user == null) {
          return _buildUnauthenticatedScreen();
        }
        return _buildAuthenticatedHome(state.user!);
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) {
        return _buildErrorScreen(error);
      },
    );
  }

  /// Construir home autenticada
  Widget _buildAuthenticatedHome(UserModel user) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              // AppBar moderna com elevação dinâmica
              appBar: ModernAppBar(
                user: user,
                showElevated: _showElevatedAppBar,
                onNotificationsTap: () => _showNotificationsDialog(context),
                onProfileTap: () => context.push('/profile'),
              ),

              // Corpo principal
              body: _buildMainContent(user),

              // FAB central expansível
              floatingActionButton: FloatingActionMenu(
                controller: _fabController,
                onCreateGroup: () => context.push('/groups/create'),
                onCreateChallenge: () => context.push('/challenges/create'),
                onInviteFriends: () => _showInviteDialog(context),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,

              // Bottom Navigation
              bottomNavigationBar: CustomBottomNav(
                currentIndex: _currentBottomIndex,
                onTap: _onBottomNavTapped,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Conteúdo principal da home
  Widget _buildMainContent(UserModel user) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header com gradiente otimizado
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

          // Espaço final para bottom nav
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

  /// Tela de loading
  Widget _buildLoadingScreen() {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  /// Tela de erro
  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Tela não autenticada
  Widget _buildUnauthenticatedScreen() {
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

  // ========== MÉTODOS AUXILIARES ==========

  /// Atualizar dados
  Future<void> _refreshData() async {
    AppLogger.info('🔄 Atualizando dados da nova home');

    // Invalidar providers para forçar reload
    ref.invalidate(userGroupsProvider);
    ref.invalidate(activeChallengesProvider);

    // Simular delay para mostrar loading
    await Future.delayed(const Duration(seconds: 1));
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
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de convite
  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar Amigos'),
        content: const Text('Sistema de convites em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
