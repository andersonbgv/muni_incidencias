import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'ver_incidencias_screen.dart';
import 'asignar_tecnicos_screen.dart';
import 'reportes_mensuales_screen.dart';
import 'jefe_notificaciones_screen.dart';
import 'gestion_usuarios_screen.dart';
import 'infraestructura_ti_screen.dart';
import 'registrar_areas_screen.dart';
import '../utils/role_validator.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  String? _nombreJefe;
  bool _loadingNombre = true;

  final Color verdeBandera = const Color(0xFF006400);

  @override
  void initState() {
    super.initState();
     _validateAndLoad();
    _cargarNombreJefe();
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
 Future<void> _validateAndLoad() async {
    final isValid = await validateUserRole(
      context,
      allowedRoles: ['admin', 'jefe'],
    );
    if (isValid) {
      _cargarNombreJefe();
    }
    // Si no es válido, ya se redirigió
  }
  Future<void> _cargarNombreJefe() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _nombreJefe = "Jefe";
        _loadingNombre = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _nombreJefe = doc.data()?['nombre'] ?? "Jefe";
      } else {
        _nombreJefe = user.email?.split('@').first ?? "Jefe";
      }
    } catch (e, stack) {
      debugPrint("Error al cargar nombre del jefe: $e");
      _nombreJefe = "Jefe";
    }

    setState(() {
      _loadingNombre = false;
    });
  }

  // 🔹 Conteo de notificaciones no leídas (reutilizable)
  Future<int> _contarNotificacionesNoLeidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(uid)
        .collection('inbox')
        .where('leido', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5), // ✅ Coherencia total

      body: Column(
        children: [
          if (_currentIndex == 0) _buildHeaderCard(), // ✅ Solo en Inicio
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildPage(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildUltraProBottomMenu(),
    );
  }

  // ✅ Header card personalizada (igual que otros roles)
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 45, 16, 10),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFE8F5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hola, Jefe",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    _loadingNombre
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.grey),
                            ))
                        : Text(
                            _nombreJefe ?? "Jefe",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: verdeBandera,
                            ),
                          ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _cerrarSesion(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Bottom nav idéntica a Usuario/Técnico (coherencia UX multi-rol)
  Widget _buildUltraProBottomMenu() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: BottomNavigationBar(
          elevation: 12,
          currentIndex: _currentIndex,
          backgroundColor: Colors.white.withOpacity(0.90),
          selectedItemColor: verdeBandera,
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "Inicio",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              label: "Incidencias",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              label: "Técnicos",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: "Notificaciones",
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Páginas según índice (optimizadas para jefe)
  Widget _buildPage() {
    switch (_currentIndex) {
      case 1:
        return const VerIncidenciasScreen(); // ✅ Prioritario
      case 2:
        return const AsignarTecnicosScreen(); // ✅ Acceso rápido
      case 3:
        return const JefeNotificacionesScreen(); // ✅ Con badge en navbar
      default:
        return _buildHomeContent(); // ✅ Grid con el resto
    }
  }

  // ✅ Home content: mismo estilo, con badge en notificaciones y acceso a todas las funciones
  Widget _buildHomeContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Panel del Jefe de Informática",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006400),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Gestiona incidencias, técnicos, usuarios y recursos tecnológicos",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 25),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // ✅ Reemplaza "Ver Incidencias" → ya está en navbar
                // ✅ Reemplaza "Asignar Técnicos" → ya está en navbar
                // ✅ Reemplaza "Notificaciones" → ya está en navbar (con badge)

                _buildCard(
                  icon: FontAwesomeIcons.chartPie,
                  title: "Reportes\nMensuales",
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
                  title: "Gestión de\nUsuarios",
                  color: Colors.teal.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GestionUsuariosScreen()),
                    );
                  },
                ),
                _buildCard(
                  icon: FontAwesomeIcons.server,
                  title: "Infraestructura\nTI",
                  color: Colors.red.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InfraestructuraTIScreen()),
                    );
                  },
                ),
                _buildCard(
                  icon: FontAwesomeIcons.mapLocationDot,
                  title: "Registrar\nÁreas",
                  color: Colors.purple.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrarAreasScreen()),
                    );
                  },
                ),

                // ✅ Notificaciones con badge (aunque ya esté en navbar, redundancia útil)
                FutureBuilder<int>(
                  future: _contarNotificacionesNoLeidas(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildCardWithBadge(
                      icon: FontAwesomeIcons.bell,
                      title: "Notificaciones",
                      color: Colors.deepPurple,
                      badgeCount: count,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JefeNotificacionesScreen()),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Tarjeta estándar (reutilizada de Usuario/Técnico)
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Tarjeta con badge (notificaciones) — integrada al estilo unificado
  Widget _buildCardWithBadge({
    required IconData icon,
    required String title,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(icon, size: 42, color: color),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}