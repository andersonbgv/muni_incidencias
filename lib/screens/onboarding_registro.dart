import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class OnboardingRegistro extends StatefulWidget {
  const OnboardingRegistro({super.key});

  @override
  State<OnboardingRegistro> createState() => _OnboardingRegistroState();
}

class _OnboardingRegistroState extends State<OnboardingRegistro>
    with TickerProviderStateMixin {
  final correoController = TextEditingController();
  final codigoController = TextEditingController();
  final nombreController = TextEditingController();
  final passController = TextEditingController();

  bool _obscurePassword = true;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _loading = false;

  String? _docId;
  String? _rol;

  // Colors
  static const Color primary = Color(0xFF0C6535);
  static const Color accent = Color(0xFF1AAA55);
  static const Color bg = Color(0xFFF4F8F4);

  // Animation controllers
  late AnimationController fadeCtrl;
  late Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnim = CurvedAnimation(
      parent: fadeCtrl,
      curve: Curves.easeInOut,
    );
    fadeCtrl.forward();
  }

  @override
  void dispose() {
    fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // FLECHA SUPERIOR IZQUIERDA
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primary,
                  size: 22,
                ),
                onPressed: () {
                  if (_currentPage == 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  } else {
                    setState(() => _currentPage--);
                  }
                },
              ),
            ),

            // indicador progreso
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 90,
              height: 6,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: (_currentPage + 1) * 30,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: primary,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _getSubtitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: "Montserrat",
                ),
              ),
            ),

            const SizedBox(height: 10),

            // CARD + ANIMATION
            Expanded(
              child: FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                      .animate(fadeCtrl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _buildCurrentForm(),
                    ),
                  ),
                ),
              ),
            ),

            // BOTON MÁS CERCA AL CARD
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
                top: 5,
              ),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == 2
                                  ? "Finalizar"
                                  : "Continuar",
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TEXTOS
  String _getTitle() {
    if (_currentPage == 0) return "Correo institucional";
    if (_currentPage == 1) return "Código de acceso";
    return "Crear cuenta";
  }

  String _getSubtitle() {
    if (_currentPage == 0) {
      return "Debes usar tu correo municipal con dominio oficial.";
    }
    if (_currentPage == 1) {
      return "Tu código empieza con USR- e identifica tu cuenta.";
    }
    return "Completa los últimos datos para activar tu cuenta.";
  }

  // FORMULARIOS
  Widget _buildCurrentForm() {
    fadeCtrl.forward(from: 0);
    if (_currentPage == 0) return _emailForm();
    if (_currentPage == 1) return _codeForm();
    return _registerForm();
  }

  Widget _emailForm() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Correo institucional"),
          const SizedBox(height: 6),
          TextFormField(
            controller: correoController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputStyle(
              icon: FontAwesomeIcons.envelope,
              hint: "usuario@reque.gob.pe",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return "Ingresa tu correo";
              if (!value.contains("@")) return "Correo inválido";
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _codeForm() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Código de verificación"),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "USR-",
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: codigoController,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle(
                    icon: FontAwesomeIcons.key,
                    hint: "123456",
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Ingresa tu código";
                    if (v.length != 6) return "Debe tener 6 dígitos";
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _formKey3,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(FontAwesomeIcons.userShield, color: primary),
                const SizedBox(width: 10),
                Text(
                  "Rol asignado: ${_rol ?? 'Usuario'}",
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("Nombre completo"),
          const SizedBox(height: 6),
          TextFormField(
            controller: nombreController,
            decoration: _inputStyle(
              icon: FontAwesomeIcons.user,
              hint: "Juan Pérez",
            ),
            validator: (v) => v!.isEmpty ? "Ingresa tu nombre" : null,
          ),

          const SizedBox(height: 20),

          const Text("Contraseña"),
          const SizedBox(height: 6),
          TextFormField(
            controller: passController,
            obscureText: _obscurePassword,
            decoration: _inputStyle(
              icon: FontAwesomeIcons.lock,
              hint: "••••••••",
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? FontAwesomeIcons.eye
                      : FontAwesomeIcons.eyeSlash,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (v) =>
                v!.length < 6 ? "Mínimo 6 caracteres" : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  // FLOW
  void _handleNext() {
    if (_currentPage == 0 && _formKey1.currentState!.validate()) {
      setState(() => _currentPage = 1);
    } else if (_currentPage == 1 && _formKey2.currentState!.validate()) {
      codigoController.text = "USR-${codigoController.text}";
      _validateCode();
    } else if (_currentPage == 2 && _formKey3.currentState!.validate()) {
      _completeRegistration();
    }
  }

  Future<void> _validateCode() async {
    setState(() => _loading = true);

    final result = await AuthService()
        .validarCodigo(correoController.text.trim(), codigoController.text);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código incorrecto")),
      );
      setState(() => _loading = false);
      return;
    }

    _docId = result['docId'];
    _rol = result['rol'];
    setState(() => _currentPage = 2);

    setState(() => _loading = false);
  }

  Future<void> _completeRegistration() async {
    setState(() => _loading = true);

    await AuthService().registrarUsuario(
      docId: _docId!,
      correo: correoController.text.trim(),
      password: passController.text.trim(),
      nombre: nombreController.text.trim(),
      rol: _rol!,
    );

    setState(() => _loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
