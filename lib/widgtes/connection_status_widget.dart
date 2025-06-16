// lib/widgets/connection_status_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/games/social/providers/connection_lifecycle_provider.dart';
import 'package:unlock/feature/games/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/games/social/providers/test_session_provider.dart';

/// Widget que mostra o status geral das conexões do usuário
/// Aparece na HomeScreen como um dashboard resumido
class ConnectionStatusWidget extends ConsumerStatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  ConsumerState<ConnectionStatusWidget> createState() =>
      _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends ConsumerState<ConnectionStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _statsController;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.elasticOut,
    );

    _statsController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final testInviteState = ref.watch(testInviteProvider);
    final testSessionState = ref.watch(testSessionProvider);
    final connectionLifecycle = ref.watch(connectionLifecycleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                  : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 16),
                _buildStatsGrid(testInviteState, testSessionState, isDark),
                if (_hasActiveItems(testInviteState, testSessionState)) ...[
                  const SizedBox(height: 16),
                  _buildActiveSection(
                    testInviteState,
                    testSessionState,
                    isDark,
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hub, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suas Conexões',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Status das suas interações',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    TestInviteState testInviteState,
    TestSessionState testSessionState,
    bool isDark,
  ) {
    return ScaleTransition(
      scale: _statsAnimation,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.mail_outline,
              label: 'Enviados',
              value: testInviteState.sentInvites.length.toString(),
              color: Colors.blue,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.inbox,
              label: 'Recebidos',
              value: testInviteState.receivedInvites.length.toString(),
              color: Colors.green,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.schedule,
              label: 'Pendentes',
              value: testInviteState.pendingReceivedInvites.length.toString(),
              color: Colors.orange,
              isDark: isDark,
              highlight: testInviteState.pendingReceivedInvites.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight
                ? color.withOpacity(0.15)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: highlight
                ? Border.all(color: color.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: highlight
                    ? color
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? color
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
        .animate(delay: (100 * int.parse(value)).ms)
        .scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildActiveSection(
    TestInviteState testInviteState,
    TestSessionState testSessionState,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Disponíveis',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildActionItems(testInviteState, testSessionState, isDark),
      ],
    );
  }

  Widget _buildActionItems(
    TestInviteState testInviteState,
    TestSessionState testSessionState,
    bool isDark,
  ) {
    final actions = <Widget>[];

    // Convites aceitos que podem iniciar teste
    final readyToStart = testInviteState.sentInvites
        .where((invite) => invite.canStartTest)
        .toList();

    if (readyToStart.isNotEmpty) {
      actions.add(
        _buildActionItem(
          icon: Icons.play_circle_fill,
          title: 'Teste Pronto!',
          subtitle:
              '${readyToStart.first.receiverUser.preferredDisplayName} aceitou seu convite',
          color: Colors.green,
          onTap: () => _startTest(readyToStart.first),
          isDark: isDark,
        ),
      );
    }

    // Teste em andamento
    if (testSessionState.hasActiveSession) {
      actions.add(
        _buildActionItem(
          icon: Icons.psychology,
          title: 'Teste em Andamento',
          subtitle: 'Continue o teste de compatibilidade',
          color: Colors.purple,
          onTap: () => _continueTest(testSessionState),
          isDark: isDark,
        ),
      );
    }

    // Resultados prontos
    final completedTests = testInviteState.sentInvites
        .where((invite) => invite.status == TestInviteStatus.completed)
        .toList();

    if (completedTests.isNotEmpty) {
      actions.add(
        _buildActionItem(
          icon: Icons.analytics,
          title: 'Resultados Disponíveis',
          subtitle: 'Ver resultados dos testes',
          color: Colors.blue,
          onTap: () => _viewResults(),
          isDark: isDark,
        ),
      );
    }

    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sentiment_satisfied,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Tudo em dia! Que tal descobrir novas conexões?',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: actions);
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: color),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.elasticOut);
  }

  bool _hasActiveItems(
    TestInviteState testInviteState,
    TestSessionState testSessionState,
  ) {
    return testSessionState.hasActiveSession ||
        testInviteState.sentInvites.any((invite) => invite.canStartTest) ||
        testInviteState.sentInvites.any(
          (invite) => invite.status == TestInviteStatus.completed,
        );
  }

  // Action handlers
  Future<void> _startTest(TestInvite invite) async {
    // Iniciar sessão de teste
    final sessionStarted = await ref
        .read(testSessionProvider.notifier)
        .startSession(invite.id, invite.receiverUser);

    if (sessionStarted && mounted) {
      context.go(
        '/connection-test',
        extra: {
          'userInterests': invite.senderUser.interesses,
          'chosenConnection': {
            'id': invite.receiverUser.uid,
            'nome': invite.receiverUser.preferredDisplayName,
            'avatarId': invite.receiverUser.avatar,
            'interesses': invite.receiverUser.interesses,
          },
        },
      );
    }
  }

  void _continueTest(TestSessionState testSessionState) {
    if (testSessionState.sessionId != null) {
      context.go('/connection-test');
    }
  }

  void _viewResults() {
    context.go('/test-results');
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }
}
