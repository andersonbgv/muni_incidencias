import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarAreasScreen extends StatefulWidget {
  const RegistrarAreasScreen({super.key});

  @override
  State<RegistrarAreasScreen> createState() => _RegistrarAreasScreenState();
}

class _RegistrarAreasScreenState extends State<RegistrarAreasScreen> {
  final nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String? tecnicoSeleccionado;
  List<String> tecnicosDisponibles = [];

  @override
  void initState() {
    super.initState();
    cargarTecnicos();
  }

  Future<void> cargarTecnicos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'tecnico')
        .get();

    setState(() {
      tecnicosDisponibles =
          snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
    });
  }

  Future<void> registrarArea() async {
    if (!_formKey.currentState!.validate()) return;

    if (tecnicoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un técnico responsable')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('areas').add({
        'nombre': nombreController.text.trim(),
        'responsables': [tecnicoSeleccionado], // ✅ guardamos como lista
        'fecha_registro': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Área registrada correctamente')),
      );

      nombreController.clear();
      setState(() => tecnicoSeleccionado = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al registrar área: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // 🔹 Validar y eliminar un área solo si no tiene equipos registrados
  Future<void> eliminarArea(String id) async {
    try {
      final equiposSnapshot = await FirebaseFirestore.instance
          .collection('equipos')
          .where('id_area', isEqualTo: id)
          .get();

      if (equiposSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ No se puede eliminar esta área porque tiene equipos registrados.',
            ),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('areas').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Área eliminada correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al eliminar área: $e')),
      );
    }
  }

  // 🔹 Editar lista de responsables del área (agregar / eliminar)
  void editarResponsables(String areaId, List<dynamic> actuales) async {
    List<String> seleccionados = List<String>.from(actuales);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Editar técnicos responsables'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: tecnicosDisponibles.map((nombre) {
                final seleccionado = seleccionados.contains(nombre);
                return CheckboxListTile(
                  title: Text(nombre),
                  value: seleccionado,
                  onChanged: (checked) {
                    setModalState(() {
                      if (checked == true) {
                        seleccionados.add(nombre);
                      } else {
                        seleccionados.remove(nombre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('areas')
                      .doc(areaId)
                      .update({'responsables': seleccionados});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('✅ Responsables actualizados correctamente')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Registrar Áreas',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar nueva área',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: verdeBandera,
                ),
              ),
              const SizedBox(height: 15),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del área',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Ingrese el nombre del área' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: tecnicoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Técnico responsable',
                        border: OutlineInputBorder(),
                      ),
                      items: tecnicosDisponibles.map((nombre) {
                        return DropdownMenuItem<String>(
                          value: nombre,
                          child: Text(nombre,
                              style:
                                  const TextStyle(fontFamily: 'Montserrat')),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tecnicoSeleccionado = value;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Seleccione un técnico responsable'
                          : null,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : registrarArea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verdeBandera,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Registrar Área',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Áreas registradas',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: verdeBandera,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('areas')
                      .orderBy('fecha_registro', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay áreas registradas aún.',
                          style: TextStyle(
                              fontFamily: 'Montserrat', color: Colors.black54),
                        ),
                      );
                    }

                    final areas = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: areas.length,
                      itemBuilder: (context, index) {
                        final area = areas[index];
                      final responsables = area.data().toString().contains('responsables')
    ? List<String>.from(area['responsables'])
    : [area['responsable'] ?? 'Sin técnico asignado'];


                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading:
                                const Icon(Icons.business, color: verdeBandera),
                            title: Text(
                              area['nombre'],
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              responsables.isNotEmpty
                                  ? 'Responsables: ${responsables.join(', ')}'
                                  : 'Sin técnicos asignados',
                              style: const TextStyle(fontFamily: 'Montserrat'),
                            ),
                            trailing: Wrap(
                              spacing: 10,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  tooltip: 'Editar responsables',
                                  onPressed: () =>
                                      editarResponsables(area.id, responsables),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: 'Eliminar área',
                                  onPressed: () => eliminarArea(area.id),
                                ),
                              ],
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
      ),
    );
  }
}
