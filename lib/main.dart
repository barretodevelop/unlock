import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/screens/splash_screen.dart'; // Adicionado para o fluxo de autenticação
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

  runApp(
    ProviderScope(child: const UnlockApp()),
  ); // Alterado para o novo Widget App
}

class UnlockApp extends StatelessWidget {
  // Renomeado de MainApp ou pode ser um novo Widget
  const UnlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Unlock App', // Defina o título do seu app
      home: SplashScreen(), // Define a SplashScreen como tela inicial
      // Considere definir um tema aqui: theme: ThemeData(...),
    );
  }
}
