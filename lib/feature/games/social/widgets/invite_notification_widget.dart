// lib/widgets/invite_notification_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/games/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/games/social/providers/test_session_provider.dart';
import 'package:unlock/utils/helpers.dart';

// ============== INVITE NOTIFICATION OVERLAY ==============
class InviteNotificationOverlay extends ConsumerWidget {
  const InviteNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testInviteState = ref.watch(testInviteProvider);

    // Mostrar apenas se houver convites pendentes
    if (!testInviteState.hasPendingInvites) {
      return const SizedBox.shrink();
    }

    final pendingInvite = testInviteState.pendingReceivedInvites.first;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: InviteNotificationCard(invite: pendingInvite),
    );
  }
}

// ============== INVITE NOTIFICATION CARD ==============
class InviteNotificationCard extends ConsumerStatefulWidget {
  final TestInvite invite;

  const InviteNotificationCard({super.key, required this.invite});

  @override
  ConsumerState<InviteNotificationCard> createState() =>
      _InviteNotificationCardState();
}

class _InviteNotificationCardState extends ConsumerState<InviteNotificationCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isResponding = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = widget.invite.expiresAt?.difference(DateTime.now());
    final minutesLeft = timeRemaining?.inMinutes ?? 0;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.purple.shade400, Colors.indigo.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎯 Convite de Teste!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${widget.invite.senderUser.preferredDisplayName} quer testar a compatibilidade',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _dismissNotification,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Informações do usuário
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              AppHelpers.buildUserAvatar(
                                avatarId: widget.invite.senderUser.avatar,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget
                                          .invite
                                          .senderUser
                                          .preferredDisplayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Nível ${widget.invite.senderUser.level} • ${_getCommonInterestsText()}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: minutesLeft <= 1
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: minutesLeft <= 1
                                    ? Colors.red[200]
                                    : Colors.orange[200],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expira em ${minutesLeft}min',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: minutesLeft <= 1
                                      ? Colors.red[200]
                                      : Colors.orange[200],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botões de ação
                        if (_isResponding)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _respondToInvite(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white70,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Recusar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _respondToInvite(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.purple[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Aceitar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCommonInterestsText() {
    // TODO: Implementar lógica de interesses comuns
    return 'Interesses em comum';
  }

  void _dismissNotification() {
    _animationController.reverse().then((_) {
      // Marcar como lido (implementar se necessário)
    });
  }

  Future<void> _respondToInvite(bool accept) async {
    setState(() {
      _isResponding = true;
    });

    final success = await ref
        .read(testInviteProvider.notifier)
        .respondToInvite(widget.invite.id, accept);

    if (mounted) {
      setState(() {
        _isResponding = false;
      });

      if (success) {
        if (accept) {
          // Aceito - aguardar o outro usuário iniciar o teste
          AppHelpers.showCustomSnackBar(
            context,
            '✅ Convite aceito! Aguardando ${widget.invite.senderUser.preferredDisplayName} iniciar o teste.',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
          );
        } else {
          // Recusado
          AppHelpers.showCustomSnackBar(
            context,
            'Convite recusado.',
            backgroundColor: Colors.orange,
            icon: Icons.cancel,
          );
        }

        _animationController.reverse();
      } else {
        // Erro
        final error = ref.read(testInviteProvider).error ?? 'Erro ao responder';
        AppHelpers.showCustomSnackBar(
          context,
          error,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// ============== ACCEPTED INVITE NOTIFICATION ==============
class AcceptedInviteNotification extends ConsumerStatefulWidget {
  const AcceptedInviteNotification({super.key});

  @override
  ConsumerState<AcceptedInviteNotification> createState() =>
      _AcceptedInviteNotificationState();
}

class _AcceptedInviteNotificationState
    extends ConsumerState<AcceptedInviteNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final testInviteState = ref.watch(testInviteProvider);

    // Verificar se há convite aceito que pode iniciar teste
    final acceptedInvite = testInviteState.sentInvites
        .where((invite) => invite.canStartTest)
        .firstOrNull;

    if (acceptedInvite == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '🎉 Convite Aceito!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          _animationController.reverse();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${acceptedInvite.receiverUser.preferredDisplayName} aceitou seu convite!',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startTest(acceptedInvite),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Teste',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTest(TestInvite invite) async {
    // Marcar convite como teste iniciado
    await ref.read(testInviteProvider.notifier).startTest(invite.id);

    // Iniciar sessão de teste
    final sessionStarted = await ref
        .read(testSessionProvider.notifier)
        .startSession(invite.id, invite.receiverUser);

    if (sessionStarted && mounted) {
      _animationController.reverse();

      // Navegar para tela de teste
      context.go(
        '/connection-test',
        extra: {
          'userInterests': [], // TODO: Pegar interesses reais
          'chosenConnection': {
            'id': invite.receiverUser.uid,
            'nome': invite.receiverUser.preferredDisplayName,
            'avatarId': invite.receiverUser.avatar,
            // Adicionar outros campos necessários
          },
        },
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// ============== NOTIFICATION STACK ==============
class NotificationStack extends ConsumerWidget {
  final Widget child;

  const NotificationStack({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        const InviteNotificationOverlay(),
        const AcceptedInviteNotification(),
      ],
    );
  }
}

// Extension para facilitar uso
extension NotificationStackExtension on Widget {
  Widget withNotifications() {
    return NotificationStack(child: this);
  }
}
