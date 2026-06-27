import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQtYhZGW_4w0bERLqj2E0URjdzYYTXfh4',
    appId: '1:165014085152:android:be15588d6a6e6c71a66645',
    messagingSenderId: '165014085152',
    projectId: 'movizius',
    storageBucket: 'movizius.firebasestorage.app',
  );
}
