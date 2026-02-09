import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'presentation/main_wrapper.dart'; //  Importamos el wrapper

void main() {
  runApp(const DuolingoCloneApp());
}

class DuolingoCloneApp extends StatelessWidget {
  const DuolingoCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duolingo Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainWrapper(), // Arrancamos con el contenedor de pestañas
    );
  }
}