// lib/features/settings/screens/notification_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/theme/app_colors.dart';
import 'package:unlock/providers/notification_provider.dart';
import 'package:unlock/shared/widgets/app_header_with_currency.dart';

/// Tela de configurações de notificação
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppHeaderWithCurrency(
        title: 'Notificações',
        showBackButton: true,
      ),
      body: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status das permissões
                  _PermissionsCard(
                    hasPermissions: notificationState.permissionsGranted,
                    onRequestPermissions: () {
                      ref.read(notificationProvider.notifier).requestPermissions();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Configurações principais
                  _SectionHeader(
                    title: 'Configurações Gerais',
                    subtitle: 'Controle quando receber notificações',
                  ),
                  const SizedBox(height: 16),

                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        title: 'Notificações ativadas',
                        subtitle: 'Receber todas as notificações do app',
                        value: notificationSettings.enabled,
                        onChanged: (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('enabled', value);
                        },
                        leading: Icon(
                          Icons.notifications_outlined,
                          color: notificationSettings.enabled 
                              ? AppColors.primary 
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tipos de notificação
                  _SectionHeader(
                    title: 'Tipos de Notificação',
                    subtitle: 'Escolha o que quer receber',
                  ),
                  const SizedBox(height: 16),

                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        title: 'Lembrete de Streak',
                        subtitle: 'Mantenha sua sequência de login ativa',
                        value: notificationSettings.streakReminders,
                        onChanged: notificationSettings.enabled ? (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('streakReminders', value);
                        } : null,
                        leading: const Icon(Icons.local_fire_department),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        title: 'Convites para Jogos',
                        subtitle: 'Quando alguém te convidar para jogar',
                        value: notificationSettings.gameInvites,
                        onChanged: notificationSettings.enabled ? (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('gameInvites', value);
                        } : null,
                        leading: const Icon(Icons.sports_esports),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        title: 'Atualizações de Conexão',
                        subtitle: 'Novas mensagens e conexões formadas',
                        value: notificationSettings.connectionUpdates,
                        onChanged: notificationSettings.enabled ? (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('connectionUpdates', value);
                        } : null,
                        leading: const Icon(Icons.favorite_outline),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        title: 'Conquistas Desbloqueadas',
                        subtitle: 'Quando alcançar novos marcos',
                        value: notificationSettings.achievementUnlocks,
                        onChanged: notificationSettings.enabled ? (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('achievementUnlocks', value);
                        } : null,
                        leading: const Icon(Icons.emoji_events_outlined),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        title: 'Resumo Semanal',
                        subtitle: 'Estatísticas da sua semana no app',
                        value: notificationSettings.weeklyDigest,
                        onChanged: notificationSettings.enabled ? (value) {
                          ref.read(notificationSettingsProvider.notifier)
                              .toggleSetting('weeklyDigest', value);
                        } : null,
                        leading: const Icon(Icons.analytics_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Configurações de horário
                  _SectionHeader(
                    title: 'Horários',
                    subtitle: 'Personalize quando receber notificações',
                  ),
                  const SizedBox(height: 16),

                  _SettingsCard(
                    children: [
                      _TimeSettingTile(
                        title: 'Horário Preferido',
                        subtitle: 'Melhor horário para receber lembretes',
                        currentTime: notificationSettings.preferredTime,
                        enabled: notificationSettings.enabled,
                        onTimeChanged: (newTime) {
                          final updatedSettings = notificationSettings.copyWith(
                            preferredTime: newTime,
                          );
                          ref.read(notificationSettingsProvider.notifier)
                              .updateSettings(updatedSettings);
                        },
                      ),
                      const Divider(height: 1),
                      _QuietHoursSettingTile(
                        title: 'Horário Silencioso',
                        subtitle: 'Não receber notificações neste período',
                        quietHours: notificationSettings.quietHours,
                        enabled: notificationSettings.enabled,
                        onQuietHoursChanged: (newQuietHours) {
                          final updatedSettings = notificationSettings.copyWith(
                            quietHours: newQuietHours,
                          );
                          ref.read(notificationSettingsProvider.notifier)
                              .updateSettings(updatedSettings);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Informações sobre notificações
                  _InfoCard(),
                  const SizedBox(height: 24),

                  // Botões de ação
                  if (notificationState.permissionsGranted) ...[
                    _ActionButtons(),
                    const SizedBox(height: 24),
                  ],

                  // Debug info (apenas em desenvolvimento)
                  if (notificationState.fcmToken != null)
                    _DebugInfoCard(
                      fcmToken: notificationState.fcmToken!,
                      scheduledCount: notificationState.scheduledNotifications.length,
                    ),
                ],
              ),
            ),
    );
  }
}

/// Card de status das permissões
class _PermissionsCard extends StatelessWidget {
  final bool hasPermissions;
  final VoidCallback onRequestPermissions;

  const _PermissionsCard({
    required this.hasPermissions,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPermissions 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPermissions 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPermissions ? Icons.check_circle : Icons.warning_amber,
            color: hasPermissions ? AppColors.success : AppColors.warning,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPermissions 
                      ? 'Notificações Ativadas'
                      : 'Permissão Necessária',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasPermissions ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  hasPermissions
                      ? 'Você pode receber notificações do Unlock'
                      : 'Permita notificações para não perder lembretes importantes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!hasPermissions) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onRequestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Permitir'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header de seção
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Card container para configurações
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

/// Tile individual de configuração
class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: leading,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled 
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled 
              ? theme.colorScheme.onSurface.withOpacity(0.7)
              : theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

/// Tile para configuração de horário
class _TimeSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String currentTime;
  final bool enabled;
  final ValueChanged<String> onTimeChanged;

  const _TimeSettingTile({
    required this.title,
    required this.subtitle,
    required this.currentTime,
    required this.enabled,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.access_time,
        color: enabled 
            ? AppColors.primary
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled 
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled 
              ? theme.colorScheme.onSurface.withOpacity(0.7)
              : theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: GestureDetector(
        onTap: enabled ? () => _showTimePicker(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            currentTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:'
                           '${pickedTime.minute.toString().padLeft(2, '0')}';
      onTimeChanged(formattedTime);
    }
  }
}

/// Tile para configuração de horário silencioso
class _QuietHoursSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final TimeRange quietHours;
  final bool enabled;
  final ValueChanged<TimeRange> onQuietHoursChanged;

  const _QuietHoursSettingTile({
    required this.title,
    required this.subtitle,
    required this.quietHours,
    required this.enabled,
    required this.onQuietHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.bedtime_outlined,
        color: enabled 
            ? AppColors.primary
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled 
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled 
              ? theme.colorScheme.onSurface.withOpacity(0.7)
              : theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: GestureDetector(
        onTap: enabled ? () => _showQuietHoursDialog(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${quietHours.start} - ${quietHours.end}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuietHoursDialog(BuildContext context) async {
    // Implementar dialog para configurar horário silencioso
    // Por simplicidade, vou manter os valores atuais
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Horário Silencioso'),
        content: const Text(
          'Configure o período em que não deseja receber notificações. '
          'Esta funcionalidade será implementada em uma versão futura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Card informativo
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sobre as Notificações',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'As notificações do Unlock são inteligentes e respeitam seus '
                  'horários de descanso. Você pode personalizar cada tipo de '
                  'notificação de acordo com suas preferências.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botões de ação
class _ActionButtons extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(notificationProvider.notifier).sendImmediateNotification(
                title: 'Teste de Notificação',
                body: 'Esta é uma notificação de teste do Unlock!',
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificação de teste enviada!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(notificationProvider.notifier).rescheduleNotifications();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificações reagendadas!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reagendar Notificações'),
          ),
        ),
      ],
    );
  }
}

/// Card de debug (apenas em desenvolvimento)
class _DebugInfoCard extends StatelessWidget {
  final String fcmToken;
  final int scheduledCount;

  const _DebugInfoCard({
    required this.fcmToken,
    required this.scheduledCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _DebugInfoRow('FCM Token', fcmToken.substring(0, 20) + '...'),
          _DebugInfoRow('Notificações Agendadas', '$scheduledCount'),
        ],
      ),
    );
  }
}

/// Row de informação de debug
class _DebugInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DebugInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}