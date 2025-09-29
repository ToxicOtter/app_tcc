import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } 
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // Se quiser iOS depois, adicione aqui.
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDTiIEcfAowhotI6eoYfwhpaJg_DQGgrj4',
    appId: '1:1078474745423:web:745745dd5756b9b3546c3a',
    messagingSenderId: '1078474745423',
    projectId: 'tccc-3e7d6',
    authDomain: 'tccc-3e7d6.firebaseapp.com',
    storageBucket: 'tccc-3e7d6.firebasestorage.app',
    measurementId: 'G-0TZQCEZYM4',
  );

   static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTiIEcfAowhotI6eoYfwhpaJg_DQGgrj4',
    appId: '1:1078474745423:web:745745dd5756b9b3546c3a',
    messagingSenderId: '1078474745423',
    projectId: 'tccc-3e7d6',
    authDomain: 'tccc-3e7d6.firebaseapp.com',
    storageBucket: 'tccc-3e7d6.firebasestorage.app',
    measurementId: 'G-0TZQCEZYM4',
  );
}