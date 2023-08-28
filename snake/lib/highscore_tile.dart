import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class HighscoreTile extends StatelessWidget {
  final String? name;
  final int? highscore;
  final String? username;
  final int? score;

  const HighscoreTile({Key? key, required this.name, required this.highscore, required this.username, required this.score})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: name == username? score == highscore? Colors.green[300] : Colors.grey[300] : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name!,
                  style: TextStyle(fontSize: 16, color: name == username ? Colors.black : Colors.white),
                ),
                Text(
                  highscore.toString(),
                  style: TextStyle(fontSize: 16, color: name == username ? Colors.black : Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
