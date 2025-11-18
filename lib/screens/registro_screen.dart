import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> registrar(Map<String, dynamic> args) async {
    try {
      setState(() => loading = true);
      final email = args['correo'];
      final docId = args['docId'];

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios_pendientes')
          .doc(docId)
          .update({
        'registrado': true,
        'nombre': nameController.text.trim(),
        'fechaRegistro': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro completado con éxito.')),
      );

      Navigator.popUntil(context, ModalRoute.withName('/login'));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final verdeBandera = const Color(0xFF006400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Column(
            children: [
              // Logo municipal
              Image.asset(
                'assets/img/logo_reque.png',
                height: 110,
              ),
              const SizedBox(height: 20),

              const Text(
                'Registro de usuario institucional',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Correo: ${args['correo']}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),

              // Card de formulario con diseño iOS
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
                shadowColor: verdeBandera.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Campo nombre
                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            FontAwesomeIcons.user,
                            color: verdeBandera,
                          ),
                          labelText: 'Nombre completo',
                          labelStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: verdeBandera, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: verdeBandera.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo contraseña
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            FontAwesomeIcons.lock,
                            color: verdeBandera,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              color: verdeBandera,
                            ),
                            onPressed: () =>
                                setState(() => obscure = !obscure),
                          ),
                          labelText: 'Crea una contraseña',
                          labelStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.black,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: verdeBandera, width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: verdeBandera.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Botón registrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : () => registrar(args),
                          icon: const Icon(FontAwesomeIcons.userCheck,
                              color: Colors.white),
                          label: Text(
                            loading ? 'Registrando...' : 'Registrar',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verdeBandera,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
