import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Inicia sesión y devuelve el rol del usuario si es válido
  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userDoc = await _firestore
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['rol'];
      } else {
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ Error al iniciar sesión: ${e.code}');
      return null;
    }
  }

  /// 🔹 Valida si el correo y código existen y no han sido usados
  Future<Map<String, dynamic>?> validarCodigo(
      String correo, String codigo) async {
    final query = await _firestore
        .collection('usuarios_pendientes')
        .where('correo', isEqualTo: correo.trim())
        .where('codigo', isEqualTo: codigo.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    if (doc['registrado'] == true) return null;

    return {
      'docId': doc.id,
      'rol': doc['rol'],
      'correo': doc['correo'],
    };
  }

  /// 🔹 Registra al usuario en Firebase Auth y actualiza Firestore
  Future<void> registrarUsuario({
    required String docId,
    required String correo,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password.trim(),
      );

      // Actualiza el documento en usuarios_pendientes
      await _firestore.collection('usuarios_pendientes').doc(docId).update({
        'registrado': true,
        'nombre': nombre.trim(),
        'fechaRegistro': DateTime.now(),
      });

      // Crea el documento oficial en usuarios
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'correo': correo.trim(),
        'nombre': nombre.trim(),
        'rol': rol,
        'creadoEn': DateTime.now(),
      });
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ Error al registrar usuario: ${e.code}');
      rethrow;
    }
  }

/// 🔹 Cierra sesión y elimina el fcmToken del usuario
Future<void> signOut() async {
  final user = _auth.currentUser;

  if (user != null) {
    // 🧹 Borrar token FCM en Firestore
    await _firestore.collection('usuarios').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  await _auth.signOut();
}
}