import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snake/highscore_tile.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Snake extends StatefulWidget {
  const Snake({super.key});

  @override
  SnakeState createState() => SnakeState();
}

class SnakeState extends State<Snake> with WidgetsBindingObserver {
  int numberOfSquares = 704;
  int rowSize = 22;

  static List<int> snakePosition = [76, 98, 120, 142];

  bool readMove = true;
  bool isGameStart = true;
  bool isGameOnPause = false;
  bool isPoison = false;

  String? name;
  int playerPosition = 0;
  int score = 0;

  String reasonForGameOver = '';

  static var randomNumber = Random();
  int food = randomNumber.nextInt(702);
  int poison = randomNumber.nextInt(702);

  @override
  void initState() {
    super.initState();
    loadUsername();
    setState(() {
      letsGetDocIds = getDocIds();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void generateNewFood() {
    if (isPoison) {
      poison = randomNumber.nextInt(702);

      while (snakePosition.contains(poison)) {
        poison = randomNumber.nextInt(702);
      }
    }

    food = randomNumber.nextInt(702);
    while (snakePosition.contains(food)) {
      food = randomNumber.nextInt(702);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!isGameStart && !isGameOnPause) {
        togglePause();
      }
    }
  }

  Future<void> loadUsername() async {
    String? username = await getUsername();
    setState(() {
      name = username;
    });

    Fluttertoast.showToast(
      msg: "Welcome back, $name!",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void signoff() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  Future<String?> getUsername() async {
    var user = FirebaseAuth.instance.currentUser;

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(user?.uid)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        String? username = userData['username'];
        return username;
      }
    }
    return null;
  }

  void startGame() {
    isGameStart = false;
    snakePosition = [76, 98, 120, 142];
    var timeLength = 175;

    var duration = Duration(milliseconds: timeLength);
    direction = 'down';

    Timer.periodic(duration, (Timer timer) {
      score = snakePosition.length - 4;
      if (gameOver()) {
        timer.cancel();
        submitScore();
        _showGameOverScreen();
      } else {
        if (!isGameOnPause) {
          readMove = true;

          updateSnake();
        }
      }
    });
  }

  var direction = 'down';
  void updateSnake() {
    setState(() {
      switch (direction) {
        case 'down':
          if (snakePosition.last > numberOfSquares - rowSize) {
            snakePosition.add(snakePosition.last + rowSize - numberOfSquares);
          } else {
            snakePosition.add(snakePosition.last + rowSize);
          }
          break;
        case 'up':
          if (snakePosition.last < rowSize) {
            snakePosition.add(snakePosition.last - rowSize + numberOfSquares);
          } else {
            snakePosition.add(snakePosition.last - rowSize);
          }
          break;
        case 'left':
          if (snakePosition.last % rowSize == 0) {
            snakePosition.add(snakePosition.last - 1 + rowSize);
          } else {
            snakePosition.add(snakePosition.last - 1);
          }
          break;

        case 'right':
          if ((snakePosition.last + 1) % rowSize == 0) {
            snakePosition.add(snakePosition.last + 1 - rowSize);
          } else {
            snakePosition.add(snakePosition.last + 1);
          }
          break;

        default:
      }
      if (snakePosition.last == food) {
        if (snakePosition.length % 10 == 0 && !isPoison) {
          isPoison = true;
        } else if (isPoison && (snakePosition.length - 4) % 10 == 0) {
          isPoison = false;
        }
        generateNewFood();
      } else {
        snakePosition.removeAt(0);
      }
    });
  }

  bool gameOver() {
    for (int i = 0; i < snakePosition.length; i++) {
      int count = 0;
      for (int j = 0; j < snakePosition.length; j++) {
        if (snakePosition[i] == snakePosition[j]) {
          count += 1;
        }
        if (count == 2) {
          reasonForGameOver = 'You ran into yourself!';
          return true;
        }
      }
    }

    if (isPoison && snakePosition.last == poison) {
      isPoison = false;
      reasonForGameOver = 'You ate the poison!';
      return true;
    }
    return false;
  }

  void resume() {
    isGameOnPause = false;
    Navigator.of(context).pop();
  }

  void togglePause() {
    isGameOnPause = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () => Future.value(false),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Paused',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 125,
                        color: Colors.green,
                        onPressed: resume,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> leaderboardDocIds = [];
  late Future? letsGetDocIds;
  Map<String, int> highscores = {};

  void refreshLeaderboard() {
    setState(() {
      letsGetDocIds = getDocIds();
    });
  }

  Future<void> getDocIds() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('highscores')
        .orderBy('score', descending: true)
        .get();

    Map<String, int> updatedHighscores = {};

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

    setState(() {
      highscores = updatedHighscores;
      leaderboardDocIds = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void submitScore() {
    final data = {'name': name, 'score': score};

    FirebaseFirestore.instance.collection('highscores').add(data);
    refreshLeaderboard();

    FirebaseFirestore.instance
        .collection("highscores")
        .orderBy('score', descending: true)
        .get()
        .then(
      (value) {
        value.docs.asMap().forEach(
          (index, element) {
            if (element.data()['score'] == score) {
              playerPosition = index + 1;
            }
          },
        );
      },
    );
  }

  void _showGameOverScreen() {
    isGameStart = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            dialogBackgroundColor: Colors.grey[800],
            dialogTheme: const DialogTheme(
              titleTextStyle: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
              contentTextStyle: TextStyle(
                color: Color.fromARGB(255, 248, 248, 248),
                fontSize: 18,
              ),
            ),
          ),
          child: WillPopScope(
            onWillPop: () => Future.value(false),
            child: AlertDialog(
              title: const Text('Game Over'),
              content: FutureBuilder(
                future: letsGetDocIds,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    return const Text('Error loading leaderboard.');
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reasonForGameOver,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Your score: ',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              score.toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'You positioned: ',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              playerPosition.toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text('Top 20 Leaderboard:'),
                        const SizedBox(
                          height: 8,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 350,
                              child: ListView.builder(
                                itemCount:
                                    highscores.length, 
                                itemBuilder: (context, index) {
                                  String user =
                                      highscores.keys.elementAt(index);
                                  int highscore = highscores[user]!;

                                  return HighscoreTile(
                                    name: user,
                                    highscore: highscore,
                                    username: name,
                                    score: score,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Play Again'),
                  onPressed: () {
                    startGame();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    double screenWidth = MediaQuery.of(context).size.width;
    double desiredHeight = screenWidth * (560 / 20) / 20;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: const [
                      Text(
                        'snake ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    color: Colors.white,
                    onPressed: signoff,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                height: desiredHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.grey[800],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (direction != 'up' && details.delta.dy > 0) {
                          if (readMove) {
                            direction = 'down';
                            readMove = false;
                          }
                        } else if (direction != 'down' &&
                            details.delta.dy < 0) {
                          if (readMove) {
                            direction = 'up';
                            readMove = false;
                          }
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (direction != 'left' && details.delta.dx > 0) {
                          if (readMove) {
                            direction = 'right';
                            readMove = false;
                          }
                        } else if (direction != 'right' &&
                            details.delta.dx < 0) {
                          if (readMove) {
                            direction = 'left';
                            readMove = false;
                          }
                        }
                      },
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: numberOfSquares,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: rowSize,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          if (snakePosition.last == index) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            );
                          }
                          if (snakePosition.contains(index)) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            );
                          }
                          if (isPoison && index == poison) {
                            return Container(
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.green[400],
                                ),
                              ),
                            );
                          }
                          if (index == food) {
                            return Container(
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.green,
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.all(2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(color: Colors.grey[800]),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 20.0, left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: isGameStart ? startGame : togglePause,
                    child: isGameStart
                        ? Column(
                            children: const [
                              Text(
                                'start',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '',
                                style: TextStyle(fontSize: 20),
                              )
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              const Text(
                                'pause',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'score: $score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
