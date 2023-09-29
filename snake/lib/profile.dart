import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/components/highscore_tile.dart';

class Profile extends StatefulWidget {
  final String? username;
  final Color? color;

  const Profile({super.key, required this.username, required this.color});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController usernameController = TextEditingController();
  Map<String, Map<String, dynamic>> highscores = {};
  List<Map<String, Map<String, dynamic>>> userScores = [];
  int totalGames = 0;
  int daysPlayed = 0;
  int totalScore = 0;
  int days = 0;
  int weeks = 0;
  int months = 0;
  double averagePosition = 0;
  int leaderboardSize = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      getUserScores();
      getMedals();
    });
  }

  void changeUsername(String? newUsername) async {
    var user = FirebaseAuth.instance.currentUser;

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('user').get();

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      String? username = data['username'];

      if (username == newUsername) {
        Fluttertoast.showToast(
          msg: 'Username already exists',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
    }

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
      'username': newUsername,
    }).then((value) {
      setState(() {
        usernameController.text = '';
      });
    });

    QuerySnapshot scoresSnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .where('name', isEqualTo: widget.username)
        .get();

    for (var doc in scoresSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(doc.id)
          .update({
        'name': newUsername,
      });
    }

    Fluttertoast.showToast(
      msg: 'Username changed',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> getUserScores() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('date', descending: true)
        .get();

    List<Map<String, Map<String, dynamic>>> updatedUserScores = [];

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      Map<String, Map<String, dynamic>> newEntry = {};

      String? user = data['name'];
      int? score = data['score'];
      Timestamp? time = data['date'];
      DateTime? date = time?.toDate();

      if (user != null && score != null && date != null) {
        if (user == widget.username) {
          newEntry[user] = {
            'score': score,
            'date': date,
          };
          updatedUserScores.add(newEntry);
        }
      }

      setState(() {
        userScores = updatedUserScores;
      });
    }
  }

  Map<DateTime, Map<String, dynamic>> findBestScorePerDay(
      scoresSnapshot, bool countScore) {
    Map<DateTime, Map<String, dynamic>> highestScoresByDay = {};

    for (var doc in scoresSnapshot.docs) {
      var scoreData = doc.data();
      int score = scoreData['score'];
      var player = scoreData['name'];
      var date = scoreData['date'].toDate();
      var day = DateTime(date.year, date.month, date.day);

      if (countScore) {
        setState(() {
          totalScore += score;
        });
      }

      if (!highestScoresByDay.containsKey(day)) {
        highestScoresByDay[day] = {'score': score, 'user': player};
      } else {
        if (score > highestScoresByDay[day]?['score']) {
          highestScoresByDay[day]?['score'] = score;
          highestScoresByDay[day]?['user'] = player;
        }
      }
    }
    return highestScoresByDay;
  }

  Map<DateTime, Map<String, dynamic>> findBestScorePerWeek(scoresSnapshot) {
    Map<DateTime, Map<String, dynamic>> highestScoresByWeek = {};

    for (var doc in scoresSnapshot.docs) {
      var scoreData = doc.data();
      int score = scoreData['score'];
      var player = scoreData['name'];
      var date = scoreData['date'].toDate();
      var week = DateTime.utc(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));

      if (!highestScoresByWeek.containsKey(week)) {
        highestScoresByWeek[week] = {'score': score, 'user': player};
      } else {
        if (score > highestScoresByWeek[week]?['score']) {
          highestScoresByWeek[week]?['score'] = score;
          highestScoresByWeek[week]?['user'] = player;
        }
      }
    }

    return highestScoresByWeek;
  }

  Map<DateTime, Map<String, dynamic>> findBestScorePerMonth(scoresSnapshot) {
    Map<DateTime, Map<String, dynamic>> highestScoresByMonth = {};

    for (var doc in scoresSnapshot.docs) {
      var scoreData = doc.data();
      int score = scoreData['score'];
      var player = scoreData['name'];
      var date = scoreData['date'].toDate();
      var month = DateTime(date.year, date.month);

      if (!highestScoresByMonth.containsKey(month)) {
        highestScoresByMonth[month] = {'score': score, 'user': player};
      } else {
        if (score > highestScoresByMonth[month]?['score']) {
          highestScoresByMonth[month]?['score'] = score;
          highestScoresByMonth[month]?['user'] = player;
        }
      }
    }

    return highestScoresByMonth;
  }

  Future<void> getMedals() async {
    Map<DateTime, Map<String, dynamic>> userBestScoresPerDay = {};
    Map<DateTime, Map<String, dynamic>> bestScoresPerDay = {};
    Map<DateTime, Map<String, dynamic>> userBestScoresPerWeek = {};
    Map<DateTime, Map<String, dynamic>> bestScoresPerWeek = {};
    Map<DateTime, Map<String, dynamic>> userBestScoresPerMonth = {};
    Map<DateTime, Map<String, dynamic>> bestScoresPerMonth = {};

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    var scoresSnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .where('name', isEqualTo: widget.username)
        .get();

    var allScoresSnapshot =
        await FirebaseFirestore.instance.collection('leaderboard').get();

    userBestScoresPerDay = findBestScorePerDay(scoresSnapshot, true);
    bestScoresPerDay = findBestScorePerDay(allScoresSnapshot, false);

    for (var day in userBestScoresPerDay.keys) {
      if (bestScoresPerDay[day]?['score'] ==
          userBestScoresPerDay[day]?['score']) {
        setState(() {
          days += 1;
        });
      }
    }

    userBestScoresPerWeek = findBestScorePerWeek(scoresSnapshot);
    bestScoresPerWeek = findBestScorePerWeek(allScoresSnapshot);

    for (var day in userBestScoresPerWeek.keys) {
      if (bestScoresPerWeek[day]?['score'] ==
          userBestScoresPerWeek[day]?['score']) {
        setState(() {
          weeks += 1;
        });
      }
    }

    userBestScoresPerMonth = findBestScorePerMonth(scoresSnapshot);
    bestScoresPerMonth = findBestScorePerMonth(allScoresSnapshot);

    for (var day in userBestScoresPerMonth.keys) {
      if (bestScoresPerMonth[day]?['score'] ==
          userBestScoresPerMonth[day]?['score']) {
        setState(() {
          months += 1;
        });
      }
    }

    // get all user entries in order to calculate the average position in leaderboard and score
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .get();

    int position = 0;
    List<int> userPositions = [];

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      String? user = data['name'];

      if (user == widget.username) {
        userPositions.add(position);
      }
      position++;
    }

    setState(() {
      totalGames = scoresSnapshot.docs.length;
      daysPlayed = userBestScoresPerDay.length;
      averagePosition =
          userPositions.reduce((a, b) => a + b) / userPositions.length;
      leaderboardSize = querySnapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    String username = widget.username ?? 'User';

    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' $username',
                  style: TextStyle(
                    color: widget.color!.withOpacity(.9),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your previous scores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You can scroll through all your past scores.e',
                                textAlign: TextAlign.center,
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    color: Colors.grey[800],
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: ListView.builder(
                        itemCount: userScores.length,
                        itemBuilder: (context, index) {
                          String user = userScores[index].keys.first;
                          int highscore =
                              userScores[index][user]!['score'] as int;

                          String hour = '';
                          if (userScores[index][user]!['date'].hour < 10) {
                            hour = '0${userScores[index][user]!['date'].hour}';
                          } else {
                            hour = '${userScores[index][user]!['date'].hour}';
                          }

                          String minute = '';
                          if (userScores[index][user]!['date'].minute < 10) {
                            minute =
                                '0${userScores[index][user]!['date'].minute}';
                          } else {
                            minute =
                                '${userScores[index][user]!['date'].minute}';
                          }

                          String date =
                              '${userScores[index][user]!['date'].day}/${userScores[index][user]!['date'].month}/${userScores[index][user]!['date'].year} $hour:$minute';

                          return HighscoreTile(
                            name: date,
                            highscore: highscore,
                            username: '',
                            score: 0,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your medals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: IconButton(
                          icon: const Icon(Icons.info_outline),
                          iconSize: 20,
                          color: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'The medals show the number of highscores per day, week, and month where you where the best.',
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The medals show the number of highscores per day, week, and month where you where the best.',
                          textAlign: TextAlign.center,
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      height: 70,
                      width: screenWidth,
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.brown,
                                ),
                                const Text('Days',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic)),
                                Text(days.toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.grey,
                                ),
                                const Text('Weeks',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic)),
                                Text(weeks.toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                                const Text('Months',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic)),
                                Text(months.toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Days played: Number of days you played at least one round.\nTotal Food Eaten: Number of food you ate in total, ever.\nNumber of Games: Number of games you played.\nAverage Score: Total Score / Number of Games\nAverage Position: The average of all your positions in leaderboard.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    width: screenWidth,
                    height: 145,
                    color: Colors.grey[800],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Days played: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                daysPlayed.toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Food Eaten: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                totalScore.toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Number of Games: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                totalGames.toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Average Score: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                (totalScore / totalGames).toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Average Position: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${(averagePosition).toStringAsFixed(2)} / $leaderboardSize',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: screenWidth * 0.7,
                  child: TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromRGBO(37, 42, 48, 1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fillColor: const Color.fromARGB(60, 255, 255, 255),
                      filled: true,
                      hintText: 'New username',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(75, 50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  onPressed: () {
                    changeUsername(usernameController.text);
                  },
                  child: const Text('Change',
                      style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                Navigator.pop(context, usernameController.text);
              },
              child: const Text('Back', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
