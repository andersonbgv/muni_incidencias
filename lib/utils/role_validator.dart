import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_home.dart';
import '../screens/tecnico_home.dart';
import '../screens/usuario_home.dart';

Future<bool> validateUserRole(
  BuildContext context, {
  required List<String> allowedRoles,
  bool redirectOnError = true,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (redirectOnError) {
      Navigator.pushReplacementNamed(context, '/');
    }
    return false;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      throw Exception('Documento de usuario no encontrado');
    }

    final rol = doc.data()?['rol'] as String?;

    if (rol == null || !allowedRoles.contains(rol)) {
      if (redirectOnError) {
        // Redirige al home correcto según rol real
        if (rol == 'jefe' || rol == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHome()),
          );
        } else if (rol == 'tecnico') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TecnicoHome()),
          );
        } else if (rol == 'usuario') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UsuarioHome()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Redirigido: no tienes acceso a esta sección'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    return true;
  } catch (e) {
    debugPrint('Error validando rol: $e');
    if (redirectOnError) {
      Navigator.pushReplacementNamed(context, '/');
    }
    return false;
  }
}