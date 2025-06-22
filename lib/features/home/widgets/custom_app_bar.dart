// lib/features/home/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/features/home/widgets/settings_bottom_sheet.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/shared/widgets/avatar_circle.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(user?.displayName ?? 'Home'),
      leading: user != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: AvatarCircle(imageUrl: user.avatar, radius: 20),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configurações',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => const SettingsBottomSheet(),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
