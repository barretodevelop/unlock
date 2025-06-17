// lib/screens/home_screen.dart
// lib/screens/enhanced_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/discovery_provider.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/social/widgets/connection_status_widget.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_app_bar.dart';
import 'package:unlock/widgtes/custom_bottom_navigation.dart';
import 'package:unlock/widgtes/pending_invites_card.dart';

/// Home Screen com UX Extraordinária
/// - Feedback visual imediato para convites
/// - Dashboard de conexões ativo
/// - Navegação fluída e intuitiva
/// - Animações que comunicam status
class OldEnhancedHomeScreen extends ConsumerStatefulWidget {
  const OldEnhancedHomeScreen({super.key});

  @override
  ConsumerState<OldEnhancedHomeScreen> createState() =>
      _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<OldEnhancedHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatingButtonController;
  late Animation<double> _mainAnimation;
  late Animation<double> _floatingButtonAnimation;

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    );

    _floatingButtonAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _floatingButtonController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
    _floatingButtonController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final testInviteState = ref.watch(testInviteProvider);

    // Contar notificações dinâmicas
    final notificationCount = testInviteState.pendingReceivedInvites.length;

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      appBar: CustomAppBar(
        userName: user?.displayName ?? 'Usuário',
        userCode: user?.codinome ?? 'USER001',
        avatarId: user?.avatar ?? 'avatar_1',
        notificationCount: notificationCount,
        onNotificationTap: () => context.go('/notifications'),
        onAvatarTap: () => context.go('/profile'),
      ),
      body: FadeTransition(
        opacity: _mainAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ✨ CONVITES PENDENTES - Feedback Imediato
                const PendingInvitesCard(),

                // ✨ STATUS DE CONEXÕES - Dashboard Ativo
                const ConnectionStatusWidget(),

                // Seção Principal
                _buildMainSection(isDark, user),

                // Ações Rápidas
                _buildQuickActions(isDark),

                // Descobrir Conexões
                _buildDiscoverySection(isDark),

                const SizedBox(height: 100), // Espaço para FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildMainSection(bool isDark, UserModel? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Olá, ${user?.displayName?.split(' ').first ?? 'Usuário'}! 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.3, duration: 800.ms),

          const SizedBox(height: 8),

          Text(
                'Pronto para descobrir novas conexões?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              )
              .animate(delay: 200.ms)
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.3, duration: 800.ms),

          const SizedBox(height: 20),

          _buildMoodSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(bool isDark) {
    final moods = [
      {'icon': Icons.people, 'label': 'Social', 'value': 'social'},
      {'icon': Icons.favorite, 'label': 'Romance', 'value': 'romance'},
      {'icon': Icons.work, 'label': 'Trabalho', 'value': 'work'},
      {'icon': Icons.sports_esports, 'label': 'Games', 'value': 'games'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como você está se sentindo hoje?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: moods.map((mood) {
            final isSelected = mood['value'] == 'social'; // Default
            return _buildMoodChip(mood, isSelected, isDark);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodChip(
    Map<String, dynamic> mood,
    bool isSelected,
    bool isDark,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => HapticFeedback.selectionClick(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mood['icon'] as IconData,
                  size: 16,
                  color: isSelected
                      ? Colors.blue
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                Text(
                  mood['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.blue
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.search,
                  title: 'Descobrir',
                  subtitle: 'Novas pessoas',
                  color: Colors.purple,
                  onTap: () => _discoverConnections(),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.message,
                  title: 'Conversas',
                  subtitle: 'Seus chats',
                  color: Colors.green,
                  onTap: () => context.go('/chats'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
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
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildDiscoverySection(bool isDark) {
    final discoveryState = ref.watch(discoveryProvider);

    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.red.shade400],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explorar Conexões',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          discoveryState.hasResults
                              ? '${discoveryState.compatibleUsers.length} pessoas compatíveis'
                              : 'Descubra pessoas com interesses similares',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: discoveryState.canSearch
                      ? _discoverConnections
                      : null,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (discoveryState.isSearching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.orange,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        discoveryState.isSearching
                            ? 'Buscando...'
                            : 'Começar Descoberta',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.3, duration: 1000.ms, curve: Curves.elasticOut);
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return ScaleTransition(
      scale: _floatingButtonAnimation,
      child: FloatingActionButton.extended(
        onPressed: _onCenterButtonTap,
        backgroundColor: Colors.blue,
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Conexão',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  }

  // Event Handlers
  Future<void> _refreshData() async {
    // Refresh discovery data
    ref.read(discoveryProvider.notifier).findCompatibleUsers();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Simulate delay
    await Future.delayed(const Duration(seconds: 1));
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    HapticFeedback.selectionClick();

    switch (index) {
      case 0:
        // Já estamos na home
        break;
      case 1:
        context.go('/discover');
        break;
      case 2:
        context.go('/chats');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  void _onCenterButtonTap() {
    HapticFeedback.mediumImpact();
    _discoverConnections();
  }

  void _discoverConnections() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      // Primeiro atualizar atividade do usuário
      ref.read(discoveryProvider.notifier).updateUserActivity();

      // Depois buscar usuários compatíveis
      ref.read(discoveryProvider.notifier).findCompatibleUsers();

      // Navegar para tela de matching
      context.go('/match', extra: user.interesses);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingButtonController.dispose();
    super.dispose();
  }
}
