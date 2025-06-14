// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Animações
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late List<Animation<Offset>> _cardAnimations;
  late Animation<double> _fadeAnimation;

  // Estado local
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Animações escalonadas para os cards
    _cardAnimations = List.generate(4, (index) {
      final start = index * 0.1;
      final end = start + 0.4;

      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start,
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    if (_isLocalLoading) return;

    // Mostrar confirmação
    final shouldLogout = await _showLogoutConfirmation();
    if (!shouldLogout) return;

    setState(() {
      _isLocalLoading = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).signOut();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no logout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Confirmar Logout',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tem certeza de que deseja sair?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: CustomScrollView(
              slivers: [_buildAppBar(user), _buildContent(authState)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(user) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9333EA), Color(0xFF2563EB), Color(0xFF0D9488)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          user.avatar,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${user.displayName}!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Bem-vindo de volta',
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
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _isLocalLoading ? null : _handleLogout,
          icon: _isLocalLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Sair',
        ),
      ],
    );
  }

  Widget _buildContent(AuthState authState) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Stats cards
          _buildStatsSection(authState.user!),

          const SizedBox(height: 30),

          // Quick actions
          _buildQuickActions(),

          const SizedBox(height: 30),

          // Recent activity
          _buildRecentActivity(),

          const SizedBox(height: 30),

          // Debug section (only in debug mode)
          if (authState.status == AuthStatus.authenticated)
            _buildDebugSection(authState),
        ]),
      ),
    );
  }

  Widget _buildStatsSection(user) {
    final stats = [
      {'icon': Icons.stars, 'label': 'Nível', 'value': '${user.level}'},
      {'icon': Icons.flash_on, 'label': 'XP', 'value': '${user.xp}'},
      {
        'icon': Icons.monetization_on,
        'label': 'Moedas',
        'value': '${user.coins}',
      },
      {'icon': Icons.diamond, 'label': 'Gemas', 'value': '${user.gems}'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suas Estatísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;

            return Expanded(
              child: SlideTransition(
                position: _cardAnimations[index],
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < stats.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: const Color(0xFF9333EA),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['value'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.person,
        'label': 'Perfil',
        'color': const Color(0xFF9333EA),
        'onTap': () => context.push('/profile'),
      },
      {
        'icon': Icons.pets,
        'label': 'Pets',
        'color': const Color(0xFF2563EB),
        'onTap': () {},
      },
      {
        'icon': Icons.settings,
        'label': 'Configurações',
        'color': const Color(0xFF0D9488),
        'onTap': () {},
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;

            return Expanded(
              child: SlideTransition(
                position: _cardAnimations[index],
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < actions.length - 1 ? 12 : 0,
                  ),
                  child: Material(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: action['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (action['color'] as Color).withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                action['icon'] as IconData,
                                color: action['color'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              action['label'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      'Fez login às ${DateTime.now().hour}:${DateTime.now().minute}',
      // 'Nível atualizado para ${authState.user?.level ?? 1}',
      'Conquistou 50 XP hoje',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9333EA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugSection(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                'Debug Info',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${authState.status}\n'
            'Initialized: ${authState.isInitialized}\n'
            'Loading: ${authState.isLoading}\n'
            'User ID: ${authState.user?.uid ?? 'null'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
