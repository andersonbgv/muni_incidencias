import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class RegistrarEquipoScreen extends StatefulWidget {
  const RegistrarEquipoScreen({super.key});

  @override
  State<RegistrarEquipoScreen> createState() => _RegistrarEquipoScreenState();
}

class _RegistrarEquipoScreenState extends State<RegistrarEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final serieController = TextEditingController();
  final descripcionController = TextEditingController();

  String? areaSeleccionadaId;
  String? areaSeleccionadaNombre;
  bool loading = false;
  String? codigoGenerado;

  Future<void> registrarEquipo() async {
    if (!_formKey.currentState!.validate() || areaSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Selecciona un área antes de continuar')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final uuid = const Uuid();
      final idUnico = uuid.v4(); // 🔹 Genera ID único para el equipo

      final equipoData = {
        'id_equipo': idUnico,
        'nombre': nombreController.text.trim(),
        'numero_serie': serieController.text.trim(),
        'id_area': areaSeleccionadaId,
        'area_nombre': areaSeleccionadaNombre,
        'descripcion': descripcionController.text.trim(),
        'fecha_registro': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('equipos').doc(idUnico).set(equipoData);

      setState(() {
        codigoGenerado = idUnico;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Equipo registrado correctamente')),
      );

      nombreController.clear();
      serieController.clear();
      descripcionController.clear();
      setState(() {
        areaSeleccionadaId = null;
        areaSeleccionadaNombre = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al registrar equipo: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Registrar Equipo',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del Equipo',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: verdeBandera,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese el nombre del equipo' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: serieController,
                  decoration: const InputDecoration(
                    labelText: 'Número de serie',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese el número de serie' : null,
                ),
                const SizedBox(height: 15),

                // 🔽 Dropdown dinámico de áreas
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('areas').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        '⚠️ No hay áreas registradas. El jefe debe registrar una primero.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      );
                    }

                    final areas = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Área asignada',
                        border: OutlineInputBorder(),
                      ),
                      value: areaSeleccionadaId,
                      items: areas.map((area) {
                        return DropdownMenuItem<String>(
                          value: area.id,
                          child: Text(area['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          areaSeleccionadaId = value;
                          areaSeleccionadaNombre = areas
                              .firstWhere((a) => a.id == value)['nombre']
                              .toString();
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccione un área' : null,
                    );
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción o estado del equipo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : registrarEquipo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verdeBandera,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrar y generar QR',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 25),

                if (codigoGenerado != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Código QR del equipo:',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: verdeBandera,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: verdeBandera.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: codigoGenerado!,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Código único: $codigoGenerado',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
