import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'completar_registro_screen.dart';

class ValidarOnboardingScreen extends StatefulWidget {
  const ValidarOnboardingScreen({super.key});

  @override
  State<ValidarOnboardingScreen> createState() => _ValidarOnboardingScreenState();
}

class _ValidarOnboardingScreenState extends State<ValidarOnboardingScreen> {
  final pageController = PageController();
  final correoController = TextEditingController();
  final codigoController = TextEditingController();

  bool loading = false;
  int page = 0;

  Future<void> _validar() async {
    final correo = correoController.text.trim();
    final codigo = codigoController.text.trim();

    if (correo.isEmpty || codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await AuthService().validarCodigo(correo, codigo);

      if (result == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Código o correo inválido.')));
        setState(() => loading = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompletarRegistroScreen(
            docId: result['docId'],
            correo: result['correo'],
            rol: result['rol'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF006400);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------- PROGRESS BAR --------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 5,
                    width: MediaQuery.of(context).size.width * (page == 0 ? .5 : 1),
                    decoration: BoxDecoration(
                      color: verde,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  // -------------------------- PAGE 1 – CORREO --------------------------------
                  _buildPage(
                    verde,
                    title: "Validar acceso institucional",
                    description:
                        "Ingresa tu correo institucional para continuar con la verificación.",
                    icon: FontAwesomeIcons.envelopeOpenText,
                    child: _emailInput(),
                    buttonText: "Siguiente",
                    onPressed: () => pageController.nextPage(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                    ),
                  ),

                  // -------------------------- PAGE 2 – CÓDIGO --------------------------------
                  _buildPage(
                    verde,
                    title: "Código de verificación",
                    description:
                        "Revisa tu bandeja de entrada. Ingresa el código enviado a tu correo.",
                    icon: FontAwesomeIcons.key,
                    child: _codeInput(),
                    buttonText: "Validar",
                    loading: loading,
                    onPressed: _validar,
                    showBack: true,
                    onBack: () => pageController.previousPage(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // ----------------------- COMPONENTE BASE DE CADA PAGE ----------------
  Widget _buildPage(
    Color verde, {
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
    required String buttonText,
    required VoidCallback onPressed,
    bool loading = false,
    bool showBack = false,
    VoidCallback? onBack,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // -------- ICONO PRINCIPAL --------
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: 1,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: verde.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: verde, size: 50),
            ),
          ),

          const SizedBox(height: 20),

          // -------- TITULO --------
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: verde,
            ),
          ),

          const SizedBox(height: 8),

          // -------- DESCRIPCIÓN --------
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 30),

          // -------- CARD PREMIUM --------
          Card(
            elevation: 10,
            shadowColor: verde.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: child,
            ),
          ),

          const SizedBox(height: 40),

          // -------- BOTONES --------
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                label: const Text("Atrás",
                    style: TextStyle(fontFamily: 'Montserrat')),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- INPUTS ----------------------
  Widget _emailInput() {
    const verde = Color(0xFF006400);

    return TextField(
      controller: correoController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: const Icon(FontAwesomeIcons.envelope, color: verde),
        labelText: "Correo institucional",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _codeInput() {
    const verde = Color(0xFF006400);

    return TextField(
      controller: codigoController,
      decoration: InputDecoration(
        prefixIcon: const Icon(FontAwesomeIcons.key, color: verde),
        labelText: "Código de verificación",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
