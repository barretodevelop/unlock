// lib/features/rankings/widgets/ranking_category_selector.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/ranking_model.dart';
import 'package:unlock/services/analytics/analytics_integration.dart';
import 'package:unlock/services/analytics/interfaces/analytics_interface.dart';

/// Seletor horizontal de categorias de ranking
class RankingCategorySelector extends StatefulWidget {
  final RankingCategory selectedCategory;
  final Function(RankingCategory) onCategoryChanged;
  final bool showDescription;
  final EdgeInsets? padding;

  const RankingCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.showDescription = false,
    this.padding,
  });

  @override
  State<RankingCategorySelector> createState() => _RankingCategorySelectorState();
}

class _RankingCategorySelectorState extends State<RankingCategorySelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Scroll para categoria selecionada após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  @override
  void didUpdateWidget(RankingCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Se categoria mudou, scroll para ela
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _scrollToSelectedCategory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll para a categoria selecionada
  void _scrollToSelectedCategory() {
    final selectedIndex = RankingCategory.values.indexOf(widget.selectedCategory);
    if (selectedIndex == -1) return;

    // Calcular posição aproximada
    const itemWidth = 120.0; // Largura aproximada de cada chip
    const spacing = 12.0;
    final targetOffset = (itemWidth + spacing) * selectedIndex;

    // Scroll animado
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.showDescription ? 100 : 80,
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: RankingCategory.values.length,
        itemBuilder: (context, index) {
          final category = RankingCategory.values[index];
          final isSelected = category == widget.selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryChip(
              category: category,
              isSelected: isSelected,
              showDescription: widget.showDescription,
              onTap: () => _onCategoryTapped(category),
            ),
          );
        },
      ),
    );
  }

  /// Handler para toque na categoria
  void _onCategoryTapped(RankingCategory category) {
    if (category == widget.selectedCategory) return;

    AppLogger.debug('🏅 Categoria de ranking selecionada: ${category.id}');
    
    // Analytics
    _trackCategoryChange(category);
    
    // Callback
    widget.onCategoryChanged(category);
  }

  /// Track mudança de categoria
  void _trackCategoryChange(RankingCategory category) async {
    try {
      if (AnalyticsIntegration.isEnabled) {
        await AnalyticsIntegration.manager.trackEvent(
          'ranking_category_selected',
          parameters: {
            'category': category.id,
            'category_label': category.label,
            'previous_category': widget.selectedCategory.id,
          },
          category: EventCategory.user,
        );
      }
    } catch (e) {
      AppLogger.debug('Erro ao enviar analytics de categoria: $e');
    }
  }
}

/// Chip individual de categoria
class _CategoryChip extends StatefulWidget {
  final RankingCategory category;
  final bool isSelected;
  final bool showDescription;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.showDescription,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AppConstants.animationDuration,
              width: widget.showDescription ? 140 : 120,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.category.color
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.category.color
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: widget.category.color.withOpacity(0.3),
                      blurRadius: 8 + (_elevationAnimation.value * 2),
                      offset: Offset(0, 2 + _elevationAnimation.value),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone e label principal
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.category.icon,
                        size: 20,
                        color: widget.isSelected
                            ? Colors.white
                            : widget.category.color,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.category.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: widget.isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: widget.isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Descrição (se habilitada)
                  if (widget.showDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.category.description,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.9)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Seletor vertical de categorias (para layout diferente)
class VerticalRankingCategorySelector extends StatelessWidget {
  final RankingCategory selectedCategory;
  final Function(RankingCategory) onCategoryChanged;

  const VerticalRankingCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Categorias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: RankingCategory.values.length,
            itemBuilder: (context, index) {
              final category = RankingCategory.values[index];
              final isSelected = category == selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _VerticalCategoryItem(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => onCategoryChanged(category),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Item vertical de categoria
class _VerticalCategoryItem extends StatelessWidget {
  final RankingCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _VerticalCategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      decoration: BoxDecoration(
        color: isSelected
            ? category.color.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? category.color
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? category.color
                : category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            category.icon,
            color: isSelected
                ? Colors.white
                : category.color,
            size: 20,
          ),
        ),
        
        title: Text(
          category.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? category.color : null,
              ),
        ),
        
        subtitle: Text(
          category.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
              ),
        ),
        
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: category.color,
                size: 20,
              )
            : null,
        
        onTap: onTap,
      ),
    );
  }
}

/// Seletor compacto de categorias (para espaços pequenos)
class CompactRankingCategorySelector extends StatelessWidget {
  final RankingCategory selectedCategory;
  final Function(RankingCategory) onCategoryChanged;

  const CompactRankingCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<RankingCategory>(
        value: selectedCategory,
        onChanged: (category) {
          if (category != null) {
            onCategoryChanged(category);
          }
        },
        items: RankingCategory.values.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 16,
                  color: category.color,
                ),
                const SizedBox(width: 8),
                Text(category.label),
              ],
            ),
          );
        }).toList(),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}