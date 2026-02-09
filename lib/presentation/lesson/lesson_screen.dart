import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progreso Superior
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () {}),
                  Expanded(
                    child: LinearPercentIndicator(
                      lineHeight: 15.0,
                      percent: 0.3, // 30% completado
                      backgroundColor: Colors.grey[300],
                      progressColor: const Color(0xFF58CC02),
                      barRadius: const Radius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Pregunta
              const Text("Selecciona la imagen de 'El Gato'", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Aquí irían las opciones (Grid o Lista)
              Container(height: 200, color: Colors.grey[100], child: const Center(child: Text("Area de Opciones"))),
              const Spacer(),
              // Botón Comprobar
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("COMPROBAR", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}