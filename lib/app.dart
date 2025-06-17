import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/config/app_theme.dart';
import 'package:unlock/config/updated_app_router.dart';
import 'package:unlock/providers/theme_provider.dart';

class UnlockApp extends ConsumerWidget {
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final router = ref.watch(AppRouterProvider);

    return MaterialApp.router(
      title: 'Unlock',
      theme: AppTheme.lightTheme, // <--- Tema claro
      darkTheme: AppTheme.darkTheme, // <--- Tema escuro
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      routerConfig: router,
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        return Stack(
          children: [
            child!,

            // ✅ Debug info no canto superior (apenas em debug mode)
            // if (kDebugMode) _buildDebugInfo(),
          ],
        );
      },
    );
  }
}
