// lib/widgets/pending_invites_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';

/// Widget que aparece na HomeScreen quando há convites pendentes
/// Fornece feedback visual imediato e ações rápidas
class PendingInvitesCard extends ConsumerStatefulWidget {
  const PendingInvitesCard({super.key});

  @override
  ConsumerState<PendingInvitesCard> createState() => _PendingInvitesCardState();
}

class _PendingInvitesCardState extends ConsumerState<PendingInvitesCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final testInviteState = ref.watch(testInviteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Não mostrar se não há convites pendentes
    if (!testInviteState.hasPendingInvites) {
      return const SizedBox.shrink();
    }

    final pendingInvites = testInviteState.pendingReceivedInvites;
    final inviteCount = pendingInvites.length;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildCardContent(pendingInvites, inviteCount, isDark),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    List<TestInvite> pendingInvites,
    int inviteCount,
    bool isDark,
  ) {
    if (inviteCount == 1) {
      return _buildSingleInviteCard(pendingInvites.first);
    } else {
      return _buildMultipleInvitesCard(inviteCount);
    }
  }

  /// Card para um convite único - mais detalhado
  Widget _buildSingleInviteCard(TestInvite invite) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: AppHelpers.buildUserAvatar(
                    avatarId: invite.senderUser.avatar,
                    radius: 25,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Novo Convite de Teste!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invite.senderUser.preferredDisplayName} quer testar a compatibilidade',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTimeRemaining(invite),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(invite),
        ],
      ),
    );
  }

  /// Card para múltiplos convites - mais compacto
  Widget _buildMultipleInvitesCard(int count) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 $count Convites Pendentes!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você tem convites de teste aguardando resposta',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          AnimatedButton(
            onPressed: () => _showAllInvites(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.purple,
            child: const Text(
              'Ver Todos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining(TestInvite invite) {
    final timeRemaining = invite.expiresAt?.difference(DateTime.now());
    final minutesLeft = timeRemaining?.inMinutes ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: minutesLeft <= 1
            ? Colors.red.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${minutesLeft}min',
        style: TextStyle(
          color: minutesLeft <= 1 ? Colors.red.shade100 : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(TestInvite invite) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _respondToInvite(invite.id, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Recusar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AnimatedButton(
            onPressed: () => _respondToInvite(invite.id, true),
            backgroundColor: Colors.white,
            foregroundColor: Colors.purple,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 8),
                Text(
                  'Aceitar Teste',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Responder ao convite com navegação automática
  Future<void> _respondToInvite(String inviteId, bool accept) async {
    final success = await ref
        .read(testInviteProvider.notifier)
        .respondToInvite(inviteId, accept);

    if (!mounted) return;

    if (success && accept) {
      // FLUXO MELHORADO: Navegação automática após aceitar
      final invite = ref
          .read(testInviteProvider)
          .pendingReceivedInvites
          .firstWhere((i) => i.id == inviteId);

      AppHelpers.showCustomSnackBar(
        context,
        '✅ Convite aceito! Iniciando teste...',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );

      // Aguardar um momento para feedback visual
      await Future.delayed(const Duration(milliseconds: 500));

      // Iniciar sessão de teste automaticamente
      final sessionStarted = await ref
          .read(testSessionProvider.notifier)
          .startSession(inviteId, invite.senderUser);

      if (sessionStarted && mounted) {
        // Navegar automaticamente para tela de teste
        context.go(
          '/connection-test',
          extra: {
            'userInterests': invite.receiverUser.interesses,
            'chosenConnection': {
              'id': invite.senderUser.uid,
              'nome': invite.senderUser.preferredDisplayName,
              'avatarId': invite.senderUser.avatar,
              'interesses': invite.senderUser.interesses,
            },
          },
        );
      }
    } else if (success && !accept) {
      AppHelpers.showCustomSnackBar(
        context,
        'Convite recusado.',
        backgroundColor: Colors.orange,
        icon: Icons.cancel,
      );
    } else {
      AppHelpers.showCustomSnackBar(
        context,
        'Erro ao responder convite. Tente novamente.',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }

  /// Mostrar tela com todos os convites (implementar depois)
  void _showAllInvites() {
    context.go('/notifications');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
