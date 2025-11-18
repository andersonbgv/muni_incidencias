import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CompletarRegistroScreen extends StatefulWidget {
  final String docId;
  final String correo;
  final String rol;

  const CompletarRegistroScreen({
    super.key,
    required this.docId,
    required this.correo,
    required this.rol,
  });

  @override
  State<CompletarRegistroScreen> createState() =>
      _CompletarRegistroScreenState();
}

class _CompletarRegistroScreenState extends State<CompletarRegistroScreen>
    with SingleTickerProviderStateMixin {
  final nombreController = TextEditingController();
  final passController = TextEditingController();

  late AnimationController animController;
  late Animation<double> fadeAnim;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    fadeAnim = CurvedAnimation(
      parent: animController,
      curve: Curves.easeOut,
    );

    animController.forward();
  }

  Future<void> _registrar() async {
    final nombre = nombreController.text.trim();
    final pass = passController.text.trim();

    if (nombre.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService().registrarUsuario(
        docId: widget.docId,
        correo: widget.correo,
        password: pass,
        nombre: nombre,
        rol: widget.rol,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
        child: FadeTransition(
          opacity: fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ---------------- HEADER + ICON ----------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: verde.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.userPlus,
                    color: verde,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Completar registro",
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: verde,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Paso final · 2 / 2",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 25),

                // ---------------- ROL CARD ----------------
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: verde.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(FontAwesomeIcons.idBadge, color: verde, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Rol asignado: ${widget.rol.toUpperCase()}",
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            color: verde,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ---------------- FORM CARD ----------------
                Card(
                  elevation: 12,
                  shadowColor: verde.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    child: Column(
                      children: [
                        // ---------------- NOMBRE ----------------
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(FontAwesomeIcons.user, color: verde),
                            labelText: "Nombre completo",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ---------------- CONTRASEÑA ----------------
                        TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(FontAwesomeIcons.lock, color: verde),
                            labelText: "Crea una contraseña",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // ---------------- BUTTON ----------------
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : _registrar,
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
                                : const Text(
                                    "Finalizar registro",
                                    style: TextStyle(
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
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
