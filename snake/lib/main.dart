import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snake/leaderboard.dart';
import 'package:snake/login/auth.dart';
import 'package:snake/login/signup.dart';
import 'package:snake/login/login.dart';
import 'package:snake/settings.dart';
import 'package:snake/snake.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    
  runApp(const MainApp());
  });
}



class MainApp extends StatelessWidget  {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/username': (context) => const Login(),
        '/snake': (context) => const Snake(),
        '/signup': (context) => const Signup(),
        '/settings': (context) => const SnakeSettings(),
        '/leaderboard': (context) => const Leaderboard(score: 0, username: '',color: Colors.green),
      },
    );
  }
}
