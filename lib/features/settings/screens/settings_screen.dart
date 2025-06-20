// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/router/app_router.dart'; // Importar AppRoutes e NavigationUtils
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/features/settings/providers/settings_provider.dart';
import 'package:unlock/features/settings/widgets/settings_tile.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/user_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Configurações',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => NavigationUtils.popOrHome(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com informações do usuário
            if (authState.user != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    UserAvatar.large(user: authState.user, showBorder: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user!.codinome?.isNotEmpty == true
                                ? authState.user!.codinome!
                                : authState.user!.username,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.user!.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Level ${authState.user!.level}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Seção de Aparência
            SettingsSection(
              title: 'Aparência',
              children: [
                SettingsTile.switchTile(
                  icon: settings.isDarkTheme
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Tema Escuro',
                  subtitle: settings.isDarkTheme
                      ? 'Usando tema escuro'
                      : 'Usando tema claro',
                  value: settings.isDarkTheme,
                  onChanged: (value) => _toggleTheme(context, ref),
                  iconColor: settings.isDarkTheme
                      ? Colors.indigo
                      : Colors.amber,
                ),
              ],
            ),

            // Seção de Notificações
            SettingsSection(
              title: 'Notificações',
              children: [
                SettingsTile.switchTile(
                  icon: settings.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  title: 'Notificações',
                  subtitle: settings.notificationsEnabled
                      ? 'Receber notificações do app'
                      : 'Notificações desabilitadas',
                  value: settings.notificationsEnabled,
                  onChanged: (value) => _toggleNotifications(context, ref),
                  iconColor: settings.notificationsEnabled
                      ? Colors.green
                      : Colors.grey,
                ),

                SettingsTile.switchTile(
                  icon: settings.soundEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  title: 'Sons',
                  subtitle: settings.soundEnabled
                      ? 'Sons e efeitos sonoros ativos'
                      : 'Sons desabilitados',
                  value: settings.soundEnabled,
                  onChanged: (value) => _toggleSound(context, ref),
                  enabled: settings.notificationsEnabled,
                  iconColor: settings.soundEnabled ? Colors.blue : Colors.grey,
                ),
              ],
            ),

            // Seção de Conta
            SettingsSection(
              title: 'Conta',
              children: [
                SettingsTile.navigation(
                  icon: Icons.person,
                  title: 'Editar Perfil',
                  subtitle: 'Alterar informações do perfil',
                  onTap: () => _navigateToAccountSettings(context), // Alterado
                  iconColor: Colors.purple,
                ),

                SettingsTile.navigation(
                  icon: Icons.privacy_tip,
                  title: 'Privacidade',
                  subtitle: 'Configurações de privacidade',
                  onTap: () => _showPrivacySettings(context),
                  iconColor: Colors.orange,
                ),
              ],
            ),

            // Seção de Suporte
            SettingsSection(
              title: 'Suporte',
              children: [
                SettingsTile.navigation(
                  icon: Icons.help_outline,
                  title: 'Ajuda',
                  subtitle: 'Central de ajuda e FAQ',
                  onTap: () => _showHelp(context),
                  iconColor: Colors.teal,
                ),

                SettingsTile.navigation(
                  icon: Icons.info_outline,
                  title: 'Sobre',
                  subtitle: 'Versão e informações do app',
                  onTap: () => _showAbout(context),
                  iconColor: Colors.cyan,
                ),
              ],
            ),

            // Seção de Ações
            SettingsSection(
              title: 'Ações',
              children: [
                SettingsTile.action(
                  icon: Icons.refresh,
                  title: 'Redefinir Configurações',
                  subtitle: 'Voltar às configurações padrão',
                  onTap: () => _resetSettings(context, ref),
                  iconColor: Colors.grey,
                ),

                SettingsTile.action(
                  icon: Icons.logout,
                  title: 'Sair',
                  subtitle: 'Fazer logout da conta',
                  onTap: () => _showLogoutDialog(context, ref),
                  iconColor: Colors.red,
                ),
              ],
            ),

            // Espaçamento inferior
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Alternar tema
  Future<void> _toggleTheme(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleTheme();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(settingsProvider).isDarkTheme
                  ? 'Tema escuro ativado'
                  : 'Tema claro ativado',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ SettingsScreen: Erro ao alternar tema: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao alterar tema'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Alternar notificações
  Future<void> _toggleNotifications(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(settingsProvider).notificationsEnabled
                  ? 'Notificações ativadas'
                  : 'Notificações desativadas',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ SettingsScreen: Erro ao alternar notificações: $e');
    }
  }

  /// Alternar som
  Future<void> _toggleSound(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleSound();
    } catch (e) {
      AppLogger.error('❌ SettingsScreen: Erro ao alternar som: $e');
    }
  }

  /// Navegar para perfil
  void _navigateToAccountSettings(BuildContext context) {
    context.push(
      AppRoutes.accountSettings,
    ); // Alterado para a rota de configurações da conta
  }

  /// Mostrar configurações de privacidade
  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidade'),
        content: const Text('Configurações de privacidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar ajuda
  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda'),
        content: const Text('Central de ajuda em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostrar sobre
  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Unlock',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Unlock App. Todos os direitos reservados.',
      children: [
        const Text('App de rede social gamificada com conexões autênticas.'),
      ],
    );
  }

  /// Redefinir configurações
  Future<void> _resetSettings(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir Configurações'),
        content: const Text(
          'Tem certeza que deseja voltar às configurações padrão? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(settingsProvider.notifier).resetToDefaults();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configurações redefinidas')),
          );
        }
      } catch (e) {
        AppLogger.error('❌ SettingsScreen: Erro ao redefinir: $e');
      }
    }
  }

  /// Mostrar diálogo de logout
  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).signOut();

        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        AppLogger.error('❌ SettingsScreen: Erro ao fazer logout: $e');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao fazer logout'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
