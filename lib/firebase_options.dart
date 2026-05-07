import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFXXsz-NLJUwsljRSv8VRckFHwOoS-quE',
    appId: '1:677865403099:android:058a8f518d67efbf0892fe',
    messagingSenderId: '677865403099',
    projectId: 'mkulima-pro-db',
    storageBucket: 'mkulima-pro-db.firebasestorage.app',
  );
}
