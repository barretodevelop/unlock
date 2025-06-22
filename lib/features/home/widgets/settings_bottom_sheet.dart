// lib/features/home/widgets/settings_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/theme_provider.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Configurações', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            title: const Text('Tema Escuro'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) => ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Sair', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              Navigator.of(context).pop(); // Fecha o BottomSheet
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}