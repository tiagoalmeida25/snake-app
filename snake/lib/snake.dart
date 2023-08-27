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
  static List<int> snakePosition = [45, 65, 85, 105];
  int numberOfSquares = 580;
  int rowSize = 20;
  final nameController = TextEditingController();
  bool isGameStart = true;
  bool isGameOnPause = false;
  bool readMove = true;
  int playerPosition = 0;
  String? name;

  @override
  void initState() {
    super.initState();
    super.initState();
    loadUsername();
    setState(() {
      letsGetDocIds = getDocIds();
    });
    WidgetsBinding.instance.addObserver(this);
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

  static var randomNumber = Random();
  int food = randomNumber.nextInt(580);

  late String lastDirection = 'down';

  void generateNewFood() {
    food = randomNumber.nextInt(580);

    while (snakePosition.contains(food)) {
      food = randomNumber.nextInt(580);
    }
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

  void submitScore() {
    refreshLeaderboard();

    final score = snakePosition.length - 4;

    final data = {'name': name, 'score': score};
    FirebaseFirestore.instance.collection('highscores').add(data);

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

    Fluttertoast.showToast(
      msg: 'Score submitted!',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  List<String> leaderboardDocIds = [];
  late Future? letsGetDocIds;

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

    setState(() {
      leaderboardDocIds = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void startGame() {
    isGameStart = false;
    snakePosition = [45, 65, 85, 105];
    var timeLength = 250;

    var duration = Duration(milliseconds: timeLength);
    direction = 'down';

    Timer.periodic(duration, (Timer timer) {
      if (gameOver()) {
        timer.cancel();
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
          } else if (snakePosition.last == numberOfSquares - rowSize) {
            snakePosition.add(0);
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
          return true;
        }
      }
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

  void _showGameOverScreen() {
    isGameStart = true;
    submitScore();

    showDialog(
      context: context,
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
                    return const Text('Error loading leaderboard.');
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                              (snakePosition.length - 4).toString(),
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
                          height: 24,
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
                              child: FutureBuilder(
                                future: letsGetDocIds,
                                builder: (context, snapshot) {
                                  return ListView.builder(
                                    itemCount: 20,
                                    itemBuilder: (context, index) {
                                      return HighscoreTile(
                                          documentId: leaderboardDocIds[index]);
                                    },
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
    double desiredHeight = screenWidth / 20 *( 560/20); 

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
            SizedBox(
              height: desiredHeight,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (direction != 'up' && details.delta.dy > 0) {
                    if (readMove) {
                      direction = 'down';
                      readMove = false;
                    }
                  } else if (direction != 'down' && details.delta.dy < 0) {
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
                  } else if (direction != 'right' && details.delta.dx < 0) {
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
                            child: Container(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }
                    if (snakePosition.contains(index)) {
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
                    if (index == food) {
                      return Container(
                        padding: const EdgeInsets.all(1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            color: Colors.green,
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.all(1),
                        child:
                      ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(color: const Color.fromARGB(255, 23, 23, 23)))
                          );
                    }
                  },
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
                        ? const Text(
                            'start',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          )
                        : Column(
                            children: <Widget>[
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'pause',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'score: ${snakePosition.length}',
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
