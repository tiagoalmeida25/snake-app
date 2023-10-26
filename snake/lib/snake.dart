import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/components/personalization.dart';
import 'package:snake/components/highscore_tile.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:snake/leaderboard.dart';
import 'package:snake/profile.dart';

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

  static List<int> snakePosition = [76, 98, 120, 142, 164];

  RewardedAd? _rewardedAd;
  // RewardedInterstitialAd? _rewardedInterstitialAd;

  final String _adUnitIdRewarded = 'ca-app-pub-6337096519310369/3689339358';
  // final String _adUnitIdRewarded = 'ca-app-pub-3940256099942544/5224354917';
  // final String _adUnitIdRewardedInterstitial =
  //     'ca-app-pub-6337096519310369/9216233864';

  bool readMove = true;
  bool isGameStart = true;
  bool isGameOnPause = false;
  bool isGameOver = false;
  bool isGameOverScreen = true;
  bool isGrid = true;

  bool isPoison = false;
  bool isExtraFood = false;
  bool isBorder = false;

  bool showWatchVideoButton = true;

  String? name;
  int playerPosition = 0;
  int score = 0;

  Color fieldColor = const Color.fromRGBO(33, 33, 33, 1);
  Color snakeColor = Colors.white;
  Color foodColor = const Color.fromARGB(255, 46, 133, 49);
  int timeLength = 275;
  Color gridColor = const Color.fromRGBO(66, 66, 66, 1);
  bool isSoundOn = true;

  String reasonForGameOver = '';

  static var randomNumber = Random();
  int food = randomNumber.nextInt(702);
  List<int> extraFood = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1];

  List<int> borders = [
    for (int i = 0; i < 22; i++) i,
    for (int i = 22; i < 704; i += 22) i,
    for (int i = 21; i < 704; i += 22) i,
    for (int i = 682; i < 704; i++) i,
  ];
  int poison = -1;

  AudioPlayer pointAudio = AudioPlayer();
  AudioPlayer losingAudio = AudioPlayer();
  AudioPlayer gameOverAudio = AudioPlayer();
  AudioPlayer extraFoodAudio = AudioPlayer();

  @override
  void initState() {
    loadUsername();
    setState(() {
      letsGetDocIds = getDocIds();
    });
    WidgetsBinding.instance.addObserver(this);
    setDefaultSettings();
    super.initState();
  }

  void generateNewFood() {
    food = randomNumber.nextInt(704);
    while (snakePosition.contains(food) || borders.contains(food)) {
      food = randomNumber.nextInt(704);
    }

    if (isPoison) {
      poison = randomNumber.nextInt(704);

      while (snakePosition.contains(poison) ||
          poison == food ||
          borders.contains(poison)) {
        poison = randomNumber.nextInt(704);
      }
    }

    if (isExtraFood) {
      int nFood = randomNumber.nextInt(5) + 5;

      for (int i = 0; i < nFood; i++) {
        extraFood[i] = randomNumber.nextInt(704);

        while (snakePosition.contains(extraFood[i]) ||
            extraFood[i] == poison ||
            borders.contains(extraFood[i])) {
          extraFood[i] = randomNumber.nextInt(704);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardedAd?.dispose();
    // _rewardedInterstitialAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!isGameStart && !isGameOnPause && !isGameOver) {
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

  void setDefaultSettings() async {
    String speed = '';
    final prefs = await SharedPreferences.getInstance();

    String? savedFieldColor = prefs.getString('fieldColor');
    String? savedSnakeColor = prefs.getString('snakeColor');
    String? savedFoodColor = prefs.getString('foodColor');
    String? savedSpeed = prefs.getString('speed');
    bool? savedIsGrid = prefs.getBool('isGrid');
    bool? savedIsSoundOn = prefs.getBool('isSoundOn');

    if (savedFieldColor != null) {
      fieldColor = getColorFromString(savedFieldColor);
    }
    if (savedSnakeColor != null) {
      snakeColor = getColorFromString(savedSnakeColor);
    }
    if (savedFoodColor != null) {
      foodColor = getColorFromString(savedFoodColor);
    }
    if (savedSpeed != null) speed = savedSpeed;
    if (savedIsGrid != null) isGrid = savedIsGrid;
    if (savedIsSoundOn != null) isSoundOn = savedIsSoundOn;

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
      if (fieldColor == Colors.black) {
        gridColor = const Color.fromARGB(153, 38, 38, 38);
      } else if (fieldColor == const Color.fromRGBO(33, 33, 33, 1)) {
        gridColor = const Color.fromARGB(153, 48, 48, 48);
      } else if (fieldColor == const Color.fromRGBO(117, 117, 117, 1)) {
        gridColor = const Color.fromARGB(153, 148, 147, 147);
      } else if (fieldColor == const Color.fromRGBO(224, 224, 224, 1)) {
        gridColor = const Color.fromARGB(153, 255, 255, 255);
      } else if (fieldColor == Colors.white) {
        gridColor = const Color.fromARGB(153, 230, 230, 230);
      }
    } else {
      gridColor = fieldColor;
    }
  }

  void settings() async {
    togglePause();
    
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
        isSoundOn = result[5];
      });

      final prefs = await SharedPreferences.getInstance();

      prefs.setString('fieldColor', setStringFromColor(result[0]));
      prefs.setString('snakeColor', setStringFromColor(result[1]));
      prefs.setString('foodColor', setStringFromColor(result[2]));
      prefs.setString('speed', result[3]);
      prefs.setBool('isGrid', result[4]);
      prefs.setBool('isSoundOn', result[5]);

      int previousTimeLength = timeLength;

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

      if (previousTimeLength != timeLength) {
        isGameOver = true;
        isGameOverScreen = false;
      }

      if (isGrid) {
        if (fieldColor == Colors.black) {
          gridColor = const Color.fromARGB(153, 38, 38, 38);
        } else if (fieldColor == const Color.fromRGBO(33, 33, 33, 1)) {
          gridColor = const Color.fromARGB(153, 48, 48, 48);
        } else if (fieldColor == const Color.fromRGBO(117, 117, 117, 1)) {
          gridColor = const Color.fromARGB(153, 148, 147, 147);
        } else if (fieldColor == const Color.fromRGBO(224, 224, 224, 1)) {
          gridColor = const Color.fromARGB(153, 255, 255, 255);
        } else if (fieldColor == Colors.white) {
          gridColor = const Color.fromARGB(153, 230, 230, 230);
        }
      } else {
        gridColor = fieldColor;
      }

      isGameOnPause = false;
    }
  }

  void restart() {
    setState(() {
      isGameOver = true;
      isGameOverScreen = false;
      isGameOnPause = false;
      isGameStart = true;
    });
  }

  // void _loadRewardedInterstitialAd() {
  //   RewardedInterstitialAd.load(
  //     adUnitId: _adUnitIdRewardedInterstitial,
  //     request: const AdRequest(),
  //     rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
  //       onAdLoaded: (RewardedInterstitialAd ad) {
  //         ad.fullScreenContentCallback = FullScreenContentCallback(
  //           onAdShowedFullScreenContent: (ad) {},
  //           onAdImpression: (ad) {},
  //           onAdFailedToShowFullScreenContent: (ad, err) {
  //             ad.dispose();
  //           },
  //           onAdDismissedFullScreenContent: (ad) {
  //             ad.dispose();
  //           },
  //           onAdClicked: (ad) {},
  //         );
  //         _rewardedInterstitialAd = ad;
  //       },
  //       onAdFailedToLoad: (LoadAdError error) {
  //         debugPrint('Rewarded interstitial ad failed to load: $error');
  //       },
  //     ),
  //   );
  // }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitIdRewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdClicked: (ad) {},
          );
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> keepPlayingAd(StreamSubscription? gameStream) async {
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
              title: const Text('Keep playing?'),
              content: const Text('Watch a video to continue playing.'),
              actions: [
                TextButton(
                  onPressed: () {
                    gameStream?.cancel();
                    setState(() => showWatchVideoButton = false);
                    Navigator.of(context).pop();
                    // _rewardedInterstitialAd?.show(
                    //   onUserEarnedReward: (ad, reward) {},
                    // );
                    _showGameOverScreen();
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      showWatchVideoButton = false;
                      isGameOver = false;
                      adShown = true;
                      Navigator.of(context).pop();
                    });
                    await _rewardedAd?.show(
                      onUserEarnedReward:
                          (AdWithoutView ad, RewardItem rewardItem) {
                        setState(
                          () {
                            gameStream?.resume();
                            isGameOver = false;
                            isPoison = false;
                            isExtraFood = false;
                            isBorder = false;
                            adShown = true;

                            for (int i = 0; i < snakePosition.length; i++) {
                              snakePosition[i] = 55;
                            }
                            snakePosition.last = 77;
                            direction = 'down';

                            togglePause();
                          },
                        );
                      },
                    );
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> getUsername() async {
    var user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.providerData.isNotEmpty &&
          user.providerData[0].providerId == 'google.com') {
        return user.displayName;
      } else {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null) {
            String? username = userData['username'];
            return username;
          }
        }
      }
    }

    return null;
  }

  StreamSubscription? gameStream;
  bool adShown = false;

  Future<void> startGame() async {
    isGameStart = false;
    isGameOver = false;
    isGameOverScreen = true;
    isGameOnPause = false;
    isPoison = false;
    isExtraFood = false;
    isBorder = false;
    showWatchVideoButton = true;
    adShown = false;

    await DefaultCacheManager().emptyCache();

    _loadRewardedAd();
    // _loadRewardedInterstitialAd();

    snakePosition = [76, 98, 120, 142, 164];

    var duration = Duration(milliseconds: timeLength);
    direction = 'down';

    gameStream = Stream.periodic(duration).listen((_) async {
      score = snakePosition.length - 5;
      // isBorder = true;
      // score = snakePosition.length + 30;

      if (gameOver() || isGameOver) {
        if (isGameOverScreen) {
          if (isSoundOn) {
            gameOverAudio.play(AssetSource('gameover.wav'));
          }

          // gameStream?.cancel();
          // _showGameOverScreen();
          // setState(() {
          //   isGameStart = true;
          //   isPoison = false;
          //   isExtraFood = false;
          //   isBorder = false;
          // });

          print('adShown: $adShown');
          print('_rewardedAd: $_rewardedAd');

          if (!adShown && _rewardedAd != null) {
            gameStream?.pause();
            await keepPlayingAd(gameStream);
          } else {
            gameStream?.cancel();
            // if (_rewardedInterstitialAd != null) {
            //   _rewardedInterstitialAd?.show(
            //     onUserEarnedReward: (ad, reward) {},
            //   );
            // }
            _showGameOverScreen();
          }
        } else {
          gameStream?.cancel();
          setState(() {
            isGameStart = true;
            isPoison = false;
            isExtraFood = false;
            isBorder = false;
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
    setState(
      () {
        switch (direction) {
          case 'down':
            if (snakePosition.last > numberOfSquares - rowSize - 1) {
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
        if (isBorder) {
          for (int i = 0; i < borders.length; i++) {
            if (snakePosition.last == borders[i]) {
              isGameOver = true;
              reasonForGameOver = 'You ran into a border!';

              if (isSoundOn) {
                losingAudio.play(AssetSource('ai.wav'));
              }
            }
          }
        }
        if (isExtraFood) {
          for (int i = 0; i < extraFood.length; i++) {
            if (snakePosition.last == extraFood[i]) {
              if (isSoundOn) {
                extraFoodAudio.play(AssetSource('blah.wav'));
              }
              extraFood[i] = -1;
            }
          }
        }
        if (snakePosition.last == food) {
          if ((score + 1) % 20 == 0 && !isExtraFood && score > 25) {
            isExtraFood = true;
            Fluttertoast.showToast(
              msg: "Find the true food, but careful with the poison!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else if (isExtraFood && score % 20 == 0 && score > 25) {
            isExtraFood = false;
          }
          if ((score + 1) % 10 == 0 && !isPoison && score > 10) {
            isPoison = true;
            if (!isExtraFood) {
              Fluttertoast.showToast(
                msg: "Look out for the poison!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          } else if (isPoison && (score - 2) % 10 == 0 && score > 10) {
            isPoison = false;
          }
          if (!isBorder && (score + 1) % 25 == 0 && score > 10) {
            isBorder = true;
            Fluttertoast.showToast(
              msg: "Look out for the borders!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else if (isBorder && (score - 4) % 25 == 0 && score > 10) {
            isBorder = false;
          }
          generateNewFood();
          if (isSoundOn) {
            pointAudio.play(AssetSource('nhamnham.wav'));
          }
        } else {
          snakePosition.removeAt(0);
        }
      },
    );
  }

  bool gameOver() {
    for (int i = 0; i < snakePosition.length - 1; i++) {
      if (snakePosition[i] == snakePosition.last) {
        reasonForGameOver = 'You ran into yourself!';
        if (isSoundOn) {
          losingAudio.play(AssetSource('ai.wav'));
        }
        isGameOver = true;
        return true;
      }
    }

    if (isPoison && snakePosition.last == poison) {
      isPoison = false;
      isGameOver = true;
      reasonForGameOver = 'You ate the poison!';
      if (isSoundOn) {
        extraFoodAudio.play(AssetSource('ew.wav'));
      }

      return true;
    }
    return false;
  }

  void resume() {
    isGameOnPause = false;
    Navigator.of(context).pop();
  }

  void togglePause() {
    if (isGameStart) return;

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
        .collection('leaderboard')
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

  void updateHighscore(Map<String, int> highscoresMap, String user, int score) {
    if (highscoresMap.containsKey(user)) {
      if (highscoresMap[user]! < score) {
        highscoresMap[user] = score;
      }
    } else {
      highscoresMap[user] = score;
    }
  }

  void submitScore() {
    final data = {
      'name': name,
      'score': score,
      'date': FieldValue.serverTimestamp(),
    };

    if (score != 0) {
      FirebaseFirestore.instance.collection('leaderboard').add(data);
    }
    refreshLeaderboard();

    FirebaseFirestore.instance
        .collection("leaderboard")
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

  void leaderboards() {
    togglePause();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Leaderboard(username: name, score: score, color: foodColor),
      ),
    );
  }

  void _showGameOverScreen() {
    setState(() => isGameStart = true);
    submitScore();

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
                              height: MediaQuery.of(context).size.height * 0.6,
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
                                    rank: (index + 1).toString(),
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
                    isGameStart = true;
                    isGameOnPause = false;
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

  void profile() async {
    togglePause();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(username: name, color: foodColor),
      ),
    );

    if (result != null) {
      setState(() {
        name = result[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double availableHeight = screenHeight - 120;

    int numberRows = (numberOfSquares / rowSize).ceil();
    double sizeSquare = screenWidth / (rowSize + 1);

    double desiredHeight = numberRows * sizeSquare;
    double desiredWidth = (rowSize + .5) * sizeSquare;

    var paddingToAdd = 0.0;
    if (availableHeight < desiredHeight) {
      setState(() {
        paddingToAdd = (desiredHeight - availableHeight) / 2;
      });

      if (screenWidth < desiredWidth + 10 + paddingToAdd) {
        setState(() {
          paddingToAdd -= (desiredWidth + 10 + paddingToAdd - screenWidth) / 3;
        });
      }
    }

    if (availableHeight > desiredHeight) {
      setState(() {
        availableHeight = desiredHeight;
      });
    }

    // print('\nWidth:');
    // print('   desired width: ${desiredWidth.toStringAsFixed(2)} + ${paddingToAdd.toStringAsFixed(2)} = ${(screenWidth + paddingToAdd).toStringAsFixed(2)}' );
    // print('   available width: $screenWidth');
    // print('Height:');
    // print('   desired height: ${desiredHeight.toStringAsFixed(2)}');
    // print('   available height: $availableHeight');
    // print('padding: $paddingToAdd');

    return WillPopScope(
      onWillPop: () async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
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
                  child: AlertDialog(
                    title: const Text('Exit Game?'),
                    content: const Text('Do you want to exit the game?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop(false); // Continue playing.
                        },
                      ),
                      TextButton(
                        child: const Text('Exit'),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Exit the game.
                        },
                      ),
                    ],
                  ),
                );
              },
            ) ??
            false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Row(
                      children: [
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
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 35,
                          child: IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                            onPressed: profile,
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: IconButton(
                            icon: const Icon(
                              Icons.leaderboard,
                              color: Colors.white,
                            ),
                            onPressed: leaderboards,
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: IconButton(
                            onPressed: restart,
                            icon: const Icon(
                              Icons.restart_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: IconButton(
                            onPressed: settings,
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: IconButton(
                            icon: const Icon(Icons.logout),
                            color: Colors.white,
                            onPressed: signoff,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0 + paddingToAdd),
                child: SizedBox(
                  height: availableHeight,
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
                              // int snakeHead = snakePosition.last;
                              // int snakePos =
                              //     snakePosition.elementAt(snakePosition.length - 2);

                              // if (snakePos == snakeHead - 1) {
                              //   return Center(
                              //     child: Container(
                              //       padding: const EdgeInsets.only(
                              //           top: 2, bottom: 2, left: 0, right: 2),
                              //       child: ClipRRect(
                              //         borderRadius: BorderRadius.only(
                              //           topRight: Radius.circular(64),
                              //           bottomRight: Radius.circular(64),
                              //           topLeft: Radius.circular(32),
                              //           bottomLeft: Radius.circular(32),
                              //         ),
                              //         child: Container(color: snakeColor),
                              //       ),
                              //     ),
                              //   );
                              // }
                              // else{
                              //     return Center(
                              //       child: Container(
                              //         padding: const EdgeInsets.all(2),
                              //         child: ClipRRect(
                              //           borderRadius: BorderRadius.circular(32),
                              //           child: Container(color: snakeColor),
                              //         ),
                              //       ),
                              //     );
                              //   // }
                              // }
                              // if (index == snakePosition.first) {
                              //   if (snakePosition.first ==
                              //       snakePosition.elementAt(1) + 22) {
                              //     return Container(
                              //       padding: const EdgeInsets.only(
                              //           top: 0, bottom: 0, left: 4, right: 4),
                              //       child: ClipRRect(
                              //         borderRadius: const BorderRadius.only(
                              //           bottomLeft: Radius.circular(64),
                              //           bottomRight: Radius.circular(64),
                              //           topLeft: Radius.circular(4),
                              //           topRight: Radius.circular(4),
                              //         ),
                              //         child: Container(
                              //           color: snakeColor,
                              //         ),
                              //       ),
                              //     );
                              //   } else if (snakePosition.first ==
                              //       snakePosition.elementAt(1) - 22) {
                              //     return Container(
                              //       padding: const EdgeInsets.only(
                              //           top: 0, bottom: 0, left: 4, right: 4),
                              //       child: ClipRRect(
                              //         borderRadius: const BorderRadius.only(
                              //           topLeft: Radius.circular(64),
                              //           topRight: Radius.circular(64),
                              //           bottomLeft: Radius.circular(4),
                              //           bottomRight: Radius.circular(4),
                              //         ),
                              //         child: Container(
                              //           color: snakeColor,
                              //         ),
                              //       ),
                              //     );
                              //   } else if (snakePosition.first ==
                              //       snakePosition.elementAt(1) - 1) {
                              //     return Container(
                              //       padding: const EdgeInsets.only(
                              //           top: 4, bottom: 4, left: 0, right: 0),
                              //       child: ClipRRect(
                              //         borderRadius: const BorderRadius.only(
                              //           topLeft: Radius.circular(64),
                              //           topRight: Radius.circular(4),
                              //           bottomLeft: Radius.circular(64),
                              //           bottomRight: Radius.circular(4),
                              //         ),
                              //         child: Container(
                              //           color: snakeColor,
                              //         ),
                              //       ),
                              //     );
                              //   } else if (snakePosition.first ==
                              //       snakePosition.elementAt(1) + 1) {
                              //     return Container(
                              //       padding: const EdgeInsets.only(
                              //           top: 4, bottom: 4, left: 0, right: 0),
                              //       child: ClipRRect(
                              //         borderRadius: const BorderRadius.only(
                              //           topLeft: Radius.circular(4),
                              //           topRight: Radius.circular(64),
                              //           bottomLeft: Radius.circular(4),
                              //           bottomRight: Radius.circular(64),
                              //         ),
                              //         child: Container(
                              //           color: snakeColor,
                              //         ),
                              //       ),
                              //     );
                              //   }
                            }
                            // if (snakePosition
                            //         .elementAt(snakePosition.length - 2) ==
                            //     index) {
                            //   int snakePos = snakePosition
                            //       .elementAt(snakePosition.length - 2);
                            //   int snakeHead = snakePosition.last;
                            //   int nextSnakePos =
                            //       snakePosition.elementAt(snakePosition.length - 3);

                            //   if (snakePos == snakeHead - 1 &&
                            //       snakePos == nextSnakePos + 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomLeft: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomLeft: Radius.circular(32),
                            //                   topLeft: Radius.circular(4),
                            //                   topRight: Radius.circular(4),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead + 1 &&
                            //       snakePos == nextSnakePos + 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //             bottomLeft: Radius.circular(4),
                            //             topLeft: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead - 1 &&
                            //       snakePos == nextSnakePos - 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(32),
                            //             topRight: Radius.circular(4),
                            //             bottomRight: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead + 1 &&
                            //       snakePos == nextSnakePos - 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topRight: Radius.circular(32),
                            //             topLeft: Radius.circular(4),
                            //             bottomLeft: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead + 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //             bottomLeft: Radius.circular(4),
                            //             topLeft: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead + 22 &&
                            //       snakePos == nextSnakePos - 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomLeft: Radius.circular(32),
                            //             topLeft: Radius.circular(4),
                            //             topRight: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead + 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //             bottomLeft: Radius.circular(4),
                            //             topLeft: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead - 22 &&
                            //       snakePos == nextSnakePos - 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(32),
                            //             topRight: Radius.circular(4),
                            //             bottomRight: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == snakeHead - 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topRight: Radius.circular(32),
                            //             topLeft: Radius.circular(4),
                            //             bottomLeft: Radius.circular(4),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   }

                            //   if (snakePos == snakeHead - 1) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(
                            //           top: 4, bottom: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topRight: Radius.circular(4),
                            //             bottomRight: Radius.circular(4),
                            //           ),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            //   }
                            //   else if (snakePos == snakeHead + 1) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(
                            //             left:2, top: 4, bottom: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(4),
                            //             bottomLeft: Radius.circular(4),
                            //           ),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            //   }
                            //   else if (snakePos == snakeHead + 22) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(top: 0, left: 4, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(4),
                            //             topRight: Radius.circular(4),
                            //           ),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            //   }
                            //   else if (snakePos == snakeHead - 22) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(
                            //           bottom: 0, left: 4, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomLeft: Radius.circular(4),
                            //             bottomRight: Radius.circular(4),
                            //           ),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            //   }
                            // } else if (snakePosition.contains(index)) {
                            //   int snakeIndex = snakePosition
                            //       .indexWhere((element) => element == index);
                            //   int snakePos =
                            //       snakePosition.elementAt(snakeIndex);
                            //   int nextSnakePos =
                            //       snakePosition.elementAt(snakeIndex - 1);
                            //   int previousSnakePos =
                            //       snakePosition.elementAt(snakeIndex + 1);

                            //   if (snakePos == previousSnakePos - 1 &&
                            //       snakePos == nextSnakePos + 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomLeft: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos + 1 &&
                            //       snakePos == nextSnakePos + 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos - 1 &&
                            //       snakePos == nextSnakePos - 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos + 1 &&
                            //       snakePos == nextSnakePos - 22) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topRight: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos + 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos + 22 &&
                            //       snakePos == nextSnakePos - 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomLeft: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos + 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 4, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             bottomRight: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               top: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   bottomRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos - 22 &&
                            //       snakePos == nextSnakePos - 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 4, right: 0),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topLeft: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               right: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topLeft: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == previousSnakePos - 22 &&
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 0, left: 0, right: 4),
                            //         child: ClipRRect(
                            //           borderRadius: const BorderRadius.only(
                            //             topRight: Radius.circular(32),
                            //           ),
                            //           child: Stack(children: [
                            //             Container(
                            //               width: sizeSquare,
                            //               height: sizeSquare,
                            //               color: snakeColor,
                            //             ),
                            //             Positioned(
                            //               left: 0,
                            //               bottom: 0,
                            //               child: ClipRRect(
                            //                 borderRadius:
                            //                     const BorderRadius.only(
                            //                   topRight: Radius.circular(32),
                            //                 ),
                            //                 child: Container(
                            //                   width: 4,
                            //                   height: 4,
                            //                   color: gridColor,
                            //                 ),
                            //               ),
                            //             )
                            //           ]),
                            //         ),
                            //       ),
                            //     );
                            //   }
                            //   if (snakePos == nextSnakePos - 1 ||
                            //       snakePos == nextSnakePos + 1) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(
                            //             top: 4, bottom: 4, left: 0, right: 0),
                            //         child: ClipRRect(
                            //           // borderRadius: BorderRadius.circular(4),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            //   } else if (snakePos == nextSnakePos - rowSize ||
                            //       snakePos == nextSnakePos + rowSize) {
                            //     return Center(
                            //       child: Container(
                            //         padding: const EdgeInsets.only(
                            //             top: 0, bottom: 0, left: 4, right: 4),
                            //         child: ClipRRect(
                            //           // borderRadius: BorderRadius.circular(4),
                            //           child: Container(color: snakeColor),
                            //         ),
                            //       ),
                            //     );
                            // }
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
                            // }
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
                            if (isExtraFood && extraFood.contains(index)) {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: foodColor,
                                  ),
                                ),
                              );
                            }
                            if (isBorder && borders.contains(index)) {
                              if (index == 0) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8)),
                                  child: Container(
                                    color: Colors.blueGrey,
                                  ),
                                );
                              } else if (index == rowSize - 1) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(8)),
                                  child: Container(
                                    color: Colors.blueGrey,
                                  ),
                                );
                              } else if (index == numberOfSquares - rowSize) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8)),
                                  child: Container(
                                    color: Colors.blueGrey,
                                  ),
                                );
                              } else if (index == numberOfSquares - 1) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      bottomRight: Radius.circular(8)),
                                  child: Container(
                                    color: Colors.blueGrey,
                                  ),
                                );
                              } else {
                                return Container(
                                  color: Colors.blueGrey,
                                );
                              }
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
                                  child: Container(
                                    color: gridColor,
                                  ),
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
                    bottom: 10.0, left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: isGameStart ? startGame : togglePause,
                      child: isGameStart
                          ? const Column(
                              children: [
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
      ),
    );
  }
}
