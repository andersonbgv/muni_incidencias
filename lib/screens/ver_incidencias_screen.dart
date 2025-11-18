import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerIncidenciasScreen extends StatefulWidget {
  const VerIncidenciasScreen({super.key});

  @override
  State<VerIncidenciasScreen> createState() => _VerIncidenciasScreenState();
}

class _VerIncidenciasScreenState extends State<VerIncidenciasScreen> {
  // Filtros seleccionados
  String? filtroArea;
  String? filtroEstado;
  String? filtroTecnico;

  // Lista de técnicos disponibles
  List<String> tecnicosDisponibles = [];

  // Estados predefinidos
  static const List<String> estados = ['Pendiente', 'En proceso', 'Resuelto'];
  // Áreas comunes (puedes ajustar según tu base)
  static const List<String> areas = [
    'informática',
    'mantenimiento',
    'redes',
    'soporte',
    'administración',
    'infraestructura',
  ];

  @override
  void initState() {
    super.initState();
    _cargarTecnicos();
  }

  Future<void> _cargarTecnicos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'tecnico')
          .get();

      final List<String> nombres = snapshot.docs
          .map((doc) => doc['nombre'] as String?)
          .whereType<String>()
          .toList();

      if (mounted) {
        setState(() {
          tecnicosDisponibles = nombres;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar técnicos: $e');
    }
  }

  void _limpiarFiltros() {
    setState(() {
      filtroArea = null;
      filtroEstado = null;
      filtroTecnico = null;
    });
  }

  bool _coincideConFiltros(Map<String, dynamic> incidencia) {
    final area = incidencia['area'] as String?;
    final estado = incidencia['estado'] as String?;

    // Obtener técnicos asignados (maneja ambos formatos)
    List<String> tecnicosAsignados = [];
    if (incidencia.containsKey('tecnicos_asignados') &&
        incidencia['tecnicos_asignados'] is List) {
      tecnicosAsignados = List<String>.from(incidencia['tecnicos_asignados'])
          .whereType<String>()
          .toList();
    } else if (incidencia.containsKey('tecnico_asignado') &&
        incidencia['tecnico_asignado'] is String) {
      tecnicosAsignados = [incidencia['tecnico_asignado']];
    }

    // Aplicar filtros
    if (filtroArea != null && area != filtroArea) return false;
    if (filtroEstado != null && estado != filtroEstado) return false;
    if (filtroTecnico != null && !tecnicosAsignados.contains(filtroTecnico)) {
      return false;
    }

    return true;
  }

  // ─── MÉTODOS AUXILIARES ─────────────────────────────────────────────────────

  String _formatearFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      final date = fecha.toDate();
      return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (fecha is DateTime) {
      return '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else {
      return 'Sin fecha';
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en proceso':
        return Colors.blue;
      case 'resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'en proceso':
        return Icons.autorenew;
      case 'resuelto':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        title: const Text(
          'Listado de Incidencias',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Limpiar filtros',
            onPressed: _limpiarFiltros,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── BARRA DE FILTROS ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              children: [
                // Filtro Área
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtroArea,
                    hint: const Text('Área'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las áreas'),
                      ),
                      ...areas.map(
                        (area) => DropdownMenuItem(
                          value: area,
                          child: Text(area.capitalize()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => filtroArea = value),
                    decoration: InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                // Filtro Estado
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtroEstado,
                    hint: const Text('Estado'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los estados'),
                      ),
                      ...estados.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => filtroEstado = value),
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                // Filtro Técnico
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtroTecnico,
                    hint: const Text('Técnico'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los técnicos'),
                      ),
                      ...tecnicosDisponibles.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => filtroTecnico = value),
                    decoration: InputDecoration(
                      labelText: 'Técnico',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ─── LISTA DE INCIDENCIAS ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidencias')
                  .orderBy('fecha_reporte', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay incidencias registradas.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                // Filtrar incidencias localmente
                final incidenciasFiltradas = snapshot.data!.docs
                    .where((doc) => doc.data() != null)
                    .map((doc) => doc.data()! as Map<String, dynamic>)
                    .where(_coincideConFiltros)
                    .toList();

                if (incidenciasFiltradas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron incidencias con los filtros aplicados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Forzar reload del stream (solo si usas offline persistence)
                    await FirebaseFirestore.instance
                        .collection('incidencias')
                        .get();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: incidenciasFiltradas.length,
                    itemBuilder: (context, index) {
                      final incidencia = incidenciasFiltradas[index];
                      final estado = incidencia['estado'] ?? 'Desconocido';
                      final colorEstado = _obtenerColorEstado(estado);
                      final iconoEstado = _obtenerIconoEstado(estado);
                      final areaNombre = incidencia['area'] ?? 'Sin área';

                      // Técnicos asignados (manejo flexible)
                      List<String> tecnicosAsignados = [];
                      if (incidencia.containsKey('tecnicos_asignados') &&
                          incidencia['tecnicos_asignados'] is List) {
                        tecnicosAsignados = List<String>.from(
                                incidencia['tecnicos_asignados'])
                            .whereType<String>()
                            .toList();
                      } else if (incidencia.containsKey('tecnico_asignado') &&
                          incidencia['tecnico_asignado'] is String) {
                        tecnicosAsignados = [incidencia['tecnico_asignado']];
                      }
                      final tecnicosAsignadosTexto =
                          tecnicosAsignados.isNotEmpty
                              ? tecnicosAsignados.join(', ')
                              : 'No asignado';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorEstado.withOpacity(0.2),
                            child: Icon(iconoEstado, color: colorEstado),
                          ),
                          title: Text(
                            incidencia['nombre_equipo'] ?? 'Equipo desconocido',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Área: $areaNombre',
                                style: const TextStyle(fontFamily: 'Montserrat'),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Técnicos: $tecnicosAsignadosTexto',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                incidencia['descripcion'] ?? 'Sin descripción',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Fecha: ${_formatearFecha(incidencia['fecha_reporte'])}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              estado,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: colorEstado,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            _mostrarDetalle(context, incidencia);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, Map<String, dynamic> incidencia) {
    final estado = incidencia['estado'] ?? 'Desconocido';
    final areaNombre = incidencia['area'] ?? 'Sin área';

    List<String> tecnicosAsignados = [];
    if (incidencia.containsKey('tecnicos_asignados') &&
        incidencia['tecnicos_asignados'] is List) {
      tecnicosAsignados = List<String>.from(incidencia['tecnicos_asignados'])
          .whereType<String>()
          .toList();
    } else if (incidencia.containsKey('tecnico_asignado') &&
        incidencia['tecnico_asignado'] is String) {
      tecnicosAsignados = [incidencia['tecnico_asignado']];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          incidencia['nombre_equipo'] ?? 'Detalle de incidencia',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Área: $areaNombre'),
              const SizedBox(height: 5),
              const Text(
                'Técnico(s) asignado(s):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 5),
              if (tecnicosAsignados.isNotEmpty)
                ...tecnicosAsignados.map((t) => Text('• $t')),
              if (tecnicosAsignados.isEmpty)
                const Text('No hay técnicos asignados.'),
              const SizedBox(height: 10),
              const Text(
                'Descripción:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(incidencia['descripcion'] ?? 'Sin descripción'),
              const SizedBox(height: 10),
              Text('Estado: $estado'),
              const SizedBox(height: 5),
              Text(
                'Fecha de reporte: ${_formatearFecha(incidencia['fecha_reporte'])}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Color(0xFF006400),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EXTENSIÓN PARA MAYÚSCULA INICIAL ───────────────────────────────────────
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}