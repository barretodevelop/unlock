// lib/features/settings/widgets/notification_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/settings/providers/settings_provider.dart';

/// Widget específico para configurações de notificação
class NotificationToggle extends ConsumerWidget {
  final bool showLabel;
  final bool isCompact;
  final VoidCallback? onChanged;

  const NotificationToggle({
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
      return _CompactNotificationToggle(
        isEnabled: settings.notificationsEnabled,
        onToggle: () => _toggleNotifications(ref),
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
          // Ícone de notificação
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: settings.notificationsEnabled
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              settings.notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: settings.notificationsEnabled ? Colors.green : Colors.grey,
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
                    'Notificações',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.notificationsEnabled
                        ? 'Receber notificações do app'
                        : 'Notificações desabilitadas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

          // Switch animado
          _AnimatedNotificationSwitch(
            value: settings.notificationsEnabled,
            onChanged: (value) {
              _toggleNotifications(ref);
              onChanged?.call();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleNotifications();
    } catch (e) {
      // Erro já é tratado no provider
    }
  }
}

/// Switch animado para notificações
class _AnimatedNotificationSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedNotificationSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value
              ? Colors.green
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                child: Icon(
                  Icons.notifications_off,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: value ? 1.0 : 0.0,
                child: Icon(
                  Icons.notifications_active,
                  size: 20,
                  color: Colors.white,
                ),
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
                  value ? Icons.notifications : Icons.notifications_off,
                  size: 14,
                  color: value ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versão compacta do toggle de notificação
class _CompactNotificationToggle extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const _CompactNotificationToggle({
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: isEnabled ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

/// Card completo de configurações de notificação
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

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
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Configurações de Notificação',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Toggle principal de notificações
          _NotificationOption(
            icon: Icons.notifications_active,
            title: 'Ativar Notificações',
            subtitle: 'Receber notificações do aplicativo',
            value: settings.notificationsEnabled,
            onChanged: (value) => _toggleNotifications(ref),
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          // Toggle de sons (apenas se notificações estão ativas)
          _NotificationOption(
            icon: Icons.volume_up,
            title: 'Sons de Notificação',
            subtitle: 'Reproduzir sons para notificações',
            value: settings.soundEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) => _toggleSound(ref)
                : null,
            color: Colors.blue,
            enabled: settings.notificationsEnabled,
          ),

          if (!settings.notificationsEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você não receberá notificações importantes como novas conexões e mensagens.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleNotifications();
    } catch (e) {
      // Erro tratado no provider
    }
  }

  Future<void> _toggleSound(WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).toggleSound();
    } catch (e) {
      // Erro tratado no provider
    }
  }
}

/// Opção individual de notificação
class _NotificationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color color;
  final bool enabled;

  const _NotificationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    required this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: enabled
                    ? color.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: enabled ? color : Colors.grey, size: 18),
            ),

            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? colorScheme.onSurface.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Switch
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de status de permissão de notificação
class NotificationPermissionStatus extends StatelessWidget {
  final bool hasPermission;
  final VoidCallback? onRequestPermission;

  const NotificationPermissionStatus({
    super.key,
    required this.hasPermission,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasPermission) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permissão de notificação concedida',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permissão de notificação negada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Para receber notificações, você precisa permitir nas configurações do sistema.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
          if (onRequestPermission != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Solicitar Permissão'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
