import 'package:flutter/material.dart';

class DetallesEquipoScreen extends StatelessWidget {
  final Map<String, dynamic> equipoData;

  const DetallesEquipoScreen({super.key, required this.equipoData});

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Detalles del Equipo',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipoData['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: verdeBandera,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Número de serie: ${equipoData['numero_serie'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Área: ${equipoData['area_nombre'] ?? 'Sin área'}'),
                const SizedBox(height: 8),
                Text('Descripción: ${equipoData['descripcion'] ?? 'Sin descripción'}'),
                const SizedBox(height: 8),
                Text('ID del equipo: ${equipoData['id_equipo']}'),
                const SizedBox(height: 20),
                Text(
                  'Registrado el: ${equipoData['fecha_registro'] != null ? equipoData['fecha_registro'].toDate().toString().split(".")[0] : 'Desconocido'}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.black54,
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
