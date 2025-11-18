import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestionUsuariosScreen extends StatelessWidget {
  const GestionUsuariosScreen({super.key});

  // 🔹 Eliminar usuario de Firestore Y de Firebase Auth
  Future<void> _eliminarUsuario(BuildContext context, String uid, String nombre) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar al usuario "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Eliminar documento de Firestore
        await db.collection('usuarios').doc(uid).delete();

        // 2. (Opcional) Eliminar de Firebase Authentication
        // Solo si tienes permisos (Cloud Function recomendado en producción)
        // await auth.currentUser?.delete(); // ⚠️ ¡No uses esto para otros usuarios!

        // 👉 En apps reales, la eliminación de Auth se hace usualmente desde un Cloud Function
        // Por ahora, solo eliminamos de Firestore.

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario "$nombre" eliminado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color verdeBandera = Color(0xFF006400);
    final String? uidJefeActual = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: verdeBandera,
        centerTitle: true,
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('rol', isNotEqualTo: 'jefe') // ⚠️ Solo técnicos y usuarios
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay técnicos ni usuarios para mostrar.',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
              ),
            );
          }

          final usuarios = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final doc = usuarios[index];
              final uid = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? 'Sin nombre';
              final correo = data['correo'] ?? 'Sin correo';
              final rol = (data['rol'] as String?)?.toLowerCase() ?? 'usuario';

              // 🔒 No mostrar al jefe actual (doble protección)
              if (uid == uidJefeActual) return const SizedBox();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rol == 'tecnico' ? Colors.orange.shade100 : Colors.grey.shade200,
                    child: Icon(
                      rol == 'tecnico' ? Icons.build : Icons.person,
                      color: rol == 'tecnico' ? Colors.orange.shade800 : Colors.grey.shade700,
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$correo • ${rol.toUpperCase()}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarUsuario(context, uid, nombre),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}