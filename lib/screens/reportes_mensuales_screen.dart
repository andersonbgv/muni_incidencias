import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  String? _selectedTecnico = 'Todos';
  String? _selectedArea = 'Todas';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasConUsuarios();
  }

  Future<void> _cargarIncidenciasConUsuarios() async {
    try {
      final snapshot = await _firestore.collection('incidencias').get();
      final data = snapshot.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

      setState(() {
        _incidenciasConUsuario = data;
        _filteredIncidencias = List.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al cargar datos: $e")),
      );
    }
  }

  // ------------------------------
  // FILTROS
  // ------------------------------
  void _filtrarIncidencias() {
    setState(() {
      _filteredIncidencias = _incidenciasConUsuario.where((inc) {
        bool matchTecnico = true;
        bool matchArea = true;
        bool matchFecha = true;

        // Técnico
        if (_selectedTecnico != null && _selectedTecnico != 'Todos') {
          final lista = inc['tecnicos_asignados'] ?? [];
          matchTecnico = lista.contains(_selectedTecnico);
        }

        // Área
        if (_selectedArea != null && _selectedArea != 'Todas') {
          matchArea = inc['area'] == _selectedArea;
        }

        // Fecha
        DateTime? fecha;
        if (inc['fecha_reporte'] is Timestamp) {
          fecha = (inc['fecha_reporte'] as Timestamp).toDate();
        }
        if (fecha != null) {
          if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) {
            matchFecha = false;
          }
          if (_fechaFin != null && fecha.isAfter(_fechaFin!)) {
            matchFecha = false;
          }
        }

        return matchTecnico && matchArea && matchFecha;
      }).toList();
    });
  }

  List<String> _obtenerTecnicosUnicos() {
    final set = <String>{};
    for (final inc in _incidenciasConUsuario) {
      if (inc['tecnicos_asignados'] is List) {
        for (final t in inc['tecnicos_asignados']) {
          set.add(t);
        }
      }
    }
    return ['Todos', ...set.toList()..sort()];
  }

  List<String> _obtenerAreasUnicas() {
    final set = <String>{};
    for (final inc in _incidenciasConUsuario) {
      if (inc['area'] != null) set.add(inc['area']);
    }
    return ['Todas', ...set.toList()..sort()];
  }

  Future<void> _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: const Color(0xFF006400)),
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

  // ---------------------------------------------------
  // UI PRINCIPAL
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF006400);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        backgroundColor: verde,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reportes Mensuales",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16, 
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _exportarAPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarIncidenciasConUsuarios,
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildDashboard(),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildFiltrosPanel(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildListaIncidencias()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // DASHBOARD CARDS
  // -----------------------------------------------
  Widget _buildDashboard() {
    final total = _filteredIncidencias.length;
    final resueltos = _filteredIncidencias
        .where((i) => (i['estado'] ?? '').toString().toLowerCase() == "resuelto")
        .length;

    final proceso = _filteredIncidencias
        .where((i) =>
            (i['estado'] ?? '').toString().toLowerCase().contains("proceso"))
        .length;

    final pendientes = total - resueltos - proceso;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _metricCard("Total", total, Colors.blue),
          _metricCard("Resueltos", resueltos, Colors.green),
          _metricCard("Pendientes", pendientes, Colors.orange),
        ],
      ),
    );
  }

  Widget _metricCard(String titulo, int valor, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.chartSimple, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              "$valor",
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // PANEL DE FILTROS
  // ------------------------------------------------
  Widget _buildFiltrosPanel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(FontAwesomeIcons.filter, size: 18, color: Color(0xFF006400)),
                SizedBox(width: 8),
                Text(
                  "Filtros",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Montserrat",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Técnico
            DropdownButtonFormField<String>(
              value: _selectedTecnico,
              decoration: const InputDecoration(
                labelText: "Técnico",
                border: OutlineInputBorder(),
              ),
              items: _obtenerTecnicosUnicos()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                _selectedTecnico = v;
                _filtrarIncidencias();
              },
            ),

            const SizedBox(height: 12),

            // Área
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: const InputDecoration(
                labelText: "Área",
                border: OutlineInputBorder(),
              ),
              items: _obtenerAreasUnicas()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                _selectedArea = v;
                _filtrarIncidencias();
              },
            ),

            const SizedBox(height: 12),

            // FECHAS
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                _fechaInicio != null && _fechaFin != null
                    ? "${DateFormat('dd/MM/yy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yy').format(_fechaFin!)}"
                    : "Seleccionar rango de fechas",
              ),
              onPressed: _seleccionarRangoFechas,
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------
  // LISTA DE INCIDENCIAS
  // -----------------------------------------------
  Widget _buildListaIncidencias() {
    if (_filteredIncidencias.isEmpty) {
      return const Center(
        child: Text(
          "No hay incidencias.",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredIncidencias.length,
      itemBuilder: (_, i) {
        return _incidenciaCard(_filteredIncidencias[i]);
      },
    );
  }

  Widget _incidenciaCard(Map<String, dynamic> inc) {
    final estado = inc['estado'] ?? 'Pendiente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _getColorEstado(estado).withOpacity(0.15),
                  child: Icon(
                    estado.toLowerCase() == 'resuelto'
                        ? Icons.check_circle
                        : Icons.build,
                    color: _getColorEstado(estado),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    inc['nombre_equipo'] ?? "Equipo",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    estado,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getColorEstado(estado),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _infoRow("Área", inc['area']),
            _infoRow("Técnicos", (inc['tecnicos_asignados'] as List?)?.join(", ")),
            _infoRow("Descripción", inc['descripcion']),
            _infoRow(
                "Fecha", _formatFecha(inc['fecha_reporte'])),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String titulo, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$titulo: ${valor ?? '—'}",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Color _getColorEstado(String e) {
    switch (e.toLowerCase()) {
      case "resuelto":
        return Colors.green;
      case "en proceso":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha(dynamic f) {
    if (f is Timestamp) return DateFormat("dd/MM/yyyy HH:mm").format(f.toDate());
    if (f is DateTime) return DateFormat("dd/MM/yyyy HH:mm").format(f);
    return "—";
  }

  // ---------------------------------------------------
  // PDF EXPORT
  // ---------------------------------------------------
  Future<void> _exportarAPdf() async {
    if (_filteredIncidencias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No hay datos para exportar.")),
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
          pw.SizedBox(height: 10),
          pw.Text(
            "Municipalidad Distrital de Reque",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Table.fromTextArray(
            headers: ["Equipo", "Área", "Técnicos", "Fecha", "Estado"],
            data: _filteredIncidencias.map((i) {
              return [
                i['nombre_equipo'] ?? "—",
                i['area'] ?? "—",
                (i['tecnicos_asignados'] as List?)?.join(", ") ?? "—",
                _formatFecha(i['fecha_reporte']),
                i['estado'] ?? "—",
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File("${dir.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.pdf");

    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
