// lib/features/home/screens/modern_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/challenge_carousel.dart';
import 'package:unlock/features/home/widgets/custom_bottom_nav.dart';
import 'package:unlock/features/home/widgets/featured_groups_widget.dart';
import 'package:unlock/features/home/widgets/quick_stats_widget.dart';
import 'package:unlock/features/home/widgets/recent_activity_widget.dart';
import 'package:unlock/features/home/widgets/settings_bottom_sheet.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

/// 🚀 Nova Home Screen Otimizada - Sem Overflow e Espaços Reduzidos
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen>
    with TickerProviderStateMixin {
  // 🎬 Controladores de animação simplificados
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // 📱 Animações principais
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 📜 Controle de scroll
  final ScrollController _scrollController = ScrollController();
  bool _showElevatedAppBar = false;

  // 🔄 Estado da navegação
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _startAnimations();

    AppLogger.info('🏠 ModernHomeScreen: Iniciada com animações otimizadas');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🎬 Configurar animações simplificadas
  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
  }

  /// 📜 Configurar listener do scroll
  void _setupScrollListener() {
    _scrollController.addListener(() {
      final shouldShowElevated = _scrollController.offset > 50;
      if (_showElevatedAppBar != shouldShowElevated) {
        setState(() => _showElevatedAppBar = shouldShowElevated);
      }
    });
  }

  /// 🚀 Iniciar animações
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return _buildUnauthorizedScreen();
    }

    final user = authState.user!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🎯 AppBar otimizada
      appBar: _buildOptimizedAppBar(context, user),

      // 📱 Conteúdo principal otimizado
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildOptimizedContent(context, user),
            ),
          );
        },
      ),

      // 🎮 FAB simplificado
      floatingActionButton: _buildSimpleFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔄 Bottom Navigation
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  /// 🎯 AppBar otimizada
  PreferredSizeWidget _buildOptimizedAppBar(
    BuildContext context,
    UserModel user,
  ) {
    return AppBar(
      backgroundColor: _showElevatedAppBar
          ? Theme.of(context).colorScheme.surface.withOpacity(0.95)
          : Colors.transparent,
      elevation: _showElevatedAppBar ? 4 : 0,
      scrolledUnderElevation: 0,

      // 👤 Avatar compacto
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => context.push('/profile'),
          child: Hero(
            tag: 'user_avatar',
            child: AvatarCircle(imageUrl: user.avatar),
          ),
        ),
      ),

      // 🏆 Título compacto
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ClashUp',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (!_showElevatedAppBar)
            Text(
              'Olá, ${user.displayName.split(' ').first}! 👋',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ),

      // ⚙️ Actions compactas
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  /// 📱 Conteúdo principal otimizado - SEM OVERFLOW
  Widget _buildOptimizedContent(BuildContext context, UserModel user) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80), // Espaço para BottomNav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎮 Hero Section compacta
            _buildCompactHeroSection(context),

            const SizedBox(height: 6),

            // 📊 Stats Rápidas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickStatsWidget(user: user),
            ),

            const SizedBox(height: 20),

            // 🎯 Ações Rápidas otimizadas
            _buildOptimizedQuickActions(context),

            const SizedBox(height: 20),

            // 👥 Meus Grupos
            _buildCompactSection(
              context,
              title: 'Meus Grupos',
              icon: Icons.groups,
              onSeeAll: () => context.push('/groups'),
              child: const FeaturedGroupsWidget(),
            ),

            const SizedBox(height: 20),

            // 📈 Atividade Recente
            _buildCompactSection(
              context,
              title: 'Atividade Recente',
              icon: Icons.timeline,
              child: const RecentActivityWidget(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎮 Hero Section compacta
  Widget _buildCompactHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desafios Ativos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Compete e mostre suas habilidades',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ChallengeCarousel(),
        ],
      ),
    );
  }

  /// 🎯 Ações rápidas otimizadas
  Widget _buildOptimizedQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Criar Desafio',
        icon: Icons.add_circle_outline,
        color: Colors.green,
        onTap: () => context.push('/challenges/create'),
      ),
      _QuickAction(
        title: 'Entrar em Desafio',
        icon: Icons.sports_esports,
        color: Colors.blue,
        onTap: () => context.push('/challenges'),
      ),
      _QuickAction(
        title: 'Meus Grupos',
        icon: Icons.groups,
        color: Colors.purple,
        onTap: () => context.push('/groups'),
      ),
      _QuickAction(
        title: 'Mini Games',
        icon: Icons.videogame_asset,
        color: Colors.red,
        onTap: () => context.push('/mini-games'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚡ Ações Rápidas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: constraints.maxWidth * 0.25, // Altura fixa
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  return _buildCompactActionCard(context, actions[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🎯 Card de ação compacto
  Widget _buildCompactActionCard(BuildContext context, _QuickAction action) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: action.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    action.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📦 Seção compacta
  Widget _buildCompactSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('Ver Todos')),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// 🎮 FAB simplificado
  Widget _buildSimpleFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreateMenu(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// 📱 Tela não autorizada
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Acesso não autorizado',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Faça login para continuar',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Fazer Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔄 Refresh dos dados
  Future<void> _refreshData() async {
    AppLogger.info('🔄 Refreshing home data');
    await Future.delayed(const Duration(seconds: 1));

    // Restart simples das animações
    _fadeController.reset();
    _slideController.reset();
    _startAnimations();
  }

  /// 🔔 Mostrar notificações
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Notificações'),
        content: const Text(
          'Sistema de notificações será implementado em breve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Mostrar configurações
  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  /// 🎮 Menu de criação otimizado
  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '➕ Criar Novo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCreateMenuItem(
              context,
              'Desafio',
              'Crie um novo desafio',
              Icons.emoji_events,
              Colors.amber,
              () => context.push('/challenges/create'),
            ),
            _buildCreateMenuItem(
              context,
              'Grupo',
              'Forme um novo grupo',
              Icons.group_add,
              Colors.blue,
              () => context.push('/groups/create'),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Item do menu de criação
  Widget _buildCreateMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔄 Navegação bottom nav
  void _onBottomNavTapped(int index) {
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0: // Home - já estamos aqui
        break;
      case 1: // Grupos
        context.push('/groups');
        break;
      case 3: // Rankings (pula index 2 que é FAB)
        context.push('/rankings');
        break;
      case 4: // Perfil
        context.push('/profile');
        break;
    }
  }
}

/// 🎯 Classe para ações rápidas otimizada
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
