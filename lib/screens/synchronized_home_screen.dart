// synchronized_home_screen.dart
// TELA HOME SINCRONIZADA COM SISTEMA BIDIRECIONAL DE CONVITES

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/screens/enhanced_test_invite_provider.dart';
import 'package:unlock/feature/social/widgets/bidirectional_invite_widget.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/widgtes/custom_app_bar.dart';
import 'package:unlock/widgtes/custom_bottom_navigation.dart';

class SynchronizedHomeScreen extends ConsumerStatefulWidget {
  const SynchronizedHomeScreen({super.key});

  @override
  ConsumerState<SynchronizedHomeScreen> createState() =>
      _SynchronizedHomeScreenState();
}

class _SynchronizedHomeScreenState extends ConsumerState<SynchronizedHomeScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _statsController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _mainAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _pulseAnimation;

  // State
  int _currentNavIndex = 0;
  bool _showStats = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProviders();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    );

    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mainController.forward();
    _statsController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _initializeProviders() {
    // O provider já inicializa automaticamente os listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Força a primeira atualização
      ref.read(enhancedTestInviteProvider.notifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final inviteState = ref.watch(enhancedTestInviteProvider);

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      appBar: CustomAppBar(
        userName: user?.displayName ?? 'Usuário',
        userCode: user?.codinome ?? 'Anônimo',
        avatarId: user?.avatar ?? '👤',
        notificationCount: _getTotalNotificationCount(inviteState),
      ),
      body: Stack(
        children: [
          // Background gradient
          _buildBackgroundGradient(isDark),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _mainAnimation,
              child: Column(
                children: [
                  // Quick stats
                  if (_showStats) ...[
                    _buildQuickStats(inviteState, isDark)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: -0.1, end: 0),
                    const SizedBox(height: 20),
                  ],

                  // Main action area
                  Expanded(child: _buildMainContent(inviteState, isDark)),
                ],
              ),
            ),
          ),

          // Bidirectional notifications overlay
          const BidirectionalInviteOverlay(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        // hasNotifications: _getTotalNotificationCount(inviteState) > 0,
      ),
    );
  }

  Widget _buildBackgroundGradient(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ]
              : [Colors.blue.shade50, Colors.white, Colors.purple.shade50],
        ),
      ),
    );
  }

  Widget _buildQuickStats(EnhancedTestInviteState inviteState, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Convites Recebidos',
              inviteState.pendingReceivedInvites.length.toString(),
              Icons.mail_outline,
              Colors.blue,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Prontos p/ Teste',
              inviteState.readyToStartInvites.length.toString(),
              Icons.rocket_launch,
              Colors.green,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Testes Ativos',
              inviteState.hasActiveTest ? '1' : '0',
              Icons.science,
              Colors.orange,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(EnhancedTestInviteState inviteState, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Status atual
          _buildCurrentStatus(inviteState, isDark),

          const SizedBox(height: 30),

          // Ações principais
          _buildMainActions(inviteState, isDark),

          const Spacer(),

          // Quick access buttons
          _buildQuickAccess(isDark),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(EnhancedTestInviteState inviteState, bool isDark) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (inviteState.hasActiveTest) {
      statusText = 'Teste em andamento';
      statusIcon = Icons.science;
      statusColor = Colors.orange;
    } else if (inviteState.hasReadyToStartInvites) {
      statusText = 'Convite aceito - pode iniciar teste!';
      statusIcon = Icons.rocket_launch;
      statusColor = Colors.green;
    } else if (inviteState.hasPendingInvites) {
      statusText = 'Você tem convites pendentes';
      statusIcon = Icons.mail;
      statusColor = Colors.blue;
    } else {
      statusText = 'Pronto para novas conexões';
      statusIcon = Icons.favorite;
      statusColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Atual',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(EnhancedTestInviteState inviteState, bool isDark) {
    return Column(
      children: [
        // Descobrir novas conexões
        _buildActionCard(
          title: 'Descobrir Conexões',
          subtitle: 'Encontre pessoas compatíveis para testar',
          icon: Icons.search,
          color: Colors.blue,
          isDark: isDark,
          onTap: () => context.push('/match'),
        ),

        const SizedBox(height: 16),

        // Gerenciar perfil
        _buildActionCard(
          title: 'Meu Perfil',
          subtitle: 'Edite suas informações e interesses',
          icon: Icons.person,
          color: Colors.purple,
          isDark: isDark,
          onTap: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0, // Sem pulse por padrão
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccess(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessButton(
            'Admin Test',
            Icons.admin_panel_settings,
            Colors.red,
            isDark,
            () => context.push('/admin/test-users'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessButton(
            'Configurações',
            Icons.settings,
            Colors.grey,
            isDark,
            () => context.push('/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(
    String label,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? Colors.grey.shade900 : Colors.grey.shade50;
  }

  int _getTotalNotificationCount(EnhancedTestInviteState inviteState) {
    return inviteState.pendingReceivedInvites.length +
        inviteState.readyToStartInvites.length;
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        // Home - já estamos aqui
        break;
      case 1:
        context.push('/match');
        break;
      case 2:
        context.push('/chat');
        break;
      case 3:
        context.push('/profile');
        break;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
