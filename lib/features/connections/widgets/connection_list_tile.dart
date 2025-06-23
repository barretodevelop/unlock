import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/services/game_service.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

final gameServiceProvider = Provider((ref) => GameService());

class ConnectionListTile extends ConsumerStatefulWidget {
  final UserModel connection;

  const ConnectionListTile({super.key, required this.connection});

  @override
  ConsumerState<ConnectionListTile> createState() => _ConnectionListTileState();
}

class _ConnectionListTileState extends ConsumerState<ConnectionListTile> {
  bool _isNavigating = false;

  Future<void> _openChat() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      AppLogger.error('Usuário atual não encontrado para abrir chat.');
      if (mounted) setState(() => _isNavigating = false);
      return;
    }

    final gameService = ref.read(gameServiceProvider);
    final gameRoomId = await gameService.findGameRoomByPlayers(
      currentUser.uid,
      widget.connection.uid,
    );

    if (mounted) {
      if (gameRoomId != null) {
        // ✅ CORREÇÃO: Removido o split(':')[0] desnecessário
        // context.go('${AppRoutes.gameRoom.split(':')[0]}$gameRoomId');
        context.go('/game/$gameRoomId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível encontrar a sala de chat.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: UserAvatar(
        user: widget.connection,
        size: 50,
        // Uma vez que a conexão é formada, a foto real é sempre exibida.
        photoUrlOverride: widget.connection.actualPhotoUrl,
      ),
      title: Text(
        widget.connection.codinome ?? 'Conexão',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Toque para conversar', style: theme.textTheme.bodySmall),
      trailing: _isNavigating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _openChat,
    );
  }
}
