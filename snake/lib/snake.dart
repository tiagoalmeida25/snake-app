import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/highscore_tile.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:snake/settings.dart';

class Snake extends StatefulWidget {
  const Snake({super.key});

  @override
  SnakeState createState() => SnakeState();

  static final GlobalKey<SnakeState> snakeStateKey = GlobalKey<SnakeState>();
}

class SnakeState extends State<Snake> with WidgetsBindingObserver {
  int numberOfSquares = 704;
  int rowSize = 22;

  static List<int> snakePosition = [76, 98, 120, 142];

  bool readMove = true;
  bool isGameStart = true;
  bool isGameOnPause = false;
  bool isGameOver = false;
  bool isGameOverScreen = true;
  bool isGrid = true;

  bool isPoison = false;
  bool isExtraFood = false;

  String? name;
  int playerPosition = 0;
  int score = 0;

  Color fieldColor = Colors.black;
  Color snakeColor = Colors.white;
  Color foodColor = Colors.green;
  int timeLength = 275;
  Color gridColor = const Color.fromRGBO(66, 66, 66, 1);

  String reasonForGameOver = '';

  static var randomNumber = Random();
  int food = randomNumber.nextInt(702);
  List<int> extraFood = [];
  int poison = randomNumber.nextInt(702);

  @override
  void initState() {
    super.initState();
    loadUsername();
    setState(() {
      letsGetDocIds = getDocIds();
    });
    WidgetsBinding.instance.addObserver(this);
    setDefaultSettings();
  }

  void generateNewFood() {
    if (isPoison) {
      poison = randomNumber.nextInt(702);

      while (snakePosition.contains(poison)) {
        poison = randomNumber.nextInt(702);
      }
    }

    if (isExtraFood) {
      int nFood = randomNumber.nextInt(5);
      for (int i = 0; i < nFood; i++) {
        extraFood[i] = randomNumber.nextInt(702);

        while (snakePosition.contains(extraFood[i])) {
          extraFood[i] = randomNumber.nextInt(702);
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

    String setStringFromColor(Color colorString) {
      if (colorString == Colors.green) {
        return 'green';
      } else if (colorString == Colors.red) {
        return 'red';
      } else if (colorString == Colors.blue) {
        return 'blue';
      } else if (colorString == Colors.purple) {
        return 'purple';
      } else if (colorString == Colors.pink) {
        return 'pink';
      } else if (colorString == Colors.orange) {
        return 'orange';
      } else if (colorString == Colors.yellow) {
        return 'yellow';
      } else if (colorString == Colors.teal) {
        return 'teal';
      } else if (colorString == Colors.white) {
        return 'white';
      } else if (colorString == Colors.black) {
        return 'black';
      } else if (colorString == Colors.grey) {
        return 'grey';
      } else if (colorString == Colors.grey[800]) {
        return 'grey[700]';
      } else if (colorString == Colors.grey[100]) {
        return 'grey[100]';
      } else if (colorString == Colors.red[100]) {
        return 'red[100]';
      } else if (colorString == Colors.blue[100]) {
        return 'blue[100]';
      } else if (colorString == Colors.yellow[100]) {
        return 'yellow[100]';
      } else if (colorString == Colors.green[100]) {
        return 'green[100]';
      } else if (colorString == Colors.orange[100]) {
        return 'orange[100]';
      } else if (colorString == Colors.grey[600]) {
        return 'grey[600]';
      } else if (colorString == Colors.red[800]) {
        return 'red[800]';
      } else if (colorString == Colors.blue[800]) {
        return 'blue[800]';
      } else if (colorString == Colors.yellow[800]) {
        return 'yellow[800]';
      } else if (colorString == Colors.green[800]) {
        return 'green[800]';
      } else if (colorString == Colors.orange[800]) {
        return 'orange[800]';
      } else {
        return 'black';
      }
    }

    Color getColorFromString(String colorString) {
      switch (colorString) {
        case 'green':
          return Colors.green;
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'orange':
          return Colors.orange;
        case 'yellow':
          return Colors.yellow;
        case 'teal':
          return Colors.teal;
        case 'black':
          return Colors.black;
        case 'grey':
          return Colors.grey;
        case 'white':
          return Colors.white;
        case 'grey[700]':
          return const Color.fromRGBO(66, 66, 66, 1);
        case 'grey[100]':
          return const Color.fromRGBO(238, 238, 238, 1);
        case 'green[100]':
          return const Color.fromRGBO(129, 199, 132, 1);
        case 'red[100]':
          return const Color.fromRGBO(229, 115, 115, 1);
        case 'blue[100]':
          return const Color.fromRGBO(100, 181, 246, 1);
        case 'yellow[100]':
          return const Color.fromRGBO(255, 241, 118, 1);
        case 'orange[100]':
          return const Color.fromRGBO(255, 204, 128, 1);
        case 'grey[600]':
          return const Color.fromRGBO(117, 117, 117, 1);
        case 'red[800]':
          return const Color.fromRGBO(198, 40, 40, 1);
        case 'orange[800]':
          return const Color.fromRGBO(239, 108, 0, 1);
        case 'yellow[800]':
          return const Color.fromRGBO(249, 168, 37, 1);
        case 'green[800]':
          return const Color.fromRGBO(46, 125, 50, 1);
        case 'blue[800]':
          return const Color.fromRGBO(21, 101, 192, 1);
        default:
          return Colors.black;
      }
    }

    void setDefaultSettings() async {
      String speed = '';
      final prefs = await SharedPreferences.getInstance();

      String? savedFieldColor = prefs.getString('fieldColor');
      String? savedSnakeColor = prefs.getString('snakeColor');
      String? savedFoodColor = prefs.getString('foodColor');
      String? savedSpeed = prefs.getString('speed');
      bool? savedIsGrid = prefs.getBool('isGrid');

      if (savedFieldColor != null) {
        fieldColor = getColorFromString(savedFieldColor);
      }
      if (savedSnakeColor != null)
        snakeColor = getColorFromString(savedSnakeColor);
      if (savedFoodColor != null)
        foodColor = getColorFromString(savedFoodColor);
      if (savedSpeed != null) speed = savedSpeed;
      if (savedIsGrid != null) isGrid = savedIsGrid;

      switch (speed) {
        case 'Tedious':
          timeLength = 500;
          break;
        case 'Slow':
          timeLength = 350;
          break;
        case 'Medium':
          timeLength = 275;
          break;
        case 'Fast':
          timeLength = 200;
          break;
        case 'Very Fast':
          timeLength = 150;
          break;
        case 'Insane':
          timeLength = 75;
          break;

        default:
      }

      if (isGrid) {
        gridColor = const Color.fromRGBO(0, 0, 0, 0.2);
      } else {
        gridColor = fieldColor;
      }
    }

    void settings() async {
      isGameOnPause = true;

      final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SnakeSettings(),
          ));
      if (result != null) {
        String speed = '';
        setState(() {
          fieldColor = result[0];
          snakeColor = result[1];
          foodColor = result[2];
          speed = result[3];
          isGrid = result[4];
        });

        final prefs = await SharedPreferences.getInstance();

        prefs.setString('fieldColor', setStringFromColor(result[0]));
        prefs.setString('snakeColor', setStringFromColor(result[1]));
        prefs.setString('foodColor', setStringFromColor(result[2]));
        prefs.setString('speed', result[3]);
        prefs.setBool('isGrid', result[4]);

        switch (speed) {
          case 'Tedious':
            timeLength = 500;
            break;
          case 'Slow':
            timeLength = 350;
            break;
          case 'Medium':
            timeLength = 275;
            break;
          case 'Fast':
            timeLength = 200;
            break;
          case 'Very Fast':
            timeLength = 150;
            break;
          case 'Insane':
            timeLength = 75;
            break;

          default:
        }

        if (isGrid) {
          gridColor = const Color.fromRGBO(0, 0, 0, 0.2);
        } else {
          gridColor = fieldColor;
        }

        isGameOnPause = false;
        isGameOver = true;
        isGameOverScreen = false;
      }
    }

    void restart() {
      isGameOver = true;
      isGameOverScreen = false;
      isGameStart = true;
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
      isGameOver = false;
      isGameOverScreen = true;
      snakePosition = [76, 98, 120, 142];

      var duration = Duration(milliseconds: timeLength);
      direction = 'down';

      Timer.periodic(duration, (Timer timer) {
        score = snakePosition.length - 4;
        if (gameOver() || isGameOver) {
          timer.cancel();
          submitScore();
          if (isGameOverScreen) {
            _showGameOverScreen();
          } else {
            setState(() {
              isGameStart = true;
            });
          }
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
          if (snakePosition.length % 10 == 0 && !isExtraFood) {
            isExtraFood = true;
          } else if (isExtraFood && (snakePosition.length - 4) % 10 == 0) {
            isExtraFood = false;
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
                                'Your rank: ',
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
                            height: 20,
                          ),
                          const Text('Highscores:'),
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
                                  itemCount: highscores.length,
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
                padding:
                    const EdgeInsets.only(top: 10, left: 15.0, right: 15.0),
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: restart,
                          icon: const Icon(
                            Icons.restart_alt,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                          onPressed: settings,
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          color: Colors.white,
                          onPressed: signoff,
                        ),
                      ],
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
                      color: fieldColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: rowSize,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            if (snakePosition.last == index) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(color: snakeColor),
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
                                    child: Container(color: snakeColor),
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
                                    color: foodColor.withOpacity(0.7),
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
                                    color: foodColor,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(color: gridColor),
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
                padding: const EdgeInsets.only(
                    bottom: 20.0, left: 15.0, right: 15.0),
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
}
