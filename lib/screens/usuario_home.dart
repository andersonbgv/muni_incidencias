import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'scan_qr_screen.dart';
import 'mis_reportes_screen.dart';
class UsuarioHome extends StatelessWidget {
  const UsuarioHome({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: verdeBandera,
        elevation: 3,
        title: const Text(
          'Panel del Usuario',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Bienvenido al módulo de incidencias',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: verdeBandera,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona una opción para continuar',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 25),

              // Cuadrícula de opciones
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.1,
                  children: [
                    _buildCard(
  icon: FontAwesomeIcons.bug,
  title: 'Reportar Incidencia',
  color: verdeBandera,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
  },
),

                   _buildCard(
  icon: FontAwesomeIcons.clipboardList,
  title: 'Mis Reportes',
  color: Colors.teal.shade700,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisReportesScreen()),
    );
  },
),
                    _buildCard(
                      icon: FontAwesomeIcons.bell,
                      title: 'Notificaciones',
                      color: Colors.orange.shade800,
                      onTap: () {
                        // TODO: Ver alertas o actualizaciones
                      },
                    ),
                    _buildCard(
                      icon: FontAwesomeIcons.infoCircle,
                      title: 'Guía de Uso',
                      color: Colors.blue.shade700,
                      onTap: () {
                        // TODO: Mostrar guía rápida o tutorial
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧱 Tarjeta reutilizable para opciones del usuario
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: color.withOpacity(0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
