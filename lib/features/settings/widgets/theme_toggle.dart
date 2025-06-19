// lib/features/settings/widgets/theme_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/settings/providers/settings_provider.dart';

/// Widget específico para alternar tema
class ThemeToggle extends ConsumerWidget {
  final bool showLabel;
  final bool isCompact;
  final VoidCallback? onChanged;

  const ThemeToggle({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    if (isCompact) {
      return _CompactThemeToggle(
        isDark: settings.isDarkTheme,
        onToggle: () => _toggleTheme(ref),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Ícone do tema atual
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: settings.isDarkTheme
                  ? Colors.indigo.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              settings.isDarkTheme ? Icons.dark_mode : Icons.light_mode,
              color: settings.isDarkTheme ? Colors.indigo : Colors.amber,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Label e descrição
          if (showLabel)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema Escuro',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.isDarkTheme
                        ? 'Usando tema escuro'
                        : 'Usando tema claro',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

          // Switch personalizado
          _AnimatedThemeSwitch(
            value: settings.isDarkTheme,
            onChanged: (value) {
              _toggleTheme(ref);
              onChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTheme(WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleTheme();
    } catch (e) {
      // Erro já é tratado no provider
    }
  }
}

/// Switch animado personalizado para tema
class _AnimatedThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedThemeSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value ? Colors.indigo : colorScheme.outline.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Ícones de fundo
            Positioned(
              left: 6,
              top: 6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: value ? 0.0 : 1.0,
                child: Icon(Icons.light_mode, size: 20, color: Colors.amber),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: value ? 1.0 : 0.0,
                child: Icon(Icons.dark_mode, size: 20, color: Colors.white),
              ),
            ),

            // Thumb do switch
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value ? 28 : 4,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  value ? Icons.nights_stay : Icons.wb_sunny,
                  size: 14,
                  color: value ? Colors.indigo : Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versão compacta do toggle de tema
class _CompactThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _CompactThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.indigo.withOpacity(0.1)
              : Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.indigo.withOpacity(0.3)
                : Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? Colors.indigo : Colors.amber,
          size: 20,
        ),
      ),
    );
  }
}

/// Botão flutuante para alternar tema
class FloatingThemeToggle extends ConsumerWidget {
  final EdgeInsets? margin;

  const FloatingThemeToggle({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: FloatingActionButton(
        mini: true,
        onPressed: () => _toggleTheme(ref),
        backgroundColor: settings.isDarkTheme ? Colors.indigo : Colors.amber,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            settings.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
            key: ValueKey(settings.isDarkTheme),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTheme(WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleTheme();
    } catch (e) {
      // Erro já é tratado no provider
    }
  }
}

/// Card de seleção de tema com opções visuais
class ThemeSelectionCard extends ConsumerWidget {
  const ThemeSelectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escolha o Tema',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  title: 'Claro',
                  subtitle: 'Tema claro e limpo',
                  icon: Icons.light_mode,
                  color: Colors.amber,
                  isSelected: !settings.isDarkTheme,
                  onTap: () => _setLightTheme(ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeOption(
                  title: 'Escuro',
                  subtitle: 'Tema escuro e elegante',
                  icon: Icons.dark_mode,
                  color: Colors.indigo,
                  isSelected: settings.isDarkTheme,
                  onTap: () => _setDarkTheme(ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setLightTheme(WidgetRef ref) async {
    final currentSettings = ref.read(settingsProvider);
    if (!currentSettings.isDarkTheme) return;

    try {
      await ref.read(settingsProvider.notifier).toggleTheme();
    } catch (e) {
      // Erro tratado no provider
    }
  }

  Future<void> _setDarkTheme(WidgetRef ref) async {
    final currentSettings = ref.read(settingsProvider);
    if (currentSettings.isDarkTheme) return;

    try {
      await ref.read(settingsProvider.notifier).toggleTheme();
    } catch (e) {
      // Erro tratado no provider
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
