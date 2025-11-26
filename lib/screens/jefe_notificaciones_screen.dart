// lib/screens/jefe_notificaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class JefeNotificacionesScreen extends StatelessWidget {
  const JefeNotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Usa StreamBuilder de authStateChanges para reconstruir si el usuario cambia
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          // ✅ Redirige suavemente al login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/');
          });
          return const Scaffold(body: Center(child: Text('Cerrando sesión...')));
        }

        // ✅ Ahora sí puedes usar user.uid sin !
        return _NotificacionesContent(uid: user.uid);
      },
    );
  }
}

/// ✅ Separado en widget hijo para evitar reconstrucción innecesaria del Stream
class _NotificacionesContent extends StatelessWidget {
  final String uid;

  const _NotificacionesContent({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        title: const Text('Notificaciones'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            .doc(uid)
            .collection('inbox')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay notificaciones nuevas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final esNuevo = data['leido'] == false;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: esNuevo ? Colors.orangeAccent.withOpacity(0.2) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FontAwesomeIcons.circleExclamation,
                      color: esNuevo ? Colors.orange : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    data['titulo'],
                    style: TextStyle(
                      fontWeight: esNuevo ? FontWeight.bold : FontWeight.normal,
                      color: esNuevo ? Colors.black : Colors.grey[700],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['cuerpo']),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(data['timestamp']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () async {
                    await doc.reference.update({'leido': true});
                    // TODO: navegar al detalle si aplica
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0 && diff.inHours < 1) {
        return 'Hace ${diff.inMinutes} min';
      } else if (diff.inDays == 0) {
        return 'Hoy, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Ayer';
      } else {
        return '${date.day}/${date.month}';
      }
    }
    return '—';
  }
}