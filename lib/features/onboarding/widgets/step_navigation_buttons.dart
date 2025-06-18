
// lib/features/onboarding/widgets/step_navigation_buttons.dart
import 'package:flutter/material.dart';
import 'package:unlock/core/constants/app_constants.dart';

class StepNavigationButtons extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String? nextText;
  final String? backText;
  final bool showBack;
  final bool isLoading;

  const StepNavigationButtons({
    super.key,
    this.onNext,
    this.onBack,
    this.nextText,
    this.backText,
    this.showBack = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Back Button
          if (showBack) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(backText ?? 'Voltar'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Next Button
          Expanded(
            flex: showBack ? 1 : 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(nextText ?? 'Continuar'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
