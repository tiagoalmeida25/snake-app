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
  final int crossAxisCount = 5;
  final double blockSize = 45.0; 
  final double spacingFactor = 0.2; 

  double get crossAxisSpacing =>
      (MediaQuery.of(context).size.width - (crossAxisCount * blockSize)) /
      ((crossAxisCount - 1) + (crossAxisCount * spacingFactor));

  double get mainAxisSpacing => blockSize * spacingFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
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
                    width: blockSize,
                    height: blockSize + 10, // Adjust this value as needed
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
