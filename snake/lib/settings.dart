import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnakeSettings extends StatefulWidget {
  const SnakeSettings({super.key});

  @override
  SnakeSettingsState createState() => SnakeSettingsState();
}

List<String> speedList = [
  'Tedious',
  'Slow',
  'Medium',
  'Fast',
  'Very Fast',
  'Insane',
];

class SnakeSettingsState extends State<SnakeSettings> {
  Color fieldColor = Colors.amber;
  Color snakeColor = Colors.amber;
  Color foodColor = Colors.amber;
  String dropdownSpeed = 'Medium';
  bool isGrid = false;

  @override
  void initState() {
    super.initState();
    getAndApplyDefaultSettings();
  }

  void getAndApplyDefaultSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? savedFieldColor = prefs.getString('fieldColor');
    String? savedSnakeColor = prefs.getString('snakeColor');
    String? savedFoodColor = prefs.getString('foodColor');
    String? savedSpeed = prefs.getString('speed');
    bool? savedIsGrid = prefs.getBool('isGrid');

    setState(
      () {
        if (savedFieldColor != null) {
          fieldColor = getColorFromString(savedFieldColor);
        }
        if (savedSnakeColor != null) {
          snakeColor = getColorFromString(savedSnakeColor);
        }
        if (savedFoodColor != null) {
          foodColor = getColorFromString(savedFoodColor);
        }
        if (savedSpeed != null) dropdownSpeed = savedSpeed;
        if (savedIsGrid != null) isGrid = savedIsGrid;
      },
    );
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    final MaterialStateProperty<Color?> trackColor =
        MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return foodColor;
        }
        if (states.contains(MaterialState.disabled)) {
          return const Color.fromARGB(255, 255, 255, 255);
        }
        return null;
      },
    );
    final MaterialStateProperty<Color?> overlayColor =
        MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return foodColor.withOpacity(0.54);
        }
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey[400];
        }
        return null;
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 15.0, right: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    'Choose Field Color:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 125,
                child: BlockPicker(
                  pickerColor: fieldColor,
                  availableColors: const [
                    Colors.black,
                    Color.fromRGBO(66, 66, 66, 1),
                    Colors.grey,
                    Color.fromRGBO(238, 238, 238, 1),
                    Colors.white,
                    Color.fromRGBO(255, 205, 210, 1),
                    Color.fromRGBO(255, 224, 178, 1),
                    Color.fromRGBO(255, 249, 196, 1),
                    Color.fromRGBO(200, 230, 201, 1),
                    Color.fromRGBO(187, 222, 251, 1),
                  ],
                  onColorChanged: (color) {
                    setState(() => fieldColor = color);
                  },
                  layoutBuilder: (context, colors, child) {
                    return GridView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 80,
                        mainAxisExtent: 60,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      children: [for (Color color in colors) child(color)],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    'Choose Snake Color:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 125,
                child: BlockPicker(
                  pickerColor: snakeColor,
                  availableColors: const [
                    Colors.black,
                    Color.fromRGBO(33, 33, 33, 1),
                    Color.fromRGBO(117, 117, 117, 1), 
                    Colors.grey,
                    Colors.white,
                    Color.fromRGBO(198, 40, 40, 1),
                    Color.fromRGBO(239, 108, 0, 1),
                    Color.fromRGBO(249, 168, 37, 1),
                    Color.fromRGBO(46, 125, 50, 1),
                    Color.fromRGBO(21, 101, 192, 1),
                  ],
                  onColorChanged: (color) {
                    setState(() => snakeColor = color);
                  },
                  layoutBuilder: (context, colors, child) {
                    return GridView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 80,
                        mainAxisExtent: 60,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      children: [for (Color color in colors) child(color)],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    'Choose Food Color:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 125,
                child: BlockPicker(
                  pickerColor: foodColor,
                  availableColors: const [
                    Colors.purple,
                    Colors.pink,
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.blue,
                    Colors.teal,
                    Colors.green,
                  ],
                  onColorChanged: (color) {
                    setState(() => foodColor = color);
                  },
                  layoutBuilder: (context, colors, child) {
                    return GridView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 90,
                        mainAxisExtent: 60,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      children: [for (Color color in colors) child(color)],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Speed:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  DropdownButton<String>(
                    value: dropdownSpeed,
                    dropdownColor: const Color.fromARGB(255, 34, 34, 34),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: speedList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        dropdownSpeed = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose to activate Grid:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Switch(
                    value: isGrid,
                    overlayColor: overlayColor,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[400],
                    trackColor: trackColor,
                    thumbColor: const MaterialStatePropertyAll<Color>(
                        Color.fromARGB(255, 255, 255, 255)),
                    onChanged: (bool value) {
                      setState(() {
                        isGrid = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: foodColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                      context, [fieldColor, snakeColor, foodColor, dropdownSpeed, isGrid]);
                },
                child: const Text('Back', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
