// lib/main.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_home.dart';
import 'screens/jefe_notificaciones_screen.dart';
import 'services/notification_service.dart'; // 👈 ya importado
import 'screens/usuario_home.dart';

// 👇 🔥 TOP-LEVEL: handler para background (¡obligatorio!)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();

    final localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    await localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final title = message.notification?.title ??
        message.data['title'] ??
        "Nueva incidencia";
    final body = message.notification?.body ??
        message.data['body'] ??
        "Revisa la lista de notificaciones";

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'incidencias_channel',
      'Incidencias Reque',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  } catch (e, stack) {
    print("❌ Background handler error: $e\n$stack");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await NotificationService().init();

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      FirebaseMessaging.instance.getToken().then((token) {
        if (token != null) {
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({'fcmToken': token});
        }
      });
    }
  });

  runApp(const MuniIncidenciasApp());
}

// ✅ DEFINE LA CLASE AQUÍ → ¡esto elimina el error!
class MuniIncidenciasApp extends StatelessWidget {
  const MuniIncidenciasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Incidencias Reque',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006400)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/admin_home': (context) => const AdminHome(),
        '/notificaciones': (context) => const JefeNotificacionesScreen(),
        '/usuario_home': (context) => const UsuarioHome(),
      },
    );
  }
}