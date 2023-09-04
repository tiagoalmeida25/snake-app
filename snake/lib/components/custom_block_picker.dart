import 'package:flutter/material.dart';

class CustomBlockPicker extends StatefulWidget {
  final List<Color> availableColors;
  final Color colorToSet;
  final Function(Color) onColorSelected;

  const CustomBlockPicker({
    Key? key,
    required this.colorToSet,
    required this.availableColors,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  CustomBlockPickerState createState() => CustomBlockPickerState();
}

class CustomBlockPickerState extends State<CustomBlockPicker> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 25.0,
          mainAxisSpacing: 15.0,
        ),
        itemBuilder: (context, index) {
          final pickedColor = widget.availableColors[index];
          final isSelected = pickedColor == widget.colorToSet;

          return GestureDetector(
            onTap: () => handleColorTapped(pickedColor),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 50.0,
                    height: 60.0,
                    color: pickedColor,
                  ),
                ),
                if (isSelected)
                  Center(
                    child: Icon(
                      Icons.check,
                      color: pickedColor == Colors.white ||
                              pickedColor == Colors.grey ||
                              pickedColor ==
                                  const Color.fromRGBO(224, 224, 224, 1)
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
              ],
            ),
          );
        },
        itemCount: widget.availableColors.length,
      ),
    );
  }

  void handleColorTapped(Color pickedColor) {
    widget.onColorSelected(pickedColor);
  }
}
