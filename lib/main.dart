import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/config/app_router.dart';
import 'package:unlock/config/app_theme.dart';
import 'package:unlock/providers/theme_provider.dart';
import 'package:unlock/services/background_service.dart';
import 'package:unlock/services/notification_service.dart';

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // ✅ INICIALIZAÇÃO CRÍTICA
  WidgetsFlutterBinding.ensureInitialized(); // Apenas uma chamada no início é necessária

  try {
    if (kDebugMode) {
      print('🚀 PetCare: Inicializando aplicação...');
    }
    // É recomendado usar options para garantir a configuração correta da plataforma.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('✅ Firebase inicializado');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      print('✅ FCM background handler configurado');
    }

    await NotificationService.initialize();
    if (kDebugMode) {
      print('✅ NotificationService inicializado');
    }

    await BackgroundService.initialize();
    if (kDebugMode) {
      print('✅ BackgroundService inicializado');
    }

    if (kDebugMode) {
      print('🎉 Unlock: Inicialização completa!');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erro na inicialização: $e');
    }
    // App pode continuar mesmo com erro nos background services
  }

  // A inicialização do Firebase com options já foi feita no bloco try/catch.
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  // final iosInit = DarwinInitializationSettings(
  //   requestSoundPermission: true,
  //   requestBadgePermission: true,
  //   requestAlertPermission: true,
  // );

  const initSettings = InitializationSettings(android: androidInit);

  await notificationsPlugin.initialize(
    initSettings,
    // definir callback se quiser lidar com clique:
    onDidReceiveNotificationResponse: (NotificationResponse resp) {
      // ação ao clicar
    },
  );

  // Configurar sistema
  await _configureApp();

  runApp(
    ProviderScope(child: const UnlockApp()),
  ); // Alterado para o novo Widget App
}

/// Configurações iniciais do app
Future<void> _configureApp() async {
  // Configurar orientação (apenas portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Configurar debug (desabilitar banners em produção)
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

class UnlockApp extends ConsumerWidget {
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PetCare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      routerConfig: router,
      debugShowCheckedModeBanner: false,

      // ✅ NOVO: Builder para debug de background service
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
