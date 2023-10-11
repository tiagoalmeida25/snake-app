import "package:flutter/material.dart";

class HighscoreTile extends StatelessWidget {
  final String? name;
  final int? highscore;
  final String? username;
  final int? score;
  final double fontSize;
  final String? rank;

  const HighscoreTile(
      {Key? key,
      required this.name,
      required this.highscore,
      required this.username,
      required this.score,
      this.rank = '',
      this.fontSize = 16})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: name == username
              ? score == highscore
                  ? Colors.green[300]
                  : Colors.grey[300]
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: rank! == '1' ? Colors.amber : rank! == '2' ? Colors.grey : rank! == '3' ? Colors.brown : Colors.grey,
                        height: 24,
                        width: 24,
                        child: Center(
                          child: Text(rank!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontSize,
                                color: name == username
                                    ? Colors.black
                                    : Colors.white,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name!,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: name == username ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  highscore.toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    color: name == username ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
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
