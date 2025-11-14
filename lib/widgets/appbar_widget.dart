import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.black,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.white), 
    title: Text(
      title,
      style: const TextStyle(color: Colors.white),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.home),
        tooltip: "Kezdőlap",
        onPressed: () {
          Navigator.pushNamed(context, '/');
        },
      ),
      IconButton(
        icon: const Icon(Icons.show_chart),
        tooltip: "Árfolyamok",
        onPressed: () {
          Navigator.pushNamed(context, '/rates');
        },
      ),
      IconButton(
        icon: const Icon(Icons.notifications),
        tooltip: "Értesitések",
        onPressed: () {
          Navigator.pushNamed(context, '/alerts');
        },
      ),

    ],
  );
}
