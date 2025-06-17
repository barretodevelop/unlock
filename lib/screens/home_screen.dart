// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/feature/social/screens/list_profiles.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/screens/mission_screen.dart';
import 'package:unlock/widgtes/custom_app_bar.dart';
import 'package:unlock/widgtes/custom_bottom_navigation.dart';

// Tela Principal Otimizada
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      appBar: CustomAppBar(
        userName: user!.displayName,
        userCode: user.codinome ?? 'Anonimo',
        avatarId: user.avatar,
        hasNotifications: _hasNotifications,
        onNotificationTap: _onNotificationTap,
        onAvatarTap: _onAvatarTap,
      ),
      body: AnimatedBuilder(
        animation: _mainAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _mainAnimation,
            child: _buildCurrentPage(isDark, user),
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
        return ProfilesPage(); //_buildProfilePage(isDark);
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
              // const SizedBox(height: 24),
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

  Widget _buildProfilePage(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            'Página Perfil',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPulse(bool isDark, UserModel user) {
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

  Widget _buildQuickStats(bool isDark) {
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
        'icon': Icons.visibility,
        'label': 'Visitantes',
        'value': '89',
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
        Text(
          'Como você está se sentindo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: moods.map((mood) {
              final isSelected = _currentMood == mood['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _currentMood = mood['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple.withOpacity(0.2)
                        : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.deepPurple, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mood['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? Colors.deepPurple
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mood['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.deepPurple
                              : (isDark ? Colors.white70 : Colors.black54),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        const SizedBox(height: 16),
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
        Text(
          'Sugestões de Conexão',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
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
              color: isDark ? Colors.white : Colors.black87,
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

  // Event Handlers
  void _onNotificationTap() {
    setState(() {
      _hasNotifications = false;
    });
    // Implementar lógica de notificações
  }

  void _onAvatarTap() {
    setState(() {
      _currentNavIndex = 3; // Ir para perfil
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _onCenterButtonTap() {
    // Ação do botão central flutuante
    context.go('/game');
  }

  void _onFindConnection(List<String> interesses) {
    HapticFeedback.mediumImpact();
    context.go('/match', extra: interesses);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();

    super.dispose();
  }
}
