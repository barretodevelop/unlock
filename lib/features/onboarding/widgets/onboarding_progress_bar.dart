// lib/features/onboarding/widgets/onboarding_progress_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/onboarding/constants/onboarding_data.dart';
import 'package:unlock/features/onboarding/providers/onboarding_provider.dart';

class OnboardingProgressBar extends ConsumerWidget {
  const OnboardingProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final progress = ref.watch(onboardingProgressProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(theme.primaryColor),
          minHeight: 4,
        ),

        const SizedBox(height: 12),

        // Progress Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              OnboardingConstants.progressTexts[onboardingState.currentStep] ??
                  '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),

            // Step Indicators
            Row(
              children: List.generate(3, (index) {
                final isCompleted = index < onboardingState.currentStep;
                final isCurrent = index == onboardingState.currentStep;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent
                        ? theme.primaryColor
                        : theme.colorScheme.surfaceVariant,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
