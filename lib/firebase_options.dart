import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('❌ Este proyecto no tiene configuración para iOS aún.');
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError('❌ Firebase no está configurado para ${defaultTargetPlatform.name}.');
      default:
        throw UnsupportedError('❌ Plataforma no soportada para Firebase.');
    }
  }

  /// 🔥 Configuración Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQ1lqK8DwuL3fRkuxHScYwyP4sKA1-Jws',
    appId: '1:290097347317:android:0fc8f330daad16052d63bc',
    messagingSenderId: '290097347317',
    projectId: 'muni-5ec79',
    storageBucket: 'muni-5ec79.appspot.com',
  );

  /// 🌐 Configuración Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDN6ffRjygYRkvTYojMc76MF2RRn1-NY0Q',
    appId: '1:290097347317:web:8f5132843583865e2d63bc',
    messagingSenderId: '290097347317',
    projectId: 'muni-5ec79',
    storageBucket: 'muni-5ec79.appspot.com',
  );
}
