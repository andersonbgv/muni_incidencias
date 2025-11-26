const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notificarJefeNuevaIncidencia = functions.firestore
  .document("incidencias/{incidenciaId}")
  .onCreate(async (snap, context) => {
    const incidencia = snap.data();
    const incidenciaId = context.params.incidenciaId;

    console.log(`🔔 Nueva incidencia creada: ${incidenciaId}`);

    try {
      // 🔍 Obtener jefes
      const jefesSnapshot = await admin.firestore()
        .collection("usuarios")
        .where("rol", "==", "jefe")
        .get();

      if (jefesSnapshot.empty) {
        console.log("⚠️ No hay jefes registrados");
        return null;
      }

      // 🎯 Recolectar tokens
      const tokens = jefesSnapshot.docs
        .map(doc => doc.data().fcmToken)
        .filter(t => t && typeof t === "string" && t.length > 20);

      if (tokens.length === 0) {
        console.log("❌ Ningún jefe tiene token FCM válido");
        return null;
      }

      // 📦 Mensaje para envío múltiple
      const message = {
        tokens,

        notification: {
          title: "🆕 Nueva incidencia reportada",
          body: `Equipo: ${incidencia.nombre_equipo || '—'} (${incidencia.area || '—'})`,
        },

        data: {
          type: "nueva_incidencia",
          incidenciaId,
          equipoId: incidencia.id_equipo || "",
          reportante: incidencia.usuario_reportante_nombre || "Anónimo"
        },

        android: {
          priority: "high",
          ttl: 3600 * 1000,
          notification: {
            channelId: "incidencias_channel", // 👈 canal definido en Flutter
            sound: "default",
            visibility: "public",
            icon: "ic_notification", // 👈 ícono blanco obligatorio
          },
        },

        apns: {
          payload: {
            aps: {
              alert: {
                title: "🆕 Nueva incidencia reportada",
                body: `Equipo: ${incidencia.nombre_equipo || '—'}`,
              },
              sound: "default",
            },
          },
        },
      };

      // 🚀 Envío moderno
      const response = await admin.messaging().sendMulticast(message);

      console.log(`📤 Éxitos: ${response.successCount}, ❌ Fallos: ${response.failureCount}`);

      // 🧹 Eliminar tokens inválidos automáticamente
      if (response.failureCount > 0) {
        const batch = admin.firestore().batch();

        response.responses.forEach((resp, i) => {
          if (!resp.success) {
            const token = tokens[i];
            const errorCode = resp.error?.code || "desconocido";

            console.warn(`🗑 Eliminando token inválido (${errorCode}): ${token}`);

            const jefeDoc = jefesSnapshot.docs[i].ref;
            batch.update(jefeDoc, { fcmToken: admin.firestore.FieldValue.delete() });
          }
        });

        await batch.commit();
      }

      return null;

    } catch (error) {
      console.error("❌ Error en notificarJefeNuevaIncidencia:", error);
      return null;
    }
  });
