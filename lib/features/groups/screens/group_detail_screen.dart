// lib/features/groups/screens/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/groups/groups/widgets/member_list_tile.dart';
import 'package:unlock/models/group_model.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/group_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    AppLogger.info(
      '👁️ GroupDetailScreen: Iniciado para grupo ${widget.groupId}',
    );

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
    _animationController.dispose();
    AppLogger.info('🧹 GroupDetailScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final currentUser = ref.watch(authProvider.select((state) => state.user));

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
              child: groupAsync.when(
                data: (group) => group != null
                    ? _buildContent(context, group, currentUser)
                    : _buildNotFoundState(context),
                loading: () => _buildLoadingState(context),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construir conteúdo principal
  Widget _buildContent(
    BuildContext context,
    GroupModel group,
    UserModel? currentUser,
  ) {
    final isMember = currentUser != null && group.isMember(currentUser.uid);
    final isAdmin = currentUser != null && group.isAdmin(currentUser.uid);
    final isCreator = currentUser != null && group.isCreator(currentUser.uid);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildSliverAppBar(context, group, isMember, isAdmin, isCreator),
        ];
      },
      body: _buildBody(context, group, isMember, isAdmin, isCreator),
    );
  }

  /// App bar expansível
  Widget _buildSliverAppBar(
    BuildContext context,
    GroupModel group,
    bool isMember,
    bool isAdmin,
    bool isCreator,
  ) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (isMember)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value, group),
            itemBuilder: (context) => [
              if (isAdmin) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Editar Grupo'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 16),
                      SizedBox(width: 8),
                      Text('Convidar'),
                    ],
                  ),
                ),
              ],
              if (!isCreator)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Sair do Grupo',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              if (isCreator)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Desativar Grupo',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Avatar do grupo
                  AvatarCircle(
                    imageUrl: group.avatar.startsWith('http')
                        ? group.avatar
                        : null,
                    // fallbackText: group.avatar.startsWith('http')
                    //     ? null
                    //     : group.avatar,
                    // radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),

                  const SizedBox(height: 16),

                  // Nome e tipo
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              group.type.icon,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              group.type.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPrivacyIcon(group.privacy),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              group.privacy.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Corpo da tela
  Widget _buildBody(
    BuildContext context,
    GroupModel group,
    bool isMember,
    bool isAdmin,
    bool isCreator,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Estatísticas
        _buildStatsSection(context, group),

        const SizedBox(height: 24),

        // Descrição
        if (group.description.isNotEmpty) ...[
          _buildDescriptionSection(context, group),
          const SizedBox(height: 24),
        ],

        // Ações principais
        if (!isMember) ...[
          _buildJoinSection(context, group),
          const SizedBox(height: 24),
        ],

        // Lista de membros
        _buildMembersSection(context, group, isAdmin),

        const SizedBox(height: 24),

        // Desafios do grupo (placeholder)
        _buildChallengesSection(context, group),

        const SizedBox(height: 100), // Espaço extra
      ],
    );
  }

  /// Seção de estatísticas
  Widget _buildStatsSection(BuildContext context, GroupModel group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Membros',
              '${group.memberCount}/${group.maxMembers}',
              Icons.people,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Criado',
              _formatCreatedDate(group.createdAt),
              Icons.calendar_today,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Status',
              group.isActive ? 'Ativo' : 'Inativo',
              group.isActive ? Icons.check_circle : Icons.pause_circle,
              color: group.isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Seção de descrição
  Widget _buildDescriptionSection(BuildContext context, GroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre o Grupo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            group.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  /// Seção para entrar no grupo
  Widget _buildJoinSection(BuildContext context, GroupModel group) {
    final actionState = ref.watch(groupActionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_add,
            color: Theme.of(context).colorScheme.primary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Quer fazer parte?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Entre no grupo e participe dos desafios!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: actionState.isLoading || group.isFull
                  ? null
                  : () => _joinGroup(group.id),
              icon: actionState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
              label: Text(
                actionState.isLoading
                    ? 'Entrando...'
                    : group.isFull
                    ? 'Grupo Cheio'
                    : 'Entrar no Grupo',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de membros
  Widget _buildMembersSection(
    BuildContext context,
    GroupModel group,
    bool isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Membros',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${group.memberCount}/${group.maxMembers}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de membros (placeholder - seria carregada separadamente)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Criador sempre primeiro
              MemberListTile(
                userId: group.creatorId,
                isCreator: true,
                isAdmin: true,
                canManage: false, // Criador não pode ser gerenciado
              ),

              // Placeholder para outros membros
              if (group.memberCount > 1) ...[
                const Divider(),
                Text(
                  '+ ${group.memberCount - 1} outros membros',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Seção de desafios (placeholder)
  Widget _buildChallengesSection(BuildContext context, GroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desafios do Grupo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Em Breve!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Desafios exclusivos do grupo serão implementados em breve.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== ESTADOS ==========

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carregando...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
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
              'Erro ao carregar grupo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grupo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Grupo não encontrado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  IconData _getPrivacyIcon(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return Icons.public;
      case GroupPrivacy.private:
        return Icons.lock;
      case GroupPrivacy.secret:
        return Icons.visibility_off;
    }
  }

  String _formatCreatedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} mês${diff.inDays > 60 ? 'es' : ''}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    } else {
      return 'Hoje';
    }
  }

  // ========== AÇÕES ==========

  void _joinGroup(String groupId) {
    AppLogger.info('👤 Tentando entrar no grupo: $groupId');
    ref.read(groupActionProvider.notifier).joinGroup(groupId);
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    GroupModel group,
  ) {
    AppLogger.debug('🎯 Ação do menu: $action');

    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'invite':
        _showInviteDialog(context, group);
        break;
      case 'leave':
        _showLeaveDialog(context, group);
        break;
      case 'deactivate':
        _showDeactivateDialog(context, group);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Grupo'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar Membros'),
        content: const Text('Sistema de convites em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Grupo'),
        content: Text('Tem certeza que deseja sair do grupo "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(groupActionProvider.notifier).leaveGroup(group.id);
              context.pop(); // Voltar para a lista
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Grupo'),
        content: Text(
          'Tem certeza que deseja desativar o grupo "${group.name}"? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar desativação
              context.pop(); // Voltar para a lista
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  void _handleActionMessages(BuildContext context, GroupActionState state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
