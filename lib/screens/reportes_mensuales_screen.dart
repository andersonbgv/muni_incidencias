import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReportesMensualesScreen extends StatefulWidget {
  const ReportesMensualesScreen({super.key});

  @override
  State<ReportesMensualesScreen> createState() =>
      _ReportesMensualesScreenState();
}

class _ReportesMensualesScreenState extends State<ReportesMensualesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _incidenciasConUsuario = [];
  List<Map<String, dynamic>> _filteredIncidencias = [];

  String? _selectedTecnico;
  String? _selectedArea;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasConUsuarios();
  }

  Future<void> _cargarIncidenciasConUsuarios() async {
    try {
      final QuerySnapshot snap =
          await _firestore.collection('incidencias').get();
      final incidencias =
          snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();

      setState(() {
        _incidenciasConUsuario = incidencias;
        _filteredIncidencias = List.from(incidencias);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al cargar incidencias: $e')),
      );
    }
  }

  void _filtrarIncidencias() {
    setState(() {
      _filteredIncidencias = _incidenciasConUsuario.where((inc) {
        bool coincideTecnico = true;
        bool coincideArea = true;
        bool coincideFecha = true;

        if (_selectedTecnico != null && _selectedTecnico != 'Todos') {
          final tecnicos = inc['tecnicos_asignados'] is List
              ? inc['tecnicos_asignados'] as List
              : [];
          coincideTecnico = tecnicos.contains(_selectedTecnico);
        }

        if (_selectedArea != null && _selectedArea != 'Todas') {
          coincideArea = inc['area'] == _selectedArea;
        }

        final fechaRaw = inc['fecha_reporte'];
        DateTime? fecha;
        if (fechaRaw is Timestamp) fecha = fechaRaw.toDate();
        if (fechaRaw is DateTime) fecha = fechaRaw;
        if (fecha != null) {
          if (_fechaInicio != null && fecha.isBefore(_fechaInicio!))
            coincideFecha = false;
          if (_fechaFin != null && fecha.isAfter(_fechaFin!))
            coincideFecha = false;
        }

        return coincideTecnico && coincideArea && coincideFecha;
      }).toList();
    });
  }

  List<String> _obtenerTecnicosUnicos() {
    final tecnicos = <String>{};
    for (final inc in _incidenciasConUsuario) {
      if (inc['tecnicos_asignados'] is List) {
        for (final t in inc['tecnicos_asignados']) {
          if (t is String) tecnicos.add(t);
        }
      }
    }
    return ['Todos', ...tecnicos.toList()..sort()];
  }

  List<String> _obtenerAreasUnicas() {
    final areas = <String>{};
    for (final inc in _incidenciasConUsuario) {
      if (inc['area'] is String) areas.add(inc['area']);
    }
    return ['Todas', ...areas.toList()..sort()];
  }

  Future<void> _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      initialDateRange: _fechaInicio != null && _fechaFin != null
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF006400)),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
      });
      _filtrarIncidencias();
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF006400);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: verde,
        title: const Text('Reportes Mensuales',
            style: TextStyle(fontFamily: 'Montserrat')),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportarAPdf,
              tooltip: 'Exportar a PDF'),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargarIncidenciasConUsuarios)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResumenCards(),
            const SizedBox(height: 10),
            _buildFiltros(),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredIncidencias.isEmpty
                  ? const Center(child: Text('No hay incidencias registradas.'))
                  : ListView.builder(
                      itemCount: _filteredIncidencias.length,
                      itemBuilder: (_, i) =>
                          _buildIncidenciaCard(_filteredIncidencias[i]),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCards() {
    final total = _filteredIncidencias.length;
    final resueltos = _filteredIncidencias
        .where((i) => (i['estado'] ?? '').toString().toLowerCase() == 'resuelto')
        .length;
    final proceso = _filteredIncidencias
        .where((i) => (i['estado'] ?? '').toString().toLowerCase().contains('proceso'))
        .length;
    final pendientes = total - resueltos - proceso;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _miniCard('Total', total, Colors.blue, FontAwesomeIcons.chartSimple),
        _miniCard('Resueltos', resueltos, Colors.green, FontAwesomeIcons.check),
        _miniCard('Pendientes', pendientes, Colors.orange, FontAwesomeIcons.clock),
      ],
    );
  }

  Widget _miniCard(String titulo, int valor, Color color, IconData icono) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, color: color, size: 26),
              const SizedBox(height: 6),
              Text('$valor',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color)),
              Text(titulo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(FontAwesomeIcons.filter, color: Color(0xFF006400), size: 18),
                SizedBox(width: 8),
                Text('Filtros activos',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedTecnico,
              decoration: const InputDecoration(
                labelText: 'Técnico',
                border: OutlineInputBorder(),
              ),
              items: _obtenerTecnicosUnicos()
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedTecnico = v);
                _filtrarIncidencias();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'Área',
                border: OutlineInputBorder(),
              ),
              items: _obtenerAreasUnicas()
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedArea = v);
                _filtrarIncidencias();
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_fechaInicio != null && _fechaFin != null
                  ? '${DateFormat('dd/MM/yy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yy').format(_fechaFin!)}'
                  : 'Seleccionar rango de fechas'),
              onPressed: _seleccionarRangoFechas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenciaCard(Map<String, dynamic> inc) {
    final area = inc['area'] ?? '—';
    final equipo = inc['nombre_equipo'] ?? '—';
    final estado = inc['estado'] ?? 'Pendiente';
    final descripcion = inc['descripcion'] ?? 'Sin descripción';
    final tecnicos = (inc['tecnicos_asignados'] as List?)?.join(', ') ?? '—';
    final fecha = _formatFecha(inc['fecha_reporte']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorEstado(estado).withOpacity(0.15),
          child: Icon(
            estado.toLowerCase() == 'resuelto'
                ? Icons.check_circle
                : Icons.build,
            color: _getColorEstado(estado),
          ),
        ),
        title: Text(equipo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Área: $area'),
            Text('Técnicos: $tecnicos'),
            Text('Descripción: $descripcion'),
            Text('Fecha: $fecha'),
          ],
        ),
        trailing: Chip(
          label: Text(estado),
          backgroundColor: _getColorEstado(estado),
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatFecha(dynamic f) {
    if (f is Timestamp) return DateFormat('dd/MM/yyyy HH:mm').format(f.toDate());
    if (f is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(f);
    return '—';
  }

  Color _getColorEstado(String e) {
    switch (e.toLowerCase()) {
      case 'resuelto':
        return Colors.green;
      case 'en proceso':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportarAPdf() async {
    if (_filteredIncidencias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay incidencias para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();
    final logoData = await rootBundle.load('assets/img/logo_reque.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Center(child: pw.Image(logo, height: 80)),
          pw.Text('Municipalidad Distrital de Reque',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Equipo', 'Área', 'Técnicos', 'Fecha', 'Estado'],
            data: _filteredIncidencias.map((i) {
              return [
                i['nombre_equipo'] ?? '—',
                i['area'] ?? '—',
                (i['tecnicos_asignados'] as List?)?.join(', ') ?? '—',
                _formatFecha(i['fecha_reporte']),
                i['estado'] ?? '—'
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
