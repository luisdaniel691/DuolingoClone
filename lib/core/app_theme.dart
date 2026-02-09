import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    primaryColor: const Color(0xFF58CC02), // Verde Duolingo
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.grey),
      titleTextStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    // Definimos botones redondeados estilo Duolingo
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF58CC02),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5, // Efecto 3D simple
      ),
    ),
  );
}