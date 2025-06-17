// bidirectional_invite_widget.dart
// WIDGET BIDIRECIONAL PARA CONVITES - INTERFACE PARA AMBOS OS USUÁRIOS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/test_session_provider.dart';
import 'package:unlock/feature/social/screens/enhanced_test_invite_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/utils/helpers.dart';

// ============== MAIN NOTIFICATION OVERLAY ==============

class BidirectionalInviteOverlay extends ConsumerWidget {
  const BidirectionalInviteOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(enhancedTestInviteProvider);

    return Stack(
      children: [
        // Convites recebidos pendentes
        if (inviteState.hasPendingInvites) const InviteReceivedWidget(),

        // Convites aceitos - prontos para teste
        if (inviteState.hasReadyToStartInvites) const ReadyToStartWidget(),
      ],
    );
  }
}

// ============== CONVITE RECEBIDO ==============

class InviteReceivedWidget extends ConsumerStatefulWidget {
  const InviteReceivedWidget({super.key});

  @override
  ConsumerState<InviteReceivedWidget> createState() =>
      _InviteReceivedWidgetState();
}

class _InviteReceivedWidgetState extends ConsumerState<InviteReceivedWidget>
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
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    final inviteState = ref.watch(enhancedTestInviteProvider);
    final pendingInvite = inviteState.pendingReceivedInvites.first;

    final timeRemaining = pendingInvite.expiresAt?.difference(DateTime.now());
    final minutesLeft = timeRemaining?.inMinutes ?? 0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade400, Colors.purple.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mail,
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
                                '🎯 Novo Convite de Teste!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'De: ${pendingInvite.senderUser.preferredDisplayName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${minutesLeft}min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Descrição
                    Text(
                      'Quer testar a compatibilidade com você! '
                      'Aceite para descobrir a afinidade entre vocês.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Recusar',
                            icon: Icons.close,
                            backgroundColor: Colors.red.shade400,
                            onPressed: _isResponding
                                ? null
                                : () => _respondToInvite(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildActionButton(
                            label: 'Aceitar Teste',
                            icon: Icons.check,
                            backgroundColor: Colors.green.shade400,
                            onPressed: _isResponding
                                ? null
                                : () => _respondToInvite(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _isResponding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Future<void> _respondToInvite(bool accept) async {
    if (_isResponding) return;

    setState(() => _isResponding = true);

    final inviteState = ref.read(enhancedTestInviteProvider);
    final pendingInvite = inviteState.pendingReceivedInvites.first;

    final success = await ref
        .read(enhancedTestInviteProvider.notifier)
        .respondToInvite(pendingInvite.id, accept);

    if (mounted) {
      setState(() => _isResponding = false);

      if (success) {
        _animationController.reverse();

        if (accept) {
          AppHelpers.showCustomSnackBar(
            context,
            '✅ Convite aceito! Aguardando o outro usuário iniciar o teste.',
            backgroundColor: Colors.green,
            icon: Icons.check_circle,
          );
        } else {
          AppHelpers.showCustomSnackBar(
            context,
            'Convite recusado.',
            backgroundColor: Colors.orange,
            icon: Icons.cancel,
          );
        }
      } else {
        AppHelpers.showCustomSnackBar(
          context,
          'Erro ao responder convite. Tente novamente.',
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

// ============== CONVITE ACEITO - PRONTO PARA TESTE ==============

class ReadyToStartWidget extends ConsumerStatefulWidget {
  const ReadyToStartWidget({super.key});

  @override
  ConsumerState<ReadyToStartWidget> createState() => _ReadyToStartWidgetState();
}

class _ReadyToStartWidgetState extends ConsumerState<ReadyToStartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  bool _isStartingTest = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(enhancedTestInviteProvider);
    final readyInvite = inviteState.readyToStartInvites.first;
    final currentUser = ref.watch(authProvider).user;

    final role = readyInvite.getRoleForUser(currentUser?.uid ?? '');
    final partner = readyInvite.getPartnerForUser(currentUser?.uid ?? '');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      left: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(
                        _glowAnimation.value * 0.4,
                      ),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade400, Colors.teal.shade400],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.rocket_launch,
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
                                    '🎉 Teste Liberado!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    role == InviteRole.sender
                                        ? '${partner.preferredDisplayName} aceitou seu convite!'
                                        : 'Você aceitou o convite de ${partner.preferredDisplayName}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Descrição
                        const Text(
                          'Vocês estão prontos para testar a compatibilidade! '
                          'Qualquer um de vocês pode iniciar o teste agora.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Botão de iniciar teste
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isStartingTest ? null : _startTest,
                            icon: _isStartingTest
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.play_arrow, size: 24),
                            label: Text(
                              _isStartingTest
                                  ? 'Iniciando...'
                                  : 'Iniciar Teste',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startTest() async {
    if (_isStartingTest) return;

    setState(() => _isStartingTest = true);

    final inviteState = ref.read(enhancedTestInviteProvider);
    final readyInvite = inviteState.readyToStartInvites.first;

    // Marcar convite como teste iniciado
    final success = await ref
        .read(enhancedTestInviteProvider.notifier)
        .startTestSession(readyInvite.id);

    if (mounted && success) {
      // Iniciar sessão de teste
      final sessionStarted = await ref
          .read(testSessionProvider.notifier)
          .startSession(
            readyInvite.id,
            readyInvite.getPartnerForUser(
              ref.read(authProvider).user?.uid ?? '',
            ),
          );

      if (sessionStarted) {
        _animationController.reverse();

        // Navegar para tela de teste
        context.go(
          '/connection-test',
          extra: {
            'chosenConnection': {
              'id': readyInvite
                  .getPartnerForUser(ref.read(authProvider).user?.uid ?? '')
                  .uid,
              'nome': readyInvite
                  .getPartnerForUser(ref.read(authProvider).user?.uid ?? '')
                  .preferredDisplayName,
              'avatarId': readyInvite
                  .getPartnerForUser(ref.read(authProvider).user?.uid ?? '')
                  .avatar,
            },
            'userInterests': ref.read(authProvider).user?.interesses ?? [],
            'inviteId': readyInvite.id,
          },
        );
      } else {
        setState(() => _isStartingTest = false);
        AppHelpers.showCustomSnackBar(
          context,
          'Erro ao iniciar teste. Tente novamente.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } else {
      setState(() => _isStartingTest = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}

// ============== NOTIFICATION STACK WRAPPER ==============

class BidirectionalNotificationStack extends ConsumerWidget {
  final Widget child;

  const BidirectionalNotificationStack({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(children: [child, const BidirectionalInviteOverlay()]);
  }
}

// Extension para facilitar uso
extension BidirectionalNotificationExtension on Widget {
  Widget withBidirectionalNotifications() {
    return BidirectionalNotificationStack(child: this);
  }
}
