import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

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

  String formatearFecha(Timestamp fecha) {
    final d = fecha.toDate();
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Historial de Incidencias',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: obtenerNombreTecnico(),
        builder: (context, tecnicoSnapshot) {
          if (tecnicoSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final nombreTecnico = tecnicoSnapshot.data;
          if (nombreTecnico == null) {
            return const Center(
              child: Text(
                'No se pudo identificar al técnico.',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
              ),
            );
          }

          // 🔹 Obtener incidencias resueltas del técnico
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('incidencias')
                .where(
                  Filter.or(
                    Filter('tecnico_asignado', isEqualTo: nombreTecnico),
                    Filter('tecnicos_asignados', arrayContains: nombreTecnico),
                  ),
                )
                .where('estado', isEqualTo: 'Resuelto')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No tienes incidencias resueltas aún.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final incidencias = snapshot.data!.docs;

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFE8F5E9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: incidencias.length,
                  itemBuilder: (context, index) {
                    final doc = incidencias[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final equipo = data['nombre_equipo'] ?? 'Equipo desconocido';
                    final descripcion = data['descripcion'] ?? 'Sin descripción';
                    final area = data['area'] ?? 'Sin área';
                    final fecha = data['fecha_reporte'] != null
                        ? formatearFecha(data['fecha_reporte'] as Timestamp)
                        : 'Sin fecha';

                    // 🔹 Extraer primera imagen de forma segura
                    final imagenesList = data['imagenes'];
                    String? urlImagen;
                    if (imagenesList is List && imagenesList.isNotEmpty) {
                      final first = imagenesList[0];
                      if (first is String) {
                        urlImagen = first.trim();
                      }
                    }

                    // Validar URL
                    bool isValidUrl(String? url) {
                      if (url == null || url.isEmpty) return false;
                      return Uri.tryParse(url)?.hasAbsolutePath == true;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: isValidUrl(urlImagen)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  urlImagen!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : const Icon(Icons.check_circle,
                                color: verdeBandera, size: 32),
                        title: Text(
                          equipo,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Área: $area',
                              style: const TextStyle(
                                  fontFamily: 'Montserrat', fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Descripción: $descripcion',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: $fecha',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(equipo),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isValidUrl(urlImagen))
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: SizedBox(
                                        width: MediaQuery.sizeOf(context).width *
                                            0.9,
                                        height: 150,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: Image.network(
                                              urlImagen!,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                  size: 60,
                                                  color: Colors.grey,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text('Área: $area'),
                                  Text('Descripción: $descripcion'),
                                  Text('Estado: Resuelto'),
                                  Text('Fecha: $fecha'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}