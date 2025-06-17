// lib/screens/home_screen.dart
// lib/screens/enhanced_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/providers/discovery_provider.dart';
import 'package:unlock/feature/social/providers/test_invite_provider.dart';
import 'package:unlock/feature/social/screens/list_profiles.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/mission_screen.dart';
import 'package:unlock/widgtes/custom_app_bar.dart';
import 'package:unlock/widgtes/custom_bottom_navigation.dart';

// Tela Principal Otimizada - LAYOUT LIMPO E FUNCIONAL
class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _mainAnimation;
  late Animation<double> _pulseAnimation;

  // State Management
  bool _isLoading = false;
  int _activeConnections = 0;
  String _currentMood = 'social';
  int _currentNavIndex = 0;
  bool _hasNotifications = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _initializeData() {
    setState(() {
      _activeConnections = 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    // ✅ Notificações dinâmicas baseadas em convites reais
    final testInviteState = ref.watch(testInviteProvider);
    final notificationCount = testInviteState.pendingReceivedInvites.length;

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      appBar: CustomAppBar(
        userName: user?.displayName ?? 'Usuário',
        userCode: user?.codinome ?? 'Anônimo',
        avatarId: user?.avatar ?? 'avatar_1',
        hasNotifications: notificationCount > 0,
        onNotificationTap: _onNotificationTap,
        onAvatarTap: _onAvatarTap,
      ),
      body: AnimatedBuilder(
        animation: _mainAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _mainAnimation,
            child: _buildCurrentPage(isDark, user!),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        onCenterButtonTap: _onCenterButtonTap,
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
  }

  Widget _buildCurrentPage(bool isDark, UserModel user) {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomePage(isDark, user);
      case 1:
        return MissionScreen();
      case 2:
        return _buildChatsPage(isDark);
      case 3:
        return ProfilesPage();
      default:
        return _buildHomePage(isDark, user);
    }
  }

  Widget _buildHomePage(bool isDark, UserModel user) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildConnectionPulse(isDark, user),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ✅ NOVO: Convites pendentes integrados de forma sutil
              _buildPendingInvitesSection(isDark),

              // ✅ MANTÉM: Estrutura original melhorada
              _buildQuickStats(isDark),
              const SizedBox(height: 24),
              _buildMoodSelector(isDark),
              const SizedBox(height: 24),
              _buildRecentActivity(isDark),
              const SizedBox(height: 24),
              _buildConnectionsSuggestions(isDark, user),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  // ✅ NOVO: Seção de convites integrada e sutil
  Widget _buildPendingInvitesSection(bool isDark) {
    final testInviteState = ref.watch(testInviteProvider);

    if (!testInviteState.hasPendingInvites) {
      return const SizedBox.shrink();
    }

    final pendingInvites = testInviteState.pendingReceivedInvites;
    final invite = pendingInvites.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.group_add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingInvites.length > 1
                            ? '${pendingInvites.length} Convites Pendentes'
                            : 'Novo Convite de Teste',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pendingInvites.length > 1
                            ? 'Você tem convites aguardando'
                            : '${invite.senderUser.preferredDisplayName} quer testar compatibilidade',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingInvites.length == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToInvite(invite.id, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Recusar',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _respondToInvite(invite.id, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Aceitar Teste',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showAllInvites,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'Ver Todos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ MANTÉM: Card de conexão original (era melhor)
  Widget _buildConnectionPulse(bool isDark, UserModel user) {
    final testInviteState = ref.watch(testInviteProvider);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: () => _onFindConnection(user.interesses),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.indigo.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Efeito de partículas
                  ...List.generate(8, (index) {
                    return Positioned(
                      left: (index * 45.0) % 300,
                      top: (index * 23.0) % 80 + 20,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (0.3 + (_pulseAnimation.value - 0.95) * 4)
                                .clamp(0.0, 0.7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  // Badge de notificação se houver convites
                  if (testInviteState.hasPendingInvites)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${testInviteState.pendingReceivedInvites.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Conteúdo principal
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          size: 32,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Descobrir Conexões',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$_activeConnections pessoas online agora',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ MELHORADO: Stats com conexões integradas
  Widget _buildQuickStats(bool isDark) {
    final testInviteState = ref.watch(testInviteProvider);

    final stats = [
      {
        'icon': Icons.favorite,
        'label': 'Matches',
        'value': '24',
        'color': Colors.red,
      },
      {
        'icon': Icons.chat_bubble,
        'label': 'Chats',
        'value': '12',
        'color': Colors.blue,
      },
      {
        'icon': Icons.mail_outline,
        'label': 'Convites',
        'value': testInviteState.sentInvites.length.toString(),
        'color': Colors.green,
      },
      {
        'icon': Icons.star,
        'label': 'XP',
        'value': '1.2k',
        'color': Colors.amber,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) {
          return Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                stat['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ✅ MANTÉM: Métodos originais
  Widget _buildChatsPage(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            'Página Chats',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(bool isDark) {
    final moods = [
      {'id': 'social', 'icon': Icons.people, 'label': 'Social'},
      {'id': 'creative', 'icon': Icons.palette, 'label': 'Criativo'},
      {'id': 'chill', 'icon': Icons.self_improvement, 'label': 'Relaxar'},
      {'id': 'adventure', 'icon': Icons.explore, 'label': 'Aventura'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Como você está se sentindo?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = mood['id'] == _currentMood;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMood = mood['id'] as String;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.shade400
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? Border.all(color: Colors.deepPurple.shade300)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mood['icon'] as IconData,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
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
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Atividade Recente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver tudo',
                  style: TextStyle(color: Colors.deepPurple.shade400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              _buildActivityItem(
                'Nova conexão encontrada',
                'Há 5 minutos',
                Icons.person_add,
                Colors.green,
                isDark,
              ),
              _buildActivityItem(
                'Mensagem recebida',
                'Há 12 minutos',
                Icons.message,
                Colors.blue,
                isDark,
              ),
              _buildActivityItem(
                'Perfil visitado',
                'Há 1 hora',
                Icons.visibility,
                Colors.orange,
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsSuggestions(bool isDark, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Sugestões de Conexão',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildSuggestionCard(index, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(int index, bool isDark) {
    final colors = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
    ];

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Anônimo ${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            '95% match',
            style: TextStyle(fontSize: 10, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  // ✅ NOVOS: Event Handlers funcionais
  Future<void> _respondToInvite(String inviteId, bool accept) async {
    final success = await ref
        .read(testInviteProvider.notifier)
        .respondToInvite(inviteId, accept);

    if (!mounted) return;

    if (success && accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Convite aceito! Preparando teste...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      final invite = ref
          .read(testInviteProvider)
          .receivedInvites
          .firstWhere((i) => i.id == inviteId);

      if (mounted) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convite recusado'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao responder convite. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAllInvites() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInvitesModal(),
    );
  }

  Widget _buildInvitesModal() {
    final testInviteState = ref.watch(testInviteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B).withOpacity(0.98),
                ]
              : [Colors.white, const Color(0xFFFAFBFF)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    size: 20,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seus Convites',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${testInviteState.pendingReceivedInvites.length} convite${testInviteState.pendingReceivedInvites.length != 1 ? 's' : ''} pendente${testInviteState.pendingReceivedInvites.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: testInviteState.pendingReceivedInvites.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: testInviteState.pendingReceivedInvites.length,
                    itemBuilder: (context, index) {
                      final invite =
                          testInviteState.pendingReceivedInvites[index];
                      return _buildInviteCard(invite, isDark, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey.shade800.withOpacity(0.2),
                        Colors.grey.shade800.withOpacity(0.1),
                        Colors.blue.shade900.withOpacity(0.05),
                      ]
                    : [
                        Colors.grey.shade50,
                        const Color(0xFFF8FAFF),
                        const Color(0xFFE0F2FE).withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum convite pendente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você está em dia com seus convites!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(dynamic invite, bool isDark, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF1E293B).withOpacity(0.95),
                    const Color(0xFF2563EB).withOpacity(0.15),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF1F5F9),
                    const Color(0xFFDEEAFE).withOpacity(0.6),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF475569).withOpacity(0.8)
                : const Color(0xFF2563EB).withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF2563EB).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: isDark
                  ? const Color(0xFF2563EB).withOpacity(0.1)
                  : const Color(0xFF2563EB).withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? Colors.blue.shade800
                      : Colors.blue.shade100,
                  child: Text(
                    invite.senderUser.preferredDisplayName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convite de ${invite.senderUser.preferredDisplayName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quer se conectar com você',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
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
                    color: isDark
                        ? Colors.orange.shade900.withOpacity(0.3)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pendente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _respondToInvite(invite.id, false);
                    },
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                    ),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.red.shade300
                          : Colors.red.shade600,
                      side: BorderSide(
                        color: isDark
                            ? Colors.red.shade300
                            : Colors.red.shade600,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _respondToInvite(invite.id, true);
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Aceitar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.blue.shade600
                          : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MANTÉM: Event Handlers originais
  void _onNotificationTap() {
    final testInviteState = ref.read(testInviteProvider);

    if (testInviteState.hasPendingInvites) {
      _showAllInvites();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não há notificações no momento'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onAvatarTap() {
    context.go('/profile');
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _onCenterButtonTap() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      HapticFeedback.mediumImpact();
      _onFindConnection(user.interesses);
    }
  }

  void _onFindConnection(List<String> interesses) {
    HapticFeedback.mediumImpact();

    // Atualizar atividade e buscar usuários
    ref.read(discoveryProvider.notifier).updateUserActivity();
    ref.read(discoveryProvider.notifier).findCompatibleUsers();

    context.go('/match', extra: interesses);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
