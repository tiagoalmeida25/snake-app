import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake/highscore_tile.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Leaderboard extends StatefulWidget {
  final String? username;
  final int? score;
  final Color? color;

  const Leaderboard({super.key, required this.username, required this.score, required this.color});

  @override
  LeaderboardState createState() => LeaderboardState();
}

class LeaderboardState extends State<Leaderboard> {
  String? username;
  int? score;

  @override
  void initState() {
    super.initState();
    setState(() {
      letsGetDocIds = getDocIds();
      username = widget.username;
      score = widget.score;
    });
  }

  late Future? letsGetDocIds;
  Map<String, int> highscores = {};
  Map<String, int> todayHighscores = {};
  Map<String, int> weeklyHighscores = {};
  Map<String, int> monthlyHighscores = {};
  Map<String, int> allHighscores = {};

  void refreshLeaderboard() {
    setState(() {
      letsGetDocIds = getDocIds();
    });
  }

  Future<void> getDocIds() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .get();

    Map<String, int> updatedHighscores = {};
    Map<String, int> updatedTodayHighscores = {};
    Map<String, int> updatedWeeklyHighscores = {};
    Map<String, int> updatedMonthlyHighscores = {};

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      String? user = data['name'];
      int? score = data['score'];

      if (user != null && score != null) {
        if (updatedHighscores.containsKey(user)) {
          if (updatedHighscores[user]! < score) {
            updatedHighscores[user] = score;
          }
        } else {
          updatedHighscores[user] = score;
        }
      }
    }

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      String? user = data['name'];
      int? score = data['score'];
      Timestamp? timestamp = data['date'];
      DateTime? date = timestamp?.toDate();

      if (user != null && score != null && date != null) {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime startOfWeek =
            today.subtract(Duration(days: today.weekday - 1));
        DateTime startOfMonth = DateTime(now.year, now.month, 1);

        if (date.isAfter(today)) {
          updateHighscore(updatedTodayHighscores, user, score);
        }

        if (date.isAfter(startOfWeek)) {
          updateHighscore(updatedWeeklyHighscores, user, score);
        }

        if (date.isAfter(startOfMonth)) {
          updateHighscore(updatedMonthlyHighscores, user, score);
        }

        updateHighscore(updatedHighscores, user, score);
      }
    }

    setState(() {
      highscores = updatedHighscores;
      todayHighscores = updatedTodayHighscores;
      weeklyHighscores = updatedWeeklyHighscores;
      monthlyHighscores = updatedMonthlyHighscores;
      allHighscores = updatedHighscores;
    });
  }

  void updateHighscore(Map<String, int> highscoresMap, String user, int score) {
    if (highscoresMap.containsKey(user)) {
      if (highscoresMap[user]! < score) {
        highscoresMap[user] = score;
      }
    } else {
      highscoresMap[user] = score;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    GNav(
                      rippleColor: const Color.fromRGBO(66, 66, 66, 1),
                      hoverColor: const Color.fromRGBO(97, 97, 97, 1),
                      haptic: true,
                      tabBorderRadius: 15,
                      tabActiveBorder:
                          Border.all(color: Colors.black, width: 1),
                      tabBorder: Border.all(color: Colors.grey, width: 1),
                      tabShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.5), blurRadius: 4)
                      ],
                      curve: Curves.easeInExpo,
                      duration: const Duration(milliseconds: 500),
                      gap: 4,
                      color: Colors.grey[800],
                      activeColor: widget.color,
                      iconSize: 24, 
                      tabBackgroundColor: widget.color
                          !.withOpacity(0.1), 
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5), 
                      tabs: const [
                        GButton(
                          icon: Icons.today,
                          text: 'Today',
                        ),
                        GButton(
                          icon: Icons.view_week_outlined,
                          text: 'Week',
                        ),
                        GButton(
                          icon: Icons.calendar_view_month,
                          text: 'Month',
                        ),
                        GButton(
                          icon: Icons.all_inclusive_outlined,
                          text: 'All',
                        ),
                      ],
                      selectedIndex: 3,
                      onTabChange: (index) {
                        setState(() {
                          if (index == 0) {
                            highscores = todayHighscores;
                          } else if (index == 1) {
                            highscores = weeklyHighscores;
                          } else if (index == 2) {
                            highscores = monthlyHighscores;
                          } else if (index == 3) {
                            highscores = allHighscores;
                          }
                        });
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder(
                          future: letsGetDocIds,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Column(
                                children: [
                                  for (var entry in highscores.entries)
                                    HighscoreTile(
                                      name: entry.key,
                                      highscore: entry.value,
                                      username: username,
                                      score: score,
                                      fontSize: 20,
                                    ),
                                ],
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 50),
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
        ));
  }
}
