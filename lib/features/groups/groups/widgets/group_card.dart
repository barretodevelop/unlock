// lib/features/groups/widgets/group_card.dart - VERSÃO CORRIGIDA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/group_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/group_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart'; // ✅ USAR VERSÃO ATUALIZADA

class GroupCard extends ConsumerWidget {
  final GroupModel group;
  final bool isPublic;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;

  const GroupCard({
    super.key,
    required this.group,
    this.isPublic = false,
    this.onTap,
    this.onJoin,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider.select((state) => state.user));
    final actionState = ref.watch(groupActionProvider);
    
    // Verificar se usuário é membro
    final isMember = currentUser != null && group.isMember(currentUser.uid);
    final isAdmin = currentUser != null && group.isAdmin(currentUser.uid);
    final isCreator = currentUser != null && group.isCreator(currentUser.uid);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                const SizedBox(height: 12),
                _buildDescription(context),
                const SizedBox(height: 12),
                _buildStats(context),
                const SizedBox(height: 16),
                _buildActions(context, ref, isMember, isAdmin, isCreator, actionState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir cabeçalho do card
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // ✅ CORRIGIDO: Usar GroupAvatar ou configurar corretamente
        GroupAvatar(
          imageUrl: group.avatar.startsWith('http') ? group.avatar : null,
          fallbackText: group.avatar.startsWith('http') ? null : group.avatar,
          radius: 24,
        ),
        const SizedBox(width: 12),
        
        // Nome e tipo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTypeChip(context),
                ],
              ),
              const SizedBox(height: 4),
              _buildPrivacyInfo(context),
            ],
          ),
        ),
        
        // Menu ou status
        _buildTrailingWidget(context),
      ],
    );
  }

  /// Construir chip do tipo de grupo
  Widget _buildTypeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group.type.icon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            group.type.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir informações de privacidade
  Widget _buildPrivacyInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getPrivacyIcon(),
          size: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          group.privacy.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (group.lastActivity != null) ...[
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatLastActivity(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  // ========== RESTO DOS MÉTODOS INALTERADOS ==========
  
  Widget _buildTrailingWidget(BuildContext context) {
    if (isPublic) {
      return Icon(
        Icons.explore,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      );
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        size: 20,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16),
              SizedBox(width: 8),
              Text('Detalhes'),
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
        if (!isPublic)
          const PopupMenuItem(
            value: 'leave',
            child: Row(
              children: [
                Icon(Icons.exit_to_app, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Sair', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (group.description.isEmpty) return const SizedBox.shrink();

    return Text(
      group.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          context,
          icon: Icons.people,
          value: '${group.memberCount}',
          label: group.memberCount == 1 ? 'membro' : 'membros',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context,
          icon: Icons.workspace_premium,
          value: '${group.maxMembers}',
          label: 'máximo',
        ),
        const Spacer(),
        _buildStatusIndicator(context),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final color = group.isActive ? Colors.green : Colors.grey;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          group.isActive ? 'Ativo' : 'Inativo',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    bool isMember,
    bool isAdmin,
    bool isCreator,
    GroupActionState actionState,
  ) {
    if (isPublic && !isMember) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: actionState.isLoading ? null : () => _joinGroup(ref),
          icon: actionState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add, size: 18),
          label: Text(actionState.isLoading ? 'Entrando...' : 'Entrar no Grupo'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (isMember) {
      return Row(
        children: [
          if (isCreator) ...[
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              'Criador',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else if (isAdmin) ...[
            Icon(
              Icons.admin_panel_settings,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Admin',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              'Membro',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: () => onTap?.call(),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Ver Grupo'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ========== MÉTODOS AUXILIARES ==========

  IconData _getPrivacyIcon() {
    switch (group.privacy) {
      case GroupPrivacy.public:
        return Icons.public;
      case GroupPrivacy.private:
        return Icons.lock;
      case GroupPrivacy.secret:
        return Icons.visibility_off;
    }
  }

  String _formatLastActivity() {
    if (group.lastActivity == null) return 'Novo';

    final now = DateTime.now();
    final diff = now.difference(group.lastActivity!);

    if (diff.inDays > 7) {
      return 'Há ${diff.inDays} dias';
    } else if (diff.inDays > 0) {
      return 'Há ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
    } else if (diff.inHours > 0) {
      return 'Há ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Há ${diff.inMinutes}min';
    } else {
      return 'Agora mesmo';
    }
  }

  // ========== AÇÕES ==========

  void _joinGroup(WidgetRef ref) {
    AppLogger.info('👤 Tentando entrar no grupo: ${group.id}');
    
    ref.read(groupActionProvider.notifier).joinGroup(group.id).then((success) {
      if (success) {
        onJoin?.call();
      }
    });
  }

  void _handleMenuAction(BuildContext context, String action) {
    AppLogger.debug('🎯 Ação do menu: $action');
    
    switch (action) {
      case 'details':
        onTap?.call();
        break;
      case 'invite':
        _showInviteDialog(context);
        break;
      case 'leave':
        _showLeaveDialog(context);
        break;
    }
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar para o Grupo'),
        content: const Text('Funcionalidade de convite em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Grupo'),
        content: Text('Tem certeza que deseja sair do grupo "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLeave?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
 