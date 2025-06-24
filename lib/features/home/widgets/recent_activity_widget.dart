
// lib/features/home/widgets/recent_activity_widget.dart
import 'package:flutter/material.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock de atividades recentes
    final activities = [
      _Activity(
        title: 'João venceu o desafio "Melhor Foto"',
        time: 'Há 2 horas',
        icon: Icons.emoji_events,
        color: Colors.amber,
      ),
      _Activity(
        title: 'Maria entrou no grupo "Amigos da Faculdade"',
        time: 'Há 4 horas',
        icon: Icons.group_add,
        color: Colors.blue,
      ),
      _Activity(
        title: 'Novo desafio "Quiz de História" disponível',
        time: 'Há 6 horas',
        icon: Icons.quiz,
        color: Colors.green,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: activities.map((activity) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActivityItem(context, activity),
        )).toList(),
      ),
    );
  }

  /// Construir item de atividade
  Widget _buildActivityItem(BuildContext context, _Activity activity) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            activity.icon,
            color: activity.color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                activity.time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Classe para atividades
class _Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _Activity({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}