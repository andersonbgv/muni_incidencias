import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_home.dart';
import 'tecnico_home.dart';
import 'usuario_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animaciones mejoradas
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Retraso de 3 segundos para iniciar el proceso de verificación de sesión
    Timer(const Duration(seconds: 3), _verificarInicioSesion);
  }

  Future<void> _verificarInicioSesion() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _irA(const LoginScreen());
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      await FirebaseAuth.instance.signOut();
      _irA(const LoginScreen());
      return;
    }

    final rol = doc['rol'];
    if (rol == 'admin') {
      _irA(const AdminHome());
    } else if (rol == 'tecnico') {
      _irA(const TecnicoHome());
    } else {
      _irA(const UsuarioHome());
    }
  }

  void _irA(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40), // Color de fondo más atractivo
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/logo_reque.png',
                  width: 160, // Tamaño más grande para el logo
                  height: 160,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Municipalidad Distrital de Reque',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat', // Mantengo la fuente Montserrat
                    fontSize: 24, // Título más grande y atractivo
                    fontWeight: FontWeight.w600, // Peso de fuente moderado
                    color: Colors.white,
                    letterSpacing: 1.2, // Espaciado entre letras para mayor legibilidad
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  strokeWidth: 4, // Indicador de carga más grueso para visibilidad
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cargando...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                    fontSize: 16, // Mejor tamaño de fuente para el texto de carga
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
