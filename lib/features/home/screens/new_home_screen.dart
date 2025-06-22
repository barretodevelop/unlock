// lib/features/home/screens/home_screen.dart - Versão Otimizada
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/home/widgets/animated_floating_button.dart';
import 'package:unlock/features/home/widgets/animated_stats_card.dart';
import 'package:unlock/features/home/widgets/connection_suggestions_carousel.dart';
import 'package:unlock/features/home/widgets/custom_refresh_indicator.dart';
import 'package:unlock/features/home/widgets/mini_mission_card.dart';
import 'package:unlock/features/home/widgets/mood_selector_widget.dart';
import 'package:unlock/features/home/widgets/quick_actions_grid.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';

/// Tela principal otimizada com widgets modulares e animações
class NewHomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<NewHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<NewHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🏠 HomeScreen inicializada');

    _setupAnimations();
    _scrollController = ScrollController();

    // Iniciar animação principal
    _mainController.forward();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: AnimationConstants.mediumDelay,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: AnimationConstants.enterCurve,
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final missionsState = ref.watch(missionsProvider);
    final isDark = ref.watch(themeProvider);
    final theme = Theme.of(context);

    // Verificação de autenticação otimizada
    if (!authState.isAuthenticated || authState.user == null) {
      return _buildAuthRedirect(theme);
    }

    final user = authState.user!;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: _buildOptimizedAppBar(context, theme, user, isDark),
            body: CustomRefreshIndicator(
              onRefresh: () => _handleRefreshData(context),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Card de estatísticas animado
                  SliverToBoxAdapter(
                    child: AnimatedStatsCard(
                      user: user,
                      onTap: () => _navigateToProfile(context),
                    ),
                  ),

                  // Seletor de humor com emojis
                  SliverToBoxAdapter(child: MoodSelectorWidget(user: user)),

                  // Ações rápidas em grid
                  const SliverToBoxAdapter(child: QuickActionsGrid()),

                  // Carrossel de sugestões
                  const SliverToBoxAdapter(
                    child: ConnectionSuggestionsCarousel(),
                  ),

                  // Seção de missões compacta
                  SliverToBoxAdapter(
                    child: _buildCompactMissionsSection(
                      context,
                      theme,
                      missionsState,
                    ),
                  ),

                  // Espaço para floating button
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppConstants.bottomNavHeight),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(context, theme),
            floatingActionButton: const AnimatedFloatingButton(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }

  /// Widget de redirecionamento de auth otimizado
  Widget _buildAuthRedirect(ThemeData theme) {
    AppLogger.warning('🏠 HomeScreen: Redirecionamento de auth necessário');

    // Agendar redirecionamento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          GoRouterState.of(context).uri.toString() != AppRoutes.login) {
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              'Verificando autenticação...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AppBar otimizada
  PreferredSizeWidget _buildOptimizedAppBar(
    BuildContext context,
    ThemeData theme,
    UserModel user,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          _buildUserAvatar(context, theme, user),
          const SizedBox(width: AppConstants.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_getDisplayFirstName(user)}!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nível ${user.level} • ${ConstantsUtils.formatGameNumber(user.xp)} XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Botão de tema
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(themeProvider.notifier).toggleTheme();
          },
          icon: AnimatedSwitcher(
            duration: AnimationConstants.shortDelay,
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(isDark),
            ),
          ),
          tooltip: 'Alternar tema',
        ),

        // Menu de ações
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Perfil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Configurações'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Sair', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Avatar do usuário otimizado
  Widget _buildUserAvatar(
    BuildContext context,
    ThemeData theme,
    UserModel user,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToProfile(context);
      },
      child: Container(
        width: AppConstants.avatarSize,
        height: AppConstants.avatarSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: AppConstants.avatarBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: user.avatar != null && user.avatar!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: user.avatar!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildAvatarPlaceholder(theme),
                  errorWidget: (context, url, error) =>
                      _buildAvatarFallback(theme, user),
                )
              : _buildAvatarFallback(theme, user),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(ThemeData theme, UserModel user) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          _getAvatarInitial(user),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.fontSizeAvatarInitial,
          ),
        ),
      ),
    );
  }

  /// Seção de missões compacta
  Widget _buildCompactMissionsSection(
    BuildContext context,
    ThemeData theme,
    dynamic missionsState,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Missões Ativas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.missions),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          _buildMissionsList(context, theme, missionsState),
        ],
      ),
    );
  }

  /// Lista de missões otimizada
  Widget _buildMissionsList(
    BuildContext context,
    ThemeData theme,
    dynamic missionsState,
  ) {
    if (missionsState.isLoading) {
      return _buildMissionsLoading(theme);
    }

    if (missionsState.error != null) {
      return _buildMissionsError(theme);
    }

    if (missionsState.availableMissions.isEmpty) {
      return _buildMissionsEmpty(theme);
    }

    // Mostrar até 3 missões na home
    // final missionsToShow = missionsState.availableMissions.take(3).toList();

    // return Column(
    //   children: missionsToShow.asMap().entries.map((entry) {
    //     final index = entry.key;
    //     final mission = entry.value;
    //     final progress = missionsState.userProgress[mission.id];

    //     return TweenAnimationBuilder<double>(
    //       duration: Duration(milliseconds: (300 + (index * 100)).toInt()),
    //       tween: Tween<double>(begin: 0.0, end: 1.0),
    //       builder: (context, value, child) {
    //         return Transform.translate(
    //           offset: Offset(0, 20 * (1 - value)),
    //           child: Opacity(
    //             opacity: value,
    //             child: MiniMissionCard(
    //               mission: mission,
    //               progress: progress,
    //               onTap: () => _handleMissionTap(context, mission.id),
    //             ),
    //           ),
    //         );
    //       },
    //     );
    //   }).toList(),
    // );

    // ✅ MISSÕES DISPONÍVEIS - mostrar até 3 na home
    final missionsToShow = missionsState.availableMissions.take(3).toList();

    return Column(
      children: List<Widget>.from(
        missionsToShow.map((mission) {
          final progress = missionsState.userProgress[mission.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
            child: MiniMissionCard(
              mission: mission,
              progress: progress,
              onTap: () => _handleMissionTap(context, mission.id),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMissionsLoading(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.spacingLarge),
          Text('Carregando missões...'),
        ],
      ),
    );
  }

  Widget _buildMissionsError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppConstants.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erro ao carregar missões',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  'Toque em "Ver todas" para tentar novamente',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsEmpty(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppConstants.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhuma missão disponível',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Volte em breve para novas aventuras!',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation otimizada
  Widget _buildBottomNav(BuildContext context, ThemeData theme) {
    final String currentLocation = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;

    if (currentLocation.startsWith(AppRoutes.missions)) {
      currentIndex = 1;
    } else if (currentLocation.startsWith(AppRoutes.connections)) {
      currentIndex = 2;
    } else if (currentLocation.startsWith(AppRoutes.profile)) {
      currentIndex = 3;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleBottomNavTap(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Missões'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Conexões'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }

  // ========== UTILS ==========

  String _getDisplayFirstName(UserModel user) {
    if (user.displayName.isNotEmpty) {
      final parts = user.displayName.trim().split(' ');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first;
      }
    }
    if (user.codinome != null && user.codinome!.trim().isNotEmpty) {
      return user.codinome!;
    }
    return 'Usuário';
  }

  String _getAvatarInitial(UserModel user) {
    if (user.displayName.isNotEmpty) {
      return user.displayName.trim().substring(0, 1).toUpperCase();
    }
    if (user.codinome != null && user.codinome!.trim().isNotEmpty) {
      return user.codinome!.trim().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  // ========== EVENT HANDLERS ==========

  Future<void> _handleRefreshData(BuildContext context) async {
    try {
      AppLogger.info('🔄 HomeScreen: Refreshing data');

      await Future.wait([
        ref.read(missionsProvider.notifier).refresh(),
        // Adicionar outros refreshes necessários
      ]);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.refresh, color: Colors.white),
                SizedBox(width: AppConstants.spacingMedium),
                Text('Dados atualizados!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ HomeScreen: Error refreshing data', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar dados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'profile':
        _navigateToProfile(context);
        break;
      case 'settings':
        context.go(AppRoutes.settings);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.missions);
        break;
      case 2:
        context.go(AppRoutes.connections);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  void _handleMissionTap(BuildContext context, String missionId) {
    HapticFeedback.lightImpact();
    context.go('${AppRoutes.missions}/$missionId');
  }

  void _navigateToProfile(BuildContext context) {
    context.go(AppRoutes.profile);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sair do App'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      AppLogger.info('🚪 HomeScreen: Performing logout');

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saindo...'),
            ],
          ),
        ),
      );

      await ref.read(authProvider.notifier).signOut();
      AppLogger.info('✅ HomeScreen: Logout successful');
    } catch (e) {
      AppLogger.error('❌ HomeScreen: Logout error', error: e);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao fazer logout. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
