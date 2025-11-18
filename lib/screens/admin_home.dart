import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'registrar_areas_screen.dart';
import 'infraestructura_ti_screen.dart';
import 'ver_incidencias_screen.dart';
import 'asignar_tecnicos_screen.dart';
import 'gestion_usuarios_screen.dart';
import 'reportes_mensuales_screen.dart';


class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

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
        backgroundColor: verdeBandera,
        elevation: 2,
        centerTitle: true, // ✅ Centra el título
        title: const Text(
          'Panel del Jefe de Informática',
          overflow: TextOverflow.ellipsis, // evita que se corte el texto
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 16, // tamaño ajustado para que entre completo
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Bienvenido Jefe de Informática',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: verdeBandera,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Administra las incidencias, técnicos y reportes del sistema.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 25),

              // 🧭 Cuadrícula de opciones
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.05,
                  children: [
                    _buildCard(
  icon: FontAwesomeIcons.list,
  title: 'Ver Incidencias',
  color: verdeBandera,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerIncidenciasScreen()),
    );
  },
),

                _buildCard(
  icon: FontAwesomeIcons.userGear,
  title: 'Asignar Técnicos',
  color: Colors.orange.shade800,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AsignarTecnicosScreen()),
    );
  },
),

                    _buildCard(
  icon: FontAwesomeIcons.chartPie,
  title: 'Reportes Mensuales',
  color: Colors.blue.shade800,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportesMensualesScreen()),
    );
  },
),
                   _buildCard(
  icon: FontAwesomeIcons.usersCog,
  title: 'Gestión de Usuarios',
  color: Colors.teal.shade700,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GestionUsuariosScreen()),
    );
  },
),
               _buildCard(
  icon: FontAwesomeIcons.bell,
  title: 'Registrar Áreas',
  color: Colors.deepPurple,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarAreasScreen()),
    );
  },
),_buildCard(
  icon: FontAwesomeIcons.server,
  title: 'Infraestructura TI',
  color: Colors.red.shade700,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InfraestructuraTIScreen()),
    );
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

  /// 🧱 Tarjeta reutilizable
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: color.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
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
      ),
    );
  }
}
