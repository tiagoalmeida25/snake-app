import 'package:flutter/material.dart';

class UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const UsernameField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color.fromRGBO(37, 42, 48, 1)),
            borderRadius: BorderRadius.circular(24),
          ),
          fillColor: Color.fromARGB(60, 255, 255, 255),
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
