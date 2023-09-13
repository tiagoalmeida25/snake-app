import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/components/password_textfield.dart';
import 'package:snake/components/username_textfield.dart';
import 'package:flutter/services.dart';
import 'package:snake/services/auth_service.dart';

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
      msg: "Welcome back,  $username!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: Column(
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
                              children: [
                                Text(
                                  'Login',
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
                            width: screenWidth,
                            controller: emailController,
                            hintText: 'Email',
                          ),
                          const SizedBox(height: 20),
                          PasswordField(
                            width: screenWidth,
                            controller: passwordController,
                            hintText: 'Password',
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Create your account ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'here!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          login();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          elevation: 5, // Shadow elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 10),
                            Text(
                              'Play',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
