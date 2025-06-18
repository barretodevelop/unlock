// lib/features/missions/widgets/mission_category_tabs.dart
// Widget de abas para categorias de missões - Fase 3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_theme.dart';
import 'package:unlock/features/missions/models/mission_model.dart';
import 'package:unlock/features/missions/providers/missions_provider.dart';

/// Provider para controlar a categoria selecionada
final selectedMissionCategoryProvider = StateProvider<MissionCategory?>(
  (ref) => null,
);

/// Widget de abas para filtrar missões por categoria
class MissionCategoryTabs extends ConsumerWidget {
  final Function(MissionCategory?)? onCategoryChanged;
  final bool showAll;
  final TabController? tabController;

  const MissionCategoryTabs({
    super.key,
    this.onCategoryChanged,
    this.showAll = true,
    this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedMissionCategoryProvider);
    final missionsState = ref.watch(missionsProvider);

    // Calcular contagem por categoria
    final categoryCounts = _calculateCategoryCounts(
      missionsState.activeMissions,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Tab "Todas"
            if (showAll)
              _buildCategoryTab(
                context,
                theme,
                ref,
                null,
                'Todas',
                '📋',
                missionsState.activeMissions.length,
                selectedCategory == null,
              ),

            // Tabs por categoria
            ...MissionCategory.values.map((category) {
              final count = categoryCounts[category] ?? 0;
              final isSelected = selectedCategory == category;

              return Container(
                margin: const EdgeInsets.only(left: 8),
                child: _buildCategoryTab(
                  context,
                  theme,
                  ref,
                  category,
                  category.displayName,
                  category.icon,
                  count,
                  isSelected,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Calcular contagem de missões por categoria
  Map<MissionCategory, int> _calculateCategoryCounts(
    List<MissionModel> missions,
  ) {
    final counts = <MissionCategory, int>{};

    for (final category in MissionCategory.values) {
      counts[category] = missions.where((m) => m.category == category).length;
    }

    return counts;
  }

  /// Construir tab individual de categoria
  Widget _buildCategoryTab(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    MissionCategory? category,
    String label,
    String icon,
    int count,
    bool isSelected,
  ) {
    final color = _getCategoryColor(category);

    return GestureDetector(
      onTap: () => _onCategoryTap(ref, category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Text(icon, style: TextStyle(fontSize: isSelected ? 18 : 16)),

            const SizedBox(width: 8),

            // Label
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),

            // Badge de contagem
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Obter cor da categoria
  Color _getCategoryColor(MissionCategory? category) {
    switch (category) {
      case MissionCategory.social:
        return AppTheme.primaryColor;
      case MissionCategory.profile:
        return AppTheme.secondaryColor;
      case MissionCategory.exploration:
        return AppTheme.accentColor;
      case MissionCategory.gamification:
        return AppTheme.successColor;
      case null:
        return AppTheme.primaryColor;
    }
  }

  /// Ação ao tocar em categoria
  void _onCategoryTap(WidgetRef ref, MissionCategory? category) {
    ref.read(selectedMissionCategoryProvider.notifier).state = category;
    onCategoryChanged?.call(category);
  }
}

/// Widget de tabs usando TabBar do Material Design
class MaterialMissionCategoryTabs extends ConsumerStatefulWidget {
  final Function(MissionCategory?)? onCategoryChanged;
  final bool showAll;

  const MaterialMissionCategoryTabs({
    super.key,
    this.onCategoryChanged,
    this.showAll = true,
  });

  @override
  ConsumerState<MaterialMissionCategoryTabs> createState() =>
      _MaterialMissionCategoryTabsState();
}

class _MaterialMissionCategoryTabsState
    extends ConsumerState<MaterialMissionCategoryTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<MissionCategory?> _categories;

  @override
  void initState() {
    super.initState();

    _categories = [if (widget.showAll) null, ...MissionCategory.values];

    _tabController = TabController(length: _categories.length, vsync: this);

    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final category = _categories[_tabController.index];
      ref.read(selectedMissionCategoryProvider.notifier).state = category;
      widget.onCategoryChanged?.call(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missionsState = ref.watch(missionsProvider);
    final categoryCounts = _calculateCategoryCounts(
      missionsState.activeMissions,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: _categories.map((category) {
          final isAll = category == null;
          final label = isAll ? 'Todas' : category.displayName;
          final icon = isAll ? '📋' : category.icon;
          final count = isAll
              ? missionsState.activeMissions.length
              : (categoryCounts[category] ?? 0);

          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(label),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Calcular contagem de missões por categoria
  Map<MissionCategory, int> _calculateCategoryCounts(
    List<MissionModel> missions,
  ) {
    final counts = <MissionCategory, int>{};

    for (final category in MissionCategory.values) {
      counts[category] = missions.where((m) => m.category == category).length;
    }

    return counts;
  }
}

/// Widget de filtro dropdown para categorias
class MissionCategoryDropdown extends ConsumerWidget {
  final Function(MissionCategory?)? onCategoryChanged;
  final bool showAll;

  const MissionCategoryDropdown({
    super.key,
    this.onCategoryChanged,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedMissionCategoryProvider);
    final missionsState = ref.watch(missionsProvider);
    final categoryCounts = _calculateCategoryCounts(
      missionsState.activeMissions,
    );

    final categories = [if (showAll) null, ...MissionCategory.values];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MissionCategory?>(
          value: selectedCategory,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          style: theme.textTheme.bodyMedium,
          dropdownColor: theme.colorScheme.surface,
          onChanged: (category) {
            ref.read(selectedMissionCategoryProvider.notifier).state = category;
            onCategoryChanged?.call(category);
          },
          items: categories.map((category) {
            final isAll = category == null;
            final label = isAll ? 'Todas as Categorias' : category.displayName;
            final icon = isAll ? '📋' : category.icon;
            final count = isAll
                ? missionsState.activeMissions.length
                : (categoryCounts[category] ?? 0);

            return DropdownMenuItem<MissionCategory?>(
              value: category,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(label),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getCategoryColor(category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Calcular contagem de missões por categoria
  Map<MissionCategory, int> _calculateCategoryCounts(
    List<MissionModel> missions,
  ) {
    final counts = <MissionCategory, int>{};

    for (final category in MissionCategory.values) {
      counts[category] = missions.where((m) => m.category == category).length;
    }

    return counts;
  }

  /// Obter cor da categoria
  Color _getCategoryColor(MissionCategory? category) {
    switch (category) {
      case MissionCategory.social:
        return AppTheme.primaryColor;
      case MissionCategory.profile:
        return AppTheme.secondaryColor;
      case MissionCategory.exploration:
        return AppTheme.accentColor;
      case MissionCategory.gamification:
        return AppTheme.successColor;
      case null:
        return AppTheme.primaryColor;
    }
  }
}

/// Widget de chips para seleção múltipla de categorias
class MissionCategoryChips extends ConsumerWidget {
  final Function(Set<MissionCategory>)? onCategoriesChanged;
  final bool allowMultiple;

  const MissionCategoryChips({
    super.key,
    this.onCategoriesChanged,
    this.allowMultiple = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedMissionCategoryProvider);
    final missionsState = ref.watch(missionsProvider);
    final categoryCounts = _calculateCategoryCounts(
      missionsState.activeMissions,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MissionCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          final count = categoryCounts[category] ?? 0;
          final color = _getCategoryColor(category);

          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.icon),
                const SizedBox(width: 6),
                Text(category.displayName),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selectedColor: color,
            checkmarkColor: Colors.white,
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: isSelected ? color : color.withOpacity(0.3),
              width: 1,
            ),
            onSelected: (selected) {
              if (selected) {
                ref.read(selectedMissionCategoryProvider.notifier).state =
                    category;
                onCategoriesChanged?.call({category});
              } else {
                ref.read(selectedMissionCategoryProvider.notifier).state = null;
                onCategoriesChanged?.call({});
              }
            },
          );
        }).toList(),
      ),
    );
  }

  /// Calcular contagem de missões por categoria
  Map<MissionCategory, int> _calculateCategoryCounts(
    List<MissionModel> missions,
  ) {
    final counts = <MissionCategory, int>{};

    for (final category in MissionCategory.values) {
      counts[category] = missions.where((m) => m.category == category).length;
    }

    return counts;
  }

  /// Obter cor da categoria
  Color _getCategoryColor(MissionCategory category) {
    switch (category) {
      case MissionCategory.social:
        return AppTheme.primaryColor;
      case MissionCategory.profile:
        return AppTheme.secondaryColor;
      case MissionCategory.exploration:
        return AppTheme.accentColor;
      case MissionCategory.gamification:
        return AppTheme.successColor;
    }
  }
}

/// Provider para missões filtradas por categoria
final filteredMissionsProvider = Provider<List<MissionModel>>((ref) {
  final selectedCategory = ref.watch(selectedMissionCategoryProvider);
  final missionsState = ref.watch(missionsProvider);

  if (selectedCategory == null) {
    return missionsState.activeMissions;
  }

  return missionsState.activeMissions
      .where((mission) => mission.category == selectedCategory)
      .toList();
});

/// Indicador de categoria com ícone e nome
class CategoryIndicator extends StatelessWidget {
  final MissionCategory category;
  final bool isSelected;
  final int? count;

  const CategoryIndicator({
    super.key,
    required this.category,
    this.isSelected = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(isSelected ? 0.5 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            category.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(MissionCategory category) {
    switch (category) {
      case MissionCategory.social:
        return AppTheme.primaryColor;
      case MissionCategory.profile:
        return AppTheme.secondaryColor;
      case MissionCategory.exploration:
        return AppTheme.accentColor;
      case MissionCategory.gamification:
        return AppTheme.successColor;
    }
  }
}
