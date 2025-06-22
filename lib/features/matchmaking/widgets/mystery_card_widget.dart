import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/router/app_router.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/matchmaking/providers/matchmaking_provider.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/onboarding/constants/onboarding_data.dart';
import 'package:unlock/providers/auth_provider.dart';

class MysteryCardWidget extends ConsumerStatefulWidget {
  final UserModel potentialMatch;

  const MysteryCardWidget({super.key, required this.potentialMatch});

  @override
  ConsumerState<MysteryCardWidget> createState() => _MysteryCardWidgetState();
}

class _MysteryCardWidgetState extends ConsumerState<MysteryCardWidget> {
  bool _isInviting = false;

  String _getCompatibilityHint(UserModel currentUser, UserModel otherUser) {
    final commonInterests = currentUser.interesses.toSet().intersection(
      otherUser.interesses.toSet(),
    );

    if (commonInterests.isNotEmpty) {
      return 'Vocês dois curtem ${commonInterests.first.split(' ').last}';
    }
    return 'Vocês têm gostos parecidos!';
  }

  Future<void> _handleInvite() async {
    if (_isInviting) return;

    setState(() => _isInviting = true);

    final inviterId = ref.read(authProvider).user?.uid;
    if (inviterId == null) {
      AppLogger.error(
        'Erro: Usuário atual não encontrado para enviar convite.',
      );
      if (mounted) setState(() => _isInviting = false);
      return;
    }

    final gameService = ref.read(gameServiceProvider);
    final gameRoomId = await gameService.sendGameInvite(
      inviterId: inviterId,
      inviteeId: widget.potentialMatch.uid,
    );

    if (mounted) {
      setState(() => _isInviting = false);
      if (gameRoomId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Convite enviado! Aguardando resposta...'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('${AppRoutes.gameRoom.split(':')[0]}$gameRoomId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('😕 Erro ao enviar convite. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return const SizedBox.shrink(); // Não deveria acontecer
    }

    final avatar = OnboardingConstants.freeAvatars.firstWhere(
      (a) => a.id == widget.potentialMatch.avatarId,
      orElse: () => OnboardingConstants.freeAvatars.first,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header com Avatar e Dica
            Column(
              children: [
                Text(avatar.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  widget.potentialMatch.codinome ?? 'Misterioso',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getCompatibilityHint(currentUser, widget.potentialMatch),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            // Bio
            Text(
              '"${widget.potentialMatch.bio ?? 'Uma alma em busca de conexão...'}"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Botão de Ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInviting ? null : _handleInvite,
                icon: _isInviting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gamepad_rounded),
                label: Text(_isInviting ? 'Enviando...' : 'Iniciar Jogo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
