import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unlock/services/background_service.dart';
import 'package:unlock/services/notification_service.dart';

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INICIALIZAÇÃO CRÍTICA
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kDebugMode) {
      print('🚀 PetCare: Inicializando aplicação...');
    }

    await Firebase.initializeApp();
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
