import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class RewardedExample extends StatefulWidget {
  bool isGameOver = false;
  bool showWatchVideoButton = false;
  var continueGame;
  List<int> snakePosition = [];

  RewardedExample({
    Key? key,
    required this.isGameOver,
    this.continueGame,
    required this.snakePosition,
    required this.showWatchVideoButton,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RewardedExampleState();
}

class RewardedExampleState extends State<RewardedExample> {
  RewardedAd? _rewardedAd;

  final adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  void loadAd() {
    RewardedAd.load(
        adUnitId: adUnitId,
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
                onAdClicked: (ad) {});

            _rewardedAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rewarded Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rewarded Example'),
        ),
        body: Stack(
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  'snake',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Game over!'),
                  Visibility(
                    visible: widget.isGameOver,
                    child: TextButton(
                      onPressed: () {
                        widget.continueGame();
                      },
                      child: const Text('Play Again'),
                    ),
                  ),
                  Visibility(
                    visible: widget.showWatchVideoButton,
                    child: TextButton(
                      onPressed: () {
                        setState(() => widget.showWatchVideoButton = false);

                        _rewardedAd?.show(
                          onUserEarnedReward:
                              (AdWithoutView ad, RewardItem rewardItem) {
                            setState(() {
                              widget.snakePosition
                                  .removeAt(widget.snakePosition.length - 1);
                              widget.snakePosition
                                  .removeAt(widget.snakePosition.length - 1);
                              widget.snakePosition
                                  .removeAt(widget.snakePosition.length - 1);
                              widget.snakePosition
                                  .removeAt(widget.snakePosition.length - 1);
                              widget.snakePosition
                                  .removeAt(widget.snakePosition.length - 1);
                            });
                          },
                        );
                      },
                      child: const Text('Watch video to continue playing'),
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
