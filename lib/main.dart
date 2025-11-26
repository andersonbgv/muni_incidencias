// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_home.dart';
import 'screens/jefe_notificaciones_screen.dart'; // 👈 nueva
import 'services/notification_service.dart';
import 'screens/usuario_home.dart';
  
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      NotificationService().init();
    }
  });

  runApp(const MuniIncidenciasApp());
}

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
      // 👇 Añadimos las rutas necesarias
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/admin_home': (context) => const AdminHome(), // ✅ importante para navegación
        '/notificaciones': (context) => const JefeNotificacionesScreen(),
        '/usuario_home': (context) => const UsuarioHome(),
        // otras rutas...
      },
    );
  }
}