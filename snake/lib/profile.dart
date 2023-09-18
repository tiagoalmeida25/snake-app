import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/components/username_textfield.dart';
import 'package:snake/highscore_tile.dart';

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
  int days = 0;
  int weeks = 0;
  int months = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      getHighscores();
      getUserScores();
      getMedals();
    });
  }

  void changeUsername(String? newUsername) async {
    var user = FirebaseAuth.instance.currentUser;

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

  Future<void> getHighscores() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .get();

    Map<String, Map<String, dynamic>> updatedHighscores = {};

    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      String? user = data['name'];
      int? score = data['score'];
      Timestamp? time = data['date'];
      DateTime? date = time?.toDate();

      if (user != null && score != null && date != null) {
        if (updatedHighscores.containsKey(user)) {
          if (updatedHighscores[user]!['score'] == null) {
            updatedHighscores[user] = {
              'score': score,
              'date': date,
            };
          } else if (updatedHighscores[user]!['score'] < score) {
            updatedHighscores[user] = {
              'score': score,
              'date': date,
            };
          }
        } else {
          updatedHighscores[user] = {
            'score': score,
            'date': date,
          };
        }
      }
    }

    setState(() {
      highscores = updatedHighscores;
    });
  }

  Future<void> getMedals() async {
    Map<DateTime, Map<String, dynamic>> highestScoresByDay = {};
    int daysUser = 0;

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    var username =
        FirebaseFirestore.instance.collection('user').doc(user.uid).get();

    highscores.forEach((key, value) {
      String name = key;
      Timestamp time = value['date'];
      DateTime date = time.toDate();
      int score = value['score'];

      DateTime day = DateTime(date.year, date.month, date.day);
      
      if (highestScoresByDay.containsKey(day)) {
        if (highestScoresByDay[day]!['score'] < score) {
          highestScoresByDay[day] = {
            'score': score,
            'date': date,
            'name': name,
          };
        }
      } else {
        highestScoresByDay[day] = {
          'score': score,
          'date': date,
          'name': name,
        };
      }

      highestScoresByDay.forEach((key, value) {
        if (value['name'] == username) {
          daysUser++;
        }
      });
    });

    setState(() {
      days = daysUser;
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Your highscores:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      color: Colors.grey[800],
                      child: SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: userScores.length,
                          itemBuilder: (context, index) {
                            String user = userScores[index].keys.first;
                            int highscore =
                                userScores[index][user]!['score'] as int;
                            String date = userScores[index][user]!['date']
                                .toString()
                                .substring(0, 10);

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
              Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Your medals:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      height: 60,
                      width: screenWidth,
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
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
                ],
              ),
              Row(
                children: [
                  UsernameField(
                    width: screenWidth - 125,
                    controller: usernameController,
                    hintText: 'New username',
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
      ),
    );
  }
}
