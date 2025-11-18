import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'validar_codigo_screen.dart';
import 'admin_home.dart';
import 'tecnico_home.dart';
import 'usuario_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final pass = passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final rol = await AuthService().signIn(email, pass);

      if (rol == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no registrado o credenciales incorrectas.')),
        );
        setState(() => loading = false);
        return;
      }

      Widget destino;
      if (rol == 'admin' || rol == 'jefe') {
        destino = const AdminHome();
      } else if (rol == 'tecnico') {
        destino = const TecnicoHome();
      } else {
        destino = const UsuarioHome();
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF006400);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ======= Fondo superior con degradado =======
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A7A3F),
                  Color(0xFF006400),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ===== Logo centrado =====
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset('assets/img/logo_reque.png', width: 95),
                const SizedBox(height: 12),
                const Text(
                  "Municipalidad Distrital de Reque",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ======== Card blanca inferior ========
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.70,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TITULO =====
                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: verde,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Ingrese sus credenciales para continuar",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontFamily: "Montserrat",
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ======= INPUT Correo =======
                  _inputField(
                    label: "Correo institucional",
                    icon: FontAwesomeIcons.envelope,
                    controller: emailController,
                    isPassword: false,
                  ),

                  const SizedBox(height: 18),

                  // ======= INPUT Contraseña =======
                  _inputField(
                    label: "Contraseña",
                    icon: FontAwesomeIcons.lock,
                    controller: passController,
                    isPassword: true,
                  ),

                  const SizedBox(height: 26),

                  // ======= BOTÓN INICIAR SESIÓN =======
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF008C4A),
                            Color(0xFF006400),
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Iniciar Sesión",
                                style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ======= Olvidaste tu contraseña (con ícono) =======
                  Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(FontAwesomeIcons.circleQuestion, size: 16, color: verde),
                      label: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: verde,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ======= Registrar usuario (con ícono) =======
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ValidarOnboardingScreen()),
                        );
                      },
                      icon: const Icon(FontAwesomeIcons.userPlus, size: 16, color: verde),
                      label: const Text(
                        "Registrar nuevo usuario",
                        style: TextStyle(
                          color: verde,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= INPUT MODERNO =================
  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: "Montserrat",
          color: Colors.black54,
        ),
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
