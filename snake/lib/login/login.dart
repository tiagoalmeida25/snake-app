import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/components/password_textfield.dart';
import 'package:snake/components/username_textfield.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  void login() async {
    UserCredential userCredential;
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    try {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text);

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(
          msg: 'No user found for that email',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.code == 'wrong-password') {
        Fluttertoast.showToast(
          msg: 'Wrong password provided for that user',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      Navigator.pop(context);

      return;
    }

    String? username;

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userCredential.user?.uid)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        username = userData['username'];
      }
    }

    Fluttertoast.showToast(
      msg: "Welcome back,  ${username}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text(
            's n a k e game',
            style: TextStyle(
              color: Colors.white,
              fontSize: 45,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            children: [
              UsernameField(
                controller: emailController,
                hintText: 'Email',
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: passwordController,
                hintText: 'Password',
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'Create your account here!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              login();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              elevation: 5, // Shadow elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow),
                SizedBox(width: 10),
                Text(
                  'Play',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 10),
              ],
            ),
          )
        ],
      ),
    );
  }
}
