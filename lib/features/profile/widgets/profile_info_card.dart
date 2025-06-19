// lib/features/profile/widgets/profile_info_card.dart
import 'package:flutter/material.dart';
import 'package:unlock/models/user_model.dart';

/// Card com informações detalhadas do usuário
class ProfileInfoCard extends StatelessWidget {
  final UserModel user;
  final bool isEditable;
  final VoidCallback? onEditTap;

  const ProfileInfoCard({
    super.key,
    required this.user,
    this.isEditable = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da seção
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informações Pessoais',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isEditable && onEditTap != null)
                IconButton(
                  onPressed: onEditTap,
                  icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Email
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            iconColor: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Codinome
          if (user.codinome?.isNotEmpty == true)
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Codinome',
              value: user.codinome!,
              iconColor: Colors.purple,
            ),

          if (user.codinome?.isNotEmpty == true) const SizedBox(height: 16),

          // Idade
          if (user.age != null)
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Idade',
              value: '${user.age} anos',
              iconColor: Colors.pink,
            ),

          if (user.age != null) const SizedBox(height: 16),

          // Objetivo
          if (user.relationshipGoal?.isNotEmpty == true)
            _InfoRow(
              icon: Icons.favorite_outline,
              label: 'Objetivo',
              value: _formatRelationshipGoal(user.relationshipGoal!),
              iconColor: Colors.red,
            ),

          if (user.relationshipGoal?.isNotEmpty == true)
            const SizedBox(height: 16),

          // Nível de conexão
          _InfoRow(
            icon: Icons.connect_without_contact_outlined,
            label: 'Nível de Conexão',
            value: '${user.connectionLevel}/10',
            iconColor: Colors.teal,
          ),

          const SizedBox(height: 16),

          // Data de criação
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membro desde',
            value: _formatDate(user.createdAt),
            iconColor: Colors.orange,
          ),

          // Onboarding status
          if (!user.onboardingCompleted) ...[
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.pending_outlined,
              label: 'Status',
              value: 'Onboarding pendente',
              iconColor: Colors.amber,
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }

  String _formatRelationshipGoal(String goal) {
    // Mapear valores técnicos para nomes amigáveis
    final goalMap = {
      'friendship': 'Amizade',
      'dating': 'Namoro',
      'serious': 'Relacionamento Sério',
      'casual': 'Casual',
      'networking': 'Networking',
    };

    return goalMap[goal] ?? goal;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Row de informação individual
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isWarning;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),

        const SizedBox(width: 16),

        // Informação
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isWarning ? Colors.amber : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de interesses do usuário
class InterestsCard extends StatelessWidget {
  final UserModel user;
  final bool isEditable;
  final VoidCallback? onEditTap;

  const InterestsCard({
    super.key,
    required this.user,
    this.isEditable = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user.interesses.isEmpty) {
      return _EmptyInterestsCard(isEditable: isEditable, onEditTap: onEditTap);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.interests_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Interesses',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isEditable && onEditTap != null)
                IconButton(
                  onPressed: onEditTap,
                  icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Chips de interesses
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interesses.map((interesse) {
              return _InterestChip(
                label: interesse,
                color: _getInterestColor(interesse),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getInterestColor(String interest) {
    // Cores diferentes para diferentes tipos de interesse
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[interest.hashCode % colors.length];
  }
}

/// Chip individual de interesse
class _InterestChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InterestChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Card vazio para quando não há interesses
class _EmptyInterestsCard extends StatelessWidget {
  final bool isEditable;
  final VoidCallback? onEditTap;

  const _EmptyInterestsCard({this.isEditable = false, this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.interests_outlined,
            color: colorScheme.onSurface.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum interesse adicionado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus interesses para encontrar pessoas com gostos similares',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (isEditable && onEditTap != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar Interesses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card compacto de informações
class CompactInfoCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const CompactInfoCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CompactInfoItem(
                    icon: Icons.cake,
                    value: user.age != null ? '${user.age} anos' : 'N/A',
                    color: Colors.pink,
                  ),
                ),
                Expanded(
                  child: _CompactInfoItem(
                    icon: Icons.connect_without_contact,
                    value: '${user.connectionLevel}/10',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            if (user.relationshipGoal?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _CompactInfoItem(
                icon: Icons.favorite,
                value: user.relationshipGoal!,
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactInfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _CompactInfoItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
