import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/invites/providers/pending_invites_provider.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

class InviteListTile extends ConsumerWidget {
  final GameInvite invite;

  const InviteListTile({super.key, required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inviter = invite.inviter;
    final gameRoomId = invite.gameRoom.id;

    // ✅ CORREÇÃO: O ListTile inteiro agora é um botão que navega para a sala de jogo.
    // A lógica de aceitar/recusar foi movida para a GameRoomScreen, que é o lugar correto.
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      onTap: () {
        AppLogger.info(
          'InviteListTile: Tapped on invite for gameRoomId: $gameRoomId',
        ); // ✅ LOGGING APRIMORADO
        // Apenas navega para a sala. A GameRoomScreen cuidará de mostrar as opções.
        context.go('/game/$gameRoomId');
      },
      leading: UserAvatar(user: inviter, size: 50),
      title: Text(
        inviter.codinome ?? 'Misterioso',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'convidou você para jogar!',
        style: theme.textTheme.bodySmall,
      ),
      // ✅ CORREÇÃO: Botões removidos, o trailing agora é um indicador de ação.
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
