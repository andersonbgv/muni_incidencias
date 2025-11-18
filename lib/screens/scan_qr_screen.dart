import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registrar_incidencia_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _scanned = false;
  final MobileScannerController controller = MobileScannerController();

  Future<void> _buscarEquipo(String idEquipo) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('equipos').doc(idEquipo).get();
      if (doc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrarIncidenciaScreen(equipoData: doc.data()!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ No se encontró un equipo con ese código QR')),
        );
        setState(() => _scanned = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al buscar equipo: $e')),
      );
      setState(() => _scanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const verdeBandera = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanear código QR',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: verdeBandera,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                setState(() => _scanned = true);
                _buscarEquipo(barcode.rawValue!);
              }
            },
          ),
          Container(
            margin: const EdgeInsets.all(80),
            decoration: BoxDecoration(
              border: Border.all(color: verdeBandera, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Positioned(
            bottom: 30,
            child: Text(
              'Alinea el código QR dentro del recuadro',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
