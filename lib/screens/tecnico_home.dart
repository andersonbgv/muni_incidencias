import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'incidencias_asignadas_screen.dart';
import 'areas_asignadas_screen.dart';
import 'historial_screen.dart';
import 'registrar_equipo_screen.dart';

class TecnicoHome extends StatefulWidget {
  const TecnicoHome({super.key});

  @override
  State<TecnicoHome> createState() => _TecnicoHomeState();
}

class _TecnicoHomeState extends State<TecnicoHome> {
  int _selectedIndex = 0;

  static const verdeBandera = Color(0xFF006400);

  final List<Widget> _screens = [
    const _HomeContent(),
    IncidenciasAsignadasScreen(),
    AreasAsignadasScreen(),
    HistorialScreen(),
  ];

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
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: verdeBandera,
        elevation: 3,
        title: const Text(
          'Panel del Técnico',
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

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_selectedIndex],
      ),

      bottomNavigationBar: _modernBottomBar(),
    );
  }

  Widget _modernBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: verdeBandera,
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: [
          _navItem("Inicio", Icons.home_filled),
          _navItem("Incidencias", FontAwesomeIcons.listCheck),
          _navItem("Áreas", FontAwesomeIcons.building),
          _navItem("Historial", FontAwesomeIcons.history),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(String label, IconData icon) {
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon, size: 22),
      ),
      activeIcon: AnimatedScale(
        scale: 1.2,
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 4),
            Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: verdeBandera,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}

// -----------------------------------------------------------------------------
// HOME CONTENT
// -----------------------------------------------------------------------------

class _HomeContent extends StatelessWidget {
  const _HomeContent({super.key});

  static const verdeBandera = Color(0xFF006400);

  @override
  Widget build(BuildContext context) {
    return Container(
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
            const Text(
              'Bienvenido Técnico',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: verdeBandera,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gestiona las incidencias asignadas desde aquí.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 25),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 1.08,
                children: [
                  _buildCard(
                    icon: FontAwesomeIcons.listCheck,
                    title: 'Incidencias Asignadas',
                    color: verdeBandera,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncidenciasAsignadasScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: FontAwesomeIcons.building,
                    title: 'Áreas Asignadas',
                    color: Colors.black87,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AreasAsignadasScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: FontAwesomeIcons.history,
                    title: 'Historial',
                    color: Colors.blue.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistorialScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    icon: FontAwesomeIcons.computer,
                    title: 'Registrar Equipo',
                    color: Colors.teal.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistrarEquipoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: color),
              const SizedBox(height: 14),
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
