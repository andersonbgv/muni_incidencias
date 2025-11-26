import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 🔥 Inicialización global
  Future<void> init() async {
    // ⭐ Permiso obligatorio en Android 13+
    if (Platform.isAndroid) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    }

    // 🔔 Crear canal obligatorio Android
    await _createNotificationChannel();

    // 🎧 Listener foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 🎧 Listener cuando abres una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 🔧 Inicializar notificaciones locales
    await _configureLocalNotifications();

    // 🔄 Guardar token
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);
    _saveTokenToFirestore(await _fcm.getToken());
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification'); // 👈 icono correcto

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 🚨 CANAL OBLIGATORIO EN ANDROID 8+
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'incidencias_channel',
      'Incidencias Reque',
      description: 'Notificaciones de incidencias municipales',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 🔔 Mostrar notificación local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incidencias_channel',
      'Incidencias Reque',
      channelDescription: 'Notificaciones de incidencias municipales',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data ?? {}),
    );
  }

  /// 🟢 Mensaje cuando la app está abierta
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? "Nueva notificación";
    final body = message.notification?.body ?? "Tienes una actualización";

    await _showLocalNotification(
      title: title,
      body: body,
      data: message.data,
    );
  }

  /// 🟡 Cuando el usuario toca la notificación
  void _onMessageOpenedApp(RemoteMessage message) {
    _handleNavigation(message.data);
  }

  /// 🟣 Cuando la notificación local se toca
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload == null) return;
    final data = jsonDecode(response.payload!);
    _handleNavigation(Map<String, dynamic>.from(data));
  }

  /// 🧭 Manejar navegación (puedes personalizar)
  void _handleNavigation(Map<String, dynamic> data) {
    debugPrint("🔔 Notificación abierta → $data");
  }

  /// 💾 Guardar token en Firestore
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .update({'fcmToken': token});

    debugPrint("🔑 Token guardado: $token");
  }
}
