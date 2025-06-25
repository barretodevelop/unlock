// lib/features/groups/widgets/member_list_tile.dart - VERSÃO CORRIGIDA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/utils/logger.dart';

class MemberListTile extends ConsumerWidget {
  final String userId;
  final bool isCreator;
  final bool isAdmin;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onPromote;
  final VoidCallback? onRemove;

  const MemberListTile({
    super.key,
    required this.userId,
    this.isCreator = false,
    this.isAdmin = false,
    this.canManage = false,
    this.onTap,
    this.onPromote,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Em uma implementação real, buscaríamos os dados do usuário aqui
    return _buildMemberTile(
      context,
      userId: userId,
      username: _getMockUsername(userId),
      avatar: _getMockAvatar(userId),
      isOnline: _getMockOnlineStatus(userId),
    );
  }

  /// Construir tile do membro
  Widget _buildMemberTile(
    BuildContext context, {
    required String userId,
    required String username,
    required String avatar,
    required bool isOnline,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // ✅ CORRIGIDO: Avatar com indicador online
        // leading: UserAvatar(
        //   imageUrl: avatar.startsWith('http') ? avatar : null,
        //   fallbackText: avatar.startsWith('http') ? null : avatar,
        //   radius: 24,
        //   isOnline: isOnline,
        // ),

        // Nome e informações
        title: Row(
          children: [
            Flexible(
              child: Text(
                username,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildRoleBadges(context),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '•',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Membro há ${_getMockMembershipDuration(userId)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Ações
        trailing: canManage ? _buildActionsMenu(context) : null,

        // Tap handler
        onTap: onTap,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========== RESTO DOS MÉTODOS INALTERADOS ==========

  Widget _buildRoleBadges(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCreator)
          _buildRoleBadge(context, 'Criador', Colors.amber, Icons.star),
        if (isAdmin && !isCreator) ...[
          if (isCreator) const SizedBox(width: 6),
          _buildRoleBadge(
            context,
            'Admin',
            Theme.of(context).colorScheme.primary,
            Icons.admin_panel_settings,
          ),
        ],
      ],
    );
  }

  Widget _buildRoleBadge(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        size: 20,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 8),
              Text('Ver Perfil'),
            ],
          ),
        ),
        if (!isAdmin && !isCreator)
          const PopupMenuItem(
            value: 'promote',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 16),
                SizedBox(width: 8),
                Text('Promover a Admin'),
              ],
            ),
          ),
        if (!isCreator)
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Remover do Grupo', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  // ========== AÇÕES E MÉTODOS MOCK ==========

  void _handleMenuAction(BuildContext context, String action) {
    AppLogger.debug('🎯 Ação do membro: $action para $userId');

    switch (action) {
      case 'profile':
        _showProfile(context);
        break;
      case 'promote':
        _showPromoteDialog(context);
        break;
      case 'remove':
        _showRemoveDialog(context);
        break;
    }
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil do Usuário'),
        content: const Text('Visualização de perfil em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPromoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover a Admin'),
        content: Text('Promover ${_getMockUsername(userId)} a administrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onPromote?.call();
            },
            child: const Text('Promover'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Membro'),
        content: Text(
          'Tem certeza que deseja remover ${_getMockUsername(userId)} do grupo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS MOCK ==========

  String _getMockUsername(String userId) {
    const names = [
      'Ana Silva',
      'Bruno Costa',
      'Carla Santos',
      'Diego Oliveira',
      'Elena Ferreira',
      'Felipe Lima',
      'Gabriela Alves',
      'Hugo Martins',
    ];
    return names[userId.hashCode % names.length];
  }

  String _getMockAvatar(String userId) {
    const avatars = [
      '👤',
      '🧑‍💻',
      '👩‍🎨',
      '🧑‍🔬',
      '👩‍💼',
      '🧑‍🎓',
      '👩‍⚕️',
      '🧑‍🏫',
    ];
    return avatars[userId.hashCode % avatars.length];
  }

  bool _getMockOnlineStatus(String userId) {
    return userId.hashCode % 3 == 0; // ~33% online
  }

  String _getMockMembershipDuration(String userId) {
    const durations = [
      '1 dia',
      '3 dias',
      '1 semana',
      '2 semanas',
      '1 mês',
      '2 meses',
    ];
    return durations[userId.hashCode % durations.length];
  }
}
