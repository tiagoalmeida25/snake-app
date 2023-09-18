import 'package:flutter/material.dart';

String setStringFromColor(Color colorString) {
  if (colorString == const Color.fromARGB(255, 46, 133, 49)) {
    return 'green';
  } else if (colorString == const Color.fromARGB(255, 223, 26, 12)) {
    return 'red';
  } else if (colorString == Colors.blue) {
    return 'blue';
  } else if (colorString == const Color.fromARGB(255, 158, 17, 183)) {
    return 'purple';
  } else if (colorString == const Color.fromARGB(255, 237, 14, 174)) {
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
  } else if (colorString == Colors.grey[900]) {
    return 'grey[900]';
  } else if (colorString == Colors.grey[300]) {
    return 'grey[300]';
  } else {
    return 'black';
  }
}

Color getColorFromString(String colorString) {
  switch (colorString) {
    case 'green':
      return const Color.fromARGB(255, 46, 133, 49);
    case 'red':
      return const Color.fromARGB(255, 223, 26, 12);
    case 'blue':
      return Colors.blue;
    case 'purple':
      return const Color.fromARGB(255, 158, 17, 183);
    case 'pink':
      return const Color.fromARGB(255, 237, 14, 174);
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
    case 'grey[900]':
      return const Color.fromRGBO(33, 33, 33, 1);
    case 'grey[600]':
      return const Color.fromRGBO(117, 117, 117, 1);
    case 'grey[400]':
      return const Color.fromRGBO(224, 224, 224, 1);
    case 'grey[700]':
      return const Color.fromRGBO(66, 66, 66, 1);
    case 'grey[100]':
      return const Color.fromRGBO(238, 238, 238, 1);
    case 'green[100]':
      return const Color.fromRGBO(200, 230, 201, 1);
    case 'red[100]':
      return const Color.fromRGBO(255, 205, 210, 1);
    case 'blue[100]':
      return const Color.fromRGBO(187, 222, 251, 1);
    case 'yellow[100]':
      return const Color.fromRGBO(255, 249, 196, 1);
    case 'orange[100]':
      return const Color.fromRGBO(255, 224, 178, 1);
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
