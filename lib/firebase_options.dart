import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'secrets.dart';

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
    apiKey: Secrets.apiKey,
    authDomain: Secrets.authDomain,
    projectId: Secrets.projectId,
    storageBucket: Secrets.storageBucket,
    messagingSenderId: Secrets.messagingSenderId,
    appId: Secrets.appId,
    measurementId: Secrets.measurementId,
  );

   static const FirebaseOptions android = FirebaseOptions(
    apiKey: Secrets.apiKey,
    authDomain: Secrets.authDomain,
    projectId: Secrets.projectId,
    storageBucket: Secrets.storageBucket,
    messagingSenderId: Secrets.messagingSenderId,
    appId: Secrets.appId,
    measurementId: Secrets.measurementId,
  );
}