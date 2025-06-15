import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/data/mock_data_provider.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';
import 'package:unlock/utils/helpers.dart';
import 'package:unlock/widgtes/animated_button.dart';
import 'package:unlock/widgtes/custom_card.dart';

final MockDataProvider dataProvider = MockDataProvider();

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _missionsController;

  late Animation<double> _missionsAnimation;
  List<Map<String, dynamic>> _currentDailyMissions = [];
  bool _isLoadingMissions = true;

  @override
  void initState() {
    super.initState();

    _missionsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _missionsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _missionsController, curve: Curves.easeOut),
    );

    _initializeMissionPage();
  }

  void _initializeMissionPage() async {
    // Simula carregamento das missões
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentDailyMissions = dataProvider.getDailyMissions();
      _isLoadingMissions = false;
    });

    _missionsController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider).user;

    return Center(child: _buildDailyMissionsSection());
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
              onPressed: () {
                setState(() {
                  _currentDailyMissions = dataProvider.getDailyMissions();
                });
                AppHelpers.showCustomSnackBar(
                  context,
                  'Missões atualizadas!',
                  icon: Icons.refresh,
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Atualizar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingMissions)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else
          FadeTransition(
            opacity: _missionsAnimation,
            child: Column(
              children: _currentDailyMissions.asMap().entries.map((entry) {
                final index = entry.key;
                final mission = entry.value;
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _missionsController,
                          curve: Interval(
                            index * 0.2,
                            0.6 + (index * 0.2),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                  child: _buildMissionCard(mission),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final missionId = mission['id'] as String;
    final isCompleted =
        false; //currentUser.completedMissionIds.contains(missionId);
    final progress = 0;
    //currentUser.missionProgress[missionId] ?? 0;
    final target = mission['target'] as int;
    final progressPercent = target > 0
        ? (progress / target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        color: isCompleted ? Colors.green.shade50 : Theme.of(context).cardColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade100
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' +${mission['xp']}'),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: Colors.orange,
                      ),
                      Text(' +${mission['moedas']}'),
                    ],
                  ),
                  if (!isCompleted && target > 1) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              // onPressed: isCompleted ? null : () => _completarMissao(mission),
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
    );
  }

  @override
  void dispose() {
    _missionsController.dispose();
    super.dispose();
  }
}
