import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYBEKndyjipdqCRG_RUjRTElTteR52Joc',
    appId: '1:723224247669:android:e5e58b46b10ff1536f273c',
    messagingSenderId: '723224247669',
    projectId: 'fdp-backend-2ccd1',
    storageBucket: 'fdp-backend-2ccd1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuZV2gcExTXkbTl89nCLvjibKsdr-By8M',
    appId: '1:723224247669:ios:605cc6e7f64bad4c6f273c',
    messagingSenderId: '723224247669',
    projectId: 'fdp-backend-2ccd1',
    storageBucket: 'fdp-backend-2ccd1.firebasestorage.app',
    iosBundleId: 'com.example.fdp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDuZV2gcExTXkbTl89nCLvjibKsdr-By8M',
    appId: '1:723224247669:ios:605cc6e7f64bad4c6f273c',
    messagingSenderId: '723224247669',
    projectId: 'fdp-backend-2ccd1',
    storageBucket: 'fdp-backend-2ccd1.firebasestorage.app',
    iosBundleId: 'com.example.fdp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDuZV2gcExTXkbTl89nCLvjibKsdr-By8M',
    appId: '1:723224247669:web:605cc6e7f64bad4c6f273c',
    messagingSenderId: '723224247669',
    projectId: 'fdp-backend-2ccd1',
    storageBucket: 'fdp-backend-2ccd1.firebasestorage.app',
  );
}

