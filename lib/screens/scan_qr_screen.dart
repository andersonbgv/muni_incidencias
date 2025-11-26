import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registrar_incidencia_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;
  final MobileScannerController controller = MobileScannerController();
  late AnimationController _animationController;

  static const Color verdePrincipal = Color(0xFF006400);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _buscarEquipo(String idEquipo) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('equipos')
          .doc(idEquipo)
          .get();

      if (doc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrarIncidenciaScreen(
              equipoData: doc.data()!,
            ),
          ),
        );
      } else {
        _showSnack("⚠️ No se encontró un equipo con ese código QR");
        setState(() => _scanned = false);
      }
    } catch (e) {
      _showSnack("❌ Error al buscar equipo: $e");
      setState(() => _scanned = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🟢 AppBar profesional
      appBar: AppBar(
        backgroundColor: verdePrincipal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Escanear Código QR',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: Stack(
        children: [
          // 📷 Cámara
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

          // 🟩 Degradado amarillo-verde encima del video
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  verdePrincipal.withOpacity(0.55),
                  verdePrincipal.withOpacity(0.20),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🟩 Recuadro de escaneo animado
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final glow = 3 + (_animationController.value * 3);

                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white,
                      width: glow,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ✨ Esquinas estilo premium blanco
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _CornerPainter(color: Colors.white),
              ),
            ),
          ),

          // 📌 Texto guía
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Alinea el código QR dentro del recuadro",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black54,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔦 Botón linterna estilo verde pro
      floatingActionButton: FloatingActionButton(
        backgroundColor: verdePrincipal,
        elevation: 6,
        onPressed: () => controller.toggleTorch(),
        child: ValueListenableBuilder(
          valueListenable: controller.torchState,
          builder: (_, state, __) {
            return Icon(
              state == TorchState.on ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
              size: 28,
            );
          },
        ),
      ),
    );
  }
}

// 🎨 Esquinas profesionales
class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double length = 32;
    const double stroke = 5;

    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    // Top left
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), paint);

    // Top right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);

    // Bottom right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
