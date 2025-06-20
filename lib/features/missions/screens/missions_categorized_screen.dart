// lib/features/missions/screens/missions_categorized_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/router/app_router.dart'; // Importar AppRoutes e NavigationUtils
import 'package:unlock/features/missions/models/mission.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';
import 'package:unlock/features/missions/widgets/mission_card.dart';

enum MissionFilterType { type, category }

class MissionsCategorizedScreen extends ConsumerStatefulWidget {
  const MissionsCategorizedScreen({super.key});

  @override
  ConsumerState<MissionsCategorizedScreen> createState() =>
      _MissionsCategorizedScreenState();
}

class _MissionsCategorizedScreenState
    extends ConsumerState<MissionsCategorizedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MissionFilterType _filterType = MissionFilterType.type; // Filtro inicial
  List<String> _currentTabs =
      []; // Keep track of the current tabs to detect changes

  // Helper method to get tabs based on current filter and missions state
  List<String> _getTabsFromMissionsState(MissionsState missionsState) {
    if (_filterType == MissionFilterType.type) {
      final types = missionsState.availableMissions
          .map((m) => m.type)
          .toSet()
          .toList();
      types.sort((a, b) => a.toString().compareTo(b.toString()));
      return types.map((t) => t.toString().split('.').last).toList();
    } else {
      return missionsState.availableMissions
          .map((m) => m.category)
          .toSet()
          .toList()
        ..sort();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initial setup of _currentTabs and _tabController.
    // We need to read the initial state of missionsProvider here.
    final missionsState = ref.read(missionsProvider);
    _currentTabs = _getTabsFromMissionsState(missionsState);
    _tabController = TabController(length: _currentTabs.length, vsync: this);
  }

  List<Mission> _getFilteredMissionsForTab(String tabName) {
    final missionsState = ref.watch(missionsProvider);
    if (_filterType == MissionFilterType.type) {
      return missionsState.availableMissions
          .where((m) => m.type.toString().split('.').last == tabName)
          .toList(); // Filter by MissionType
    } else {
      return missionsState.availableMissions
          .where((m) => m.category == tabName)
          .toList();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MissionsCategorizedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This method is called when the widget configuration changes.
    // We need to re-evaluate tabs here if the underlying data (missionsState)
    // or filterType changes, which would cause a rebuild of this widget.

    // Get the latest missions state
    final missionsState = ref.read(missionsProvider);
    final newTabs = _getTabsFromMissionsState(missionsState);

    // Check if the tabs have actually changed
    if (!listEquals(_currentTabs, newTabs)) {
      // Dispose the old controller before creating a new one
      _tabController.dispose();
      _tabController = TabController(length: newTabs.length, vsync: this);
      _currentTabs = newTabs; // Update the stored tabs
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionsState = ref.watch(missionsProvider);
    // No need to recalculate newTabs here if didUpdateWidget handles it.
    // _currentTabs should already be up-to-date.

    // If missionsState is loading and _currentTabs is empty, show a loading indicator.
    if (missionsState.isLoading && _currentTabs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // If there are no tabs, show a message.
    if (_currentTabs.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma categoria ou tipo de missão disponível.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Missões'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => NavigationUtils.popOrHome(context),
        ),
        actions: [
          // Adicionar um botão para trocar o tipo de filtro (opcional)
          // PopupMenuButton<MissionFilterType>(
          //   onSelected: (MissionFilterType result) {
          //     setState(() { // This setState will trigger didUpdateWidget
          //       _filterType = result;
          //     });
          //   },
          //   itemBuilder: (BuildContext context) => <PopupMenuEntry<MissionFilterType>>[
          //     const PopupMenuItem<MissionFilterType>(
          //       value: MissionFilterType.type,
          //       child: Text('Filtrar por Tipo'),
          //     ),
          //     const PopupMenuItem<MissionFilterType>(
          //       value: MissionFilterType.category,
          //       child: Text('Filtrar por Categoria'),
          //     ),
          //   ],
          // ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _currentTabs
              .map((tabName) => Tab(text: tabName.toUpperCase()))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _currentTabs.map((tabName) {
          final filteredMissions = _getFilteredMissionsForTab(tabName);
          if (missionsState.isLoading) {
            // Only show loading if missionsState is loading AND there are no filtered missions yet
            return const Center(child: CircularProgressIndicator());
          }
          if (filteredMissions.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma missão para "$tabName"',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredMissions.length,
            itemBuilder: (context, index) {
              final mission = filteredMissions[index];
              final progress = missionsState.userProgress[mission.id];
              return MissionCard(mission: mission, progress: progress);
            },
          );
        }).toList(),
      ),
    );
  }
}

// Helper para comparar listas, pode ser movido para um arquivo de utils
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
