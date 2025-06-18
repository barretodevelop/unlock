
// lib/features/onboarding/widgets/avatar_selection_grid.dart
import 'package:flutter/material.dart';
import 'package:unlock/features/onboarding/constants/onboarding_data.dart';
import 'package:unlock/models/avatar_model.dart';

class AvatarSelectionGrid extends StatelessWidget {
  final String? selectedAvatarId;
  final ValueChanged<String> onAvatarSelected;

  const AvatarSelectionGrid({
    super.key,
    this.selectedAvatarId,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatars = OnboardingConstants.freeAvatars;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final isSelected = avatar.id == selectedAvatarId;

        return GestureDetector(
          onTap: () => onAvatarSelected(avatar.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.primaryColor.withOpacity(0.1)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected 
                    ? theme.primaryColor 
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  avatar.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  avatar.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? theme.primaryColor
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
