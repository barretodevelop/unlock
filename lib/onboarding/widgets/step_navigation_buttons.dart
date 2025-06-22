// lib/features/onboarding/widgets/step_navigation_buttons.dart
import 'package:flutter/material.dart';

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
              flex: 1,
              child: OutlinedButton(
                // ...
                onPressed: isLoading ? null : onBack,
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.center, // Removido para permitir que o Expanded funcione corretamente
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(backText ?? 'Voltar'),
                    ), // Envolve o Text em Expanded
                  ],
                ),
              ),
            ), // Fim do Expanded do botão "Voltar"
            SizedBox(width: 5),
          ],

          // Next Button
          Expanded(
            flex: showBack ? 2 : 1,
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
                      // mainAxisAlignment: MainAxisAlignment.center, // Removido para permitir que o Expanded funcione corretamente
                      children: [
                        Expanded(
                          // Envolve o Text em Expanded
                          child: Text(
                            nextText ?? 'Continuar',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        // O ícone de seta foi mantido comentado, conforme sua observação anterior.
                        // Se desejar reativá-lo, descomente e teste novamente.
                        // const SizedBox(width: 2),
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
