
// lib/features/home/widgets/quick_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';

class QuickStatsWidget extends StatelessWidget {
  final UserModel user;

  const QuickStatsWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Faíscas',
              user.coins.toString(),
              Icons.bolt,
              Colors.amber,
            ),
          ),
          _buildDivider(context),
          Expanded(
            child: _buildStatItem(
              context,
              'Gemas',
              user.gems.toString(),
              Icons.diamond,
              Colors.purple,
            ),
          ),
          _buildDivider(context),
          Expanded(
            child: _buildStatItem(
              context,
              'Streak',
              '${user.loginStreak ?? 0}',
              Icons.local_fire_department,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir item de estatística
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Construir divisor
  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }
}

 