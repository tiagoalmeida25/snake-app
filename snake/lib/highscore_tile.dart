import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class HighscoreTile extends StatelessWidget {
  final String documentId;
  final String? name;
  final int score;
  const HighscoreTile(
      {Key? key,
      required this.documentId,
      required this.name,
      required this.score})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    CollectionReference highscores =
        FirebaseFirestore.instance.collection("highscores");

    return FutureBuilder<DocumentSnapshot>(
      future: highscores.doc(documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: data["name"] == name
                    ? data["score"] == score
                        ? Colors.green[300]
                        : Colors.grey[300]
                    : Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data["name"],
                        style: TextStyle(
                            fontSize: 16,
                            color: data["name"] == name
                                ? Colors.black
                                : Colors.white),
                      ),
                      Text(
                        data["score"].toString(),
                        style: TextStyle(
                            fontSize: 16,
                            color: data["name"] == name
                                ? Colors.black
                                : Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return const Text("Loading...");
        }
      },
    );
  }
}
