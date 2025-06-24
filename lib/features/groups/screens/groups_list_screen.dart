// lib/features/groups/screens/groups_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/groups/groups/widgets/group_card.dart';
import 'package:unlock/models/group_model.dart';
import 'package:unlock/providers/group_provider.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.info('👥 GroupsListScreen: Iniciado');

    // Configurar tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    AppLogger.info('🧹 GroupsListScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escutar mensagens do provider
    ref.listen<GroupActionState>(groupActionProvider, (previous, current) {
      _handleActionMessages(context, current);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(context),
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  /// Construir conteúdo principal
  Widget _buildContent(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [_buildSliverAppBar(context, innerBoxIsScrolled)];
      },
      body: _buildTabBarView(context),
    );
  }

  /// Construir app bar expansível
  Widget _buildSliverAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final groupsCount = ref.watch(userGroupsCountProvider);

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Grupos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const SizedBox(height: 20),
                  Text(
                    'Seus Grupos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$groupsCount ${groupsCount == 1 ? 'grupo' : 'grupos'} · Conecte-se e compete!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.group), text: 'Meus Grupos'),
          Tab(icon: Icon(Icons.public), text: 'Descobrir'),
        ],
      ),
    );
  }

  /// Construir conteúdo das abas
  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [_buildMyGroupsTab(context), _buildDiscoverTab(context)],
    );
  }

  /// Aba "Meus Grupos"
  Widget _buildMyGroupsTab(BuildContext context) {
    final userGroupsAsync = ref.watch(userGroupsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.debug('🔄 Refresh dos grupos do usuário');
        ref.invalidate(userGroupsProvider);
      },
      child: userGroupsAsync.when(
        data: (groups) =>
            _buildGroupsList(context, groups, isEmpty: groups.isEmpty),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  /// Aba "Descobrir"
  Widget _buildDiscoverTab(BuildContext context) {
    final publicGroupsAsync = ref.watch(publicGroupsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.debug('🔄 Refresh dos grupos públicos');
        ref.invalidate(publicGroupsProvider);
      },
      child: publicGroupsAsync.when(
        data: (groups) => _buildGroupsList(context, groups, isPublic: true),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  /// Construir lista de grupos
  Widget _buildGroupsList(
    BuildContext context,
    List<GroupModel> groups, {
    bool isEmpty = false,
    bool isPublic = false,
  }) {
    if (isEmpty) {
      return _buildEmptyState(context, isPublic: isPublic);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GroupCard(
            group: group,
            isPublic: isPublic,
            onTap: () => _navigateToGroup(context, group.id),
          ),
        );
      },
    );
  }

  /// Estado de carregamento
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando grupos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado de erro
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Oops! Algo deu errado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar os grupos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                AppLogger.debug('🔄 Tentando novamente');
                ref.invalidate(userGroupsProvider);
                ref.invalidate(publicGroupsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado vazio
  Widget _buildEmptyState(BuildContext context, {bool isPublic = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPublic ? Icons.explore : Icons.group_add,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isPublic ? 'Explore Novos Grupos!' : 'Crie seu Primeiro Grupo!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPublic
                  ? 'Descubra grupos públicos e conecte-se com pessoas que compartilham seus interesses.'
                  : 'Conecte-se com amigos, familiares ou colegas criando grupos para desafios privados.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isPublic) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateGroup(context),
                icon: const Icon(Icons.add),
                label: const Text('Criar Grupo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Floating Action Button
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateGroup(context),
      icon: const Icon(Icons.add),
      label: const Text('Criar Grupo'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
    );
  }

  // ========== NAVEGAÇÃO ==========

  /// Navegar para criação de grupo
  void _navigateToCreateGroup(BuildContext context) {
    AppLogger.navigation('📍 Navegando para criação de grupo');
    context.push('/groups/create');
  }

  /// Navegar para detalhes do grupo
  void _navigateToGroup(BuildContext context, String groupId) {
    AppLogger.navigation('📍 Navegando para grupo: $groupId');
    context.push('/groups/$groupId');
  }

  // ========== HANDLERS ==========

  /// Manipular mensagens do provider
  void _handleActionMessages(BuildContext context, GroupActionState state) {
    if (state.error != null) {
      AppLogger.warning('⚠️ Erro no grupo: ${state.error}');
      _showSnackBar(context, state.error!, isError: true);
    }

    if (state.successMessage != null) {
      AppLogger.info('✅ Sucesso no grupo: ${state.successMessage}');
      _showSnackBar(context, state.successMessage!);
    }
  }

  /// Mostrar SnackBar
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
