// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0Z8zuZidCfcRIE2LBtzW5XGcBmnYAHdY',
    appId: '1:933418996723:web:0b464d6e93140dd2637886',
    messagingSenderId: '933418996723',
    projectId: 'snake-d0598',
    authDomain: 'snake-d0598.firebaseapp.com',
    storageBucket: 'snake-d0598.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4_TCxiOTV8wEiT-jt_IUBkBDSFetZyes',
    appId: '1:933418996723:android:7f5749916ff430d6637886',
    messagingSenderId: '933418996723',
    projectId: 'snake-d0598',
    storageBucket: 'snake-d0598.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDN1sgHbwAqLG3h_189zQ25u8orKR-han8',
    appId: '1:933418996723:ios:c457e0c82b3bb219637886',
    messagingSenderId: '933418996723',
    projectId: 'snake-d0598',
    storageBucket: 'snake-d0598.appspot.com',
    iosClientId: '933418996723-oip5sdis4k1ucqj3g4u096nns7kmrbbs.apps.googleusercontent.com',
    iosBundleId: 'com.example.snake',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDN1sgHbwAqLG3h_189zQ25u8orKR-han8',
    appId: '1:933418996723:ios:c457e0c82b3bb219637886',
    messagingSenderId: '933418996723',
    projectId: 'snake-d0598',
    storageBucket: 'snake-d0598.appspot.com',
    iosClientId: '933418996723-oip5sdis4k1ucqj3g4u096nns7kmrbbs.apps.googleusercontent.com',
    iosBundleId: 'com.example.snake',
  );
}
