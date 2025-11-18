import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AsignarTecnicosScreen extends StatefulWidget {
  const AsignarTecnicosScreen({super.key});

  @override
  State<AsignarTecnicosScreen> createState() => _AsignarTecnicosScreenState();
}

class _AsignarTecnicosScreenState extends State<AsignarTecnicosScreen> {
  String? tecnicoSeleccionado;
  Map<String, List<String>> mapaResponsables = {}; // área → lista de técnicos

  @override
  void initState() {
    super.initState();
    cargarResponsables();
  }

  /// 🔹 Cargar los responsables (lista) de cada área desde Firestore
  Future<void> cargarResponsables() async {
    final snapshot = await FirebaseFirestore.instance.collection('areas').get();

    setState(() {
      mapaResponsables = {
        for (var doc in snapshot.docs)
          doc['nombre']: doc.data().toString().contains('responsables')
              ? List<String>.from(doc['responsables'])
              : [doc['responsable'] ?? 'Sin técnico asignado']
      };
    });
  }

  /// 🔹 Asignar incidencia validando que el técnico sea responsable del área
  Future<void> asignarIncidencia(String idIncidencia, String areaIncidencia) async {
    if (tecnicoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un técnico antes de asignar')),
      );
      return;
    }

    final responsables = mapaResponsables[areaIncidencia] ?? [];

    if (responsables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ No hay técnicos responsables registrados para el área "$areaIncidencia".',
          ),
        ),
      );
      return;
    }

    if (!responsables.contains(tecnicoSeleccionado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ El técnico seleccionado no pertenece al área "$areaIncidencia".',
          ),
        ),
      );
      return;
    }

    try {
      final doc = FirebaseFirestore.instance.collection('incidencias').doc(idIncidencia);

      // ✅ Soporte para múltiples técnicos asignados (sin perder los previos)
      final snapshot = await doc.get();
      final data = snapshot.data() ?? {};
      List<String> tecnicosAsignados = [];

      if (data.containsKey('tecnicos_asignados')) {
        tecnicosAsignados = List<String>.from(data['tecnicos_asignados']);
      } else if (data.containsKey('tecnico_asignado')) {
        tecnicosAsignados = [data['tecnico_asignado']];
      }

      if (!tecnicosAsignados.contains(tecnicoSeleccionado)) {
        tecnicosAsignados.add(tecnicoSeleccionado!);
      }

      await doc.update({
        'tecnicos_asignados': tecnicosAsignados,
        'estado': 'En proceso',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Incidencia asignada a $tecnicoSeleccionado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al asignar incidencia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        title: const Text(
          'Asignar Técnicos a Incidencias',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Técnico:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            /// 🔹 Lista de técnicos (únicos) disponibles en TODAS las áreas
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'tecnico')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tecnicos = snapshot.data!.docs;

                if (tecnicos.isEmpty) {
                  return const Text(
                    'No hay técnicos registrados.',
                    style: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: tecnicoSeleccionado,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: 'Seleccione un técnico',
                  ),
                  items: tecnicos.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final correo = data['correo'] ?? '';
                    return DropdownMenuItem<String>(
                      value: nombre,
                      child: Text('$nombre ($correo)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => tecnicoSeleccionado = value);
                  },
                );
              },
            ),

            const SizedBox(height: 25),
            const Text(
              'Incidencias Pendientes:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            /// 🔹 Lista de incidencias pendientes
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('incidencias')
                    .where('estado', isEqualTo: 'Pendiente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay incidencias pendientes.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  final incidencias = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: incidencias.length,
                    itemBuilder: (context, index) {
                      final incidencia = incidencias[index].data() as Map<String, dynamic>;
                      final idIncidencia = incidencias[index].id;
                      final area = incidencia['area'] ?? 'Sin área';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.bug_report, color: verdeBandera),
                          title: Text(
                            incidencia['nombre_equipo'] ?? 'Equipo desconocido',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Área: $area\n${incidencia['descripcion'] ?? 'Sin descripción'}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => asignarIncidencia(idIncidencia, area),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: verdeBandera,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Asignar',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
