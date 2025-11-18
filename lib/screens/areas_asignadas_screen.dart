import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AreasAsignadasScreen extends StatelessWidget {
  const AreasAsignadasScreen({super.key});

  /// 🔹 Obtener el nombre del técnico logueado
  Future<String?> obtenerNombreTecnico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('correo', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first['nombre'];
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Áreas Asignadas',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: obtenerNombreTecnico(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final nombreTecnico = snapshot.data;
          if (nombreTecnico == null) {
            return const Center(
              child: Text(
                'No se pudo identificar al técnico.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          // 🔹 Consultar áreas donde el técnico esté en la lista "responsables" o sea "responsable" (campo antiguo)
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('areas')
                .where(
                  Filter.or(
                    Filter('responsables', arrayContains: nombreTecnico),
                    Filter('responsable', isEqualTo: nombreTecnico),
                  ),
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No tienes áreas asignadas actualmente.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final areas = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  final area = areas[index].data() as Map<String, dynamic>;
                  final nombre = area['nombre'] ?? 'Sin nombre';
                  final fecha = area['fecha_registro'] != null
                      ? (area['fecha_registro'] as Timestamp)
                          .toDate()
                          .toString()
                          .split(' ')[0]
                      : 'Sin fecha';
                  final responsables = area.containsKey('responsables')
                      ? List<String>.from(area['responsables'])
                      : [area['responsable'] ?? 'No asignado'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.business, color: verdeBandera),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de registro: $fecha',
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Técnicos responsables: ${responsables.join(', ')}',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
