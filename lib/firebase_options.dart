import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions só está configurado para Web no momento.',
      );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDijH0R0LvwF9yab9Blufu_VRpX73arYjo",
    authDomain: "teste-fa69f.firebaseapp.com",
    projectId: "teste-fa69f",
    storageBucket: "teste-fa69f.appspot.com",
    messagingSenderId: "660216194982",
    appId: "1:660216194982:web:f14edfebf233c665db5167",
    measurementId: "G-MR8N494E1V",
  );
}
