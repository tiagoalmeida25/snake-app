import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/components/password_textfield.dart';
import 'package:snake/components/username_textfield.dart';
import 'package:flutter/services.dart';
import 'package:snake/services/auth_service.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => SignupState();
}

class SignupState extends State<Signup> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void registerUser() async {
    UserCredential userCredential;
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    try {
      QuerySnapshot usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'Username already taken',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text);

      await FirebaseFirestore.instance
          .collection('user')
          .doc(userCredential.user?.uid)
          .set({
        'username': usernameController.text,
      });

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(
          msg: 'Email already in use',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.code == 'invalid-email') {
        Fluttertoast.showToast(
          msg: 'Invalid email',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.code == 'weak-password') {
        Fluttertoast.showToast(
          msg: 'Password is too weak',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: e.code,
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

    Fluttertoast.showToast(
      msg: "Sign-up successful!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color.fromARGB(255, 73, 244, 54),
      textColor: Colors.white,
      fontSize: 16.0,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text(
                  'snake',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  ' game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                  ),
                )
              ],
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Sign-up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              UsernameField(
                controller: emailController,
                hintText: 'Email',
              ),
              const SizedBox(height: 20),
              UsernameField(
                controller: usernameController,
                hintText: 'Username',
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: passwordController,
                hintText: 'Password',
              ),
            ],
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              children: [
                Expanded(
                  child: Divider(thickness: 0.5, color: Colors.grey[400]),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('Or continue with',
                      style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Divider(thickness: 0.5, color: Colors.grey[400]),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () => {AuthService().signInWithGoogle()},
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(50),
                color: const Color.fromARGB(62, 232, 232, 232),
              ),
              child: Image.asset(
                'lib/images/google.png',
                height: 30,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              registerUser();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              elevation: 5, // Shadow elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 10),
                Text(
                  'Register',
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
