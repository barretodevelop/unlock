import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/providers/theme_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgets/animated/animated_button.dart';
import 'package:unlock/widgets/common/custom_card.dart';

final MockDataProvider dataProvider = MockDataProvider();

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _missionsController;
  late AnimationController _specialMissionController;
  late AnimationController _petController;

  late Animation<double> _missionsAnimation;
  late Animation<double> _specialMissionAnimation;
  late Animation<double> _petBounceAnimation;
  late Animation<double> _petGlowAnimation;

  List<Map<String, dynamic>> _currentDailyMissions = [];
  Map<String, dynamic>? _specialMission;
  bool _isLoadingMissions = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMissionPage();
  }

  void _initializeAnimations() {
    _missionsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _specialMissionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _petController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _missionsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _missionsController, curve: Curves.easeOutBack),
    );

    _specialMissionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _specialMissionController,
        curve: Curves.elasticOut,
      ),
    );

    _petBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _petController, curve: Curves.bounceOut));

    _petGlowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _petController, curve: Curves.easeInOut));

    // Animação contínua para o pet
    _petController.repeat(reverse: true);
  }

  void _initializeMissionPage() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentDailyMissions = dataProvider.getDailyMissions();
      _specialMission = _createSpecialMission();
      _isLoadingMissions = false;
    });

    _missionsController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _specialMissionController.forward();
  }

  Map<String, dynamic> _createSpecialMission() {
    return {
      'id': 'special_pet_mission',
      'title': '🐾 Missão Especial: Adote um Pet',
      'description':
          'Complete 5 missões diárias consecutivas para desbloquear seu novo companheiro!',
      'icon': Icons.pets,
      'xp': 500,
      'moedas': 1000,
      'target': 5,
      'currentProgress': 3,
      'petType': 'Dragon Bebê',
      'petEmoji': 'assets/pets/dog2.png',
      'isSpecial': true,
    };
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Reset animations
    _missionsController.reset();
    _specialMissionController.reset();

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _currentDailyMissions = dataProvider.getDailyMissions();
      _specialMission = _createSpecialMission();
      _isRefreshing = false;
    });

    // Restart animations
    _missionsController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _specialMissionController.forward();

    if (mounted) {
      AppHelpers.showCustomSnackBar(
        context,
        'Missões atualizadas com sucesso!',
        icon: Icons.refresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      backgroundColor: Theme.of(context).cardColor,
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingMissions || _isRefreshing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                _buildSpecialMissionSection(),
                const SizedBox(height: 24),
                _buildDailyMissionsSection(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialMissionSection() {
    if (_specialMission == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _specialMissionAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -0.3),
          end: Offset.zero,
        ).animate(_specialMissionAnimation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '✨ Missão Especial',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _petGlowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(
                              _petGlowAnimation.value * 0.3,
                            ),
                            Colors.pink.withOpacity(
                              _petGlowAnimation.value * 0.3,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIMITADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSpecialMissionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialMissionCard() {
    final mission = _specialMission!;
    final progress = mission['currentProgress'] as int;
    final target = mission['target'] as int;
    final progressPercent = (progress / target).clamp(0.0, 1.0);
    final isCompleted = progress >= target;

    return AnimatedBuilder(
      animation: _specialMissionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_specialMissionAnimation.value * 0.05),
          child: GestureDetector(
            onTap: () {
              // Ação da missão especial
              AppHelpers.showCustomSnackBar(
                context,
                isCompleted
                    ? 'Coletando recompensa...'
                    : 'Continuando missão...',
                icon: isCompleted ? Icons.pets : Icons.play_arrow,
              );
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCompleted
                      ? [
                          Colors.green.shade400,
                          Colors.green.shade500,
                          Colors.teal.shade400,
                        ]
                      : [
                          Colors.orange.shade400,
                          Colors.deepOrange.shade400,
                          Colors.red.shade400,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.4)
                        : Colors.orange.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Efeito de partículas
                  ...List.generate(12, (index) {
                    return Positioned(
                      left: (index * 30.0) % 320,
                      top: (index * 15.0) % 140 + 20,
                      child: AnimatedBuilder(
                        animation: _petController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (0.2 + (_petGlowAnimation.value - 0.5) * 2)
                                .clamp(0.0, 0.6),
                            child: Container(
                              width: 3,
                              height: 3,
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header com pet e título
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _petBounceAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale:
                                      0.9 + (_petBounceAnimation.value * 0.1),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    // child: Text(
                                    //   mission['petEmoji'] as String,
                                    //   style: const TextStyle(fontSize: 28),
                                    // ),
                                    child: Image.asset(
                                      mission['petEmoji'] as String,
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🐾 Adote um Pet',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mission['petType'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Progresso
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progresso: $progress/$target',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber.shade300,
                                      ),
                                      Text(
                                        ' +${mission['xp']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progressPercent,
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de status no canto superior direito
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isCompleted ? 'CONCLUÍDA' : 'ESPECIAL',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildDailyMissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎯 Missões Diárias',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Atualizar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _missionsAnimation,
          child: Column(
            children: _currentDailyMissions.asMap().entries.map((entry) {
              final index = entry.key;
              final mission = entry.value;
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _missionsController,
                        curve: Interval(
                          index * 0.15,
                          0.5 + (index * 0.15),
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    ),
                child: _buildMissionCard(mission, index),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, int index) {
    final missionId = mission['id'] as String;
    final isCompleted = false;
    final progress = 0;
    final target = mission['target'] as int;
    final progressPercent = target > 0
        ? (progress / target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        color: isCompleted ? Colors.green.shade50 : Theme.of(context).cardColor,
        borderRadius: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.shade100
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mission['icon'] as IconData,
                  color: isCompleted
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(' +${mission['xp']}'),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: Colors.orange,
                        ),
                        Text(' +${mission['moedas']}'),
                      ],
                    ),
                    if (!isCompleted && target > 1) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Progresso: $progress/$target',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedButton(
                backgroundColor: isCompleted ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                child: Text(
                  isCompleted ? 'Concluída' : 'Iniciar',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _missionsController.dispose();
    _specialMissionController.dispose();
    _petController.dispose();
    super.dispose();
  }
}
