
// lib/features/onboarding/widgets/interest_chip_grid.dart
import 'package:flutter/material.dart';
import 'package:unlock/features/onboarding/constants/onboarding_data.dart';

class InterestChipGrid extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<String> onInterestToggled;
  final VoidCallback? onQuickFill;
  final int? userAge;

  const InterestChipGrid({
    super.key,
    required this.selectedInterests,
    required this.onInterestToggled,
    this.onQuickFill,
    this.userAge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Fill Button
        if (userAge != null && onQuickFill != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onQuickFill,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text('Sugestões para ${userAge}+ anos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Interests Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OnboardingConstants.availableInterests.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (_) => onInterestToggled(interest),
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
              side: BorderSide(
                color: isSelected 
                    ? theme.primaryColor 
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
              labelStyle: TextStyle(
                color: isSelected 
                    ? theme.primaryColor
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Counter
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selectedInterests.length >= OnboardingConstants.minInterests
                  ? theme.primaryColor.withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedInterests.length >= OnboardingConstants.minInterests
                    ? theme.primaryColor
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${selectedInterests.length}/${OnboardingConstants.maxInterests} selecionados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: selectedInterests.length >= OnboardingConstants.minInterests
                    ? theme.primaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}