import 'package:flutter/material.dart';
//Importamos la pantalla de la lección para poder navegar a ella
import '../lesson/lesson_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.flag, color: Colors.grey),
            Row(children: const [
              Icon(Icons.local_fire_department, color: Colors.orange),
              Text(" 0")
            ]),
            Row(children: const [
              Icon(Icons.bolt, color: Colors.blue),
              Text(" 25")
            ]),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5, 
        itemBuilder: (context, index) {
          return Column(
            children: [
              // Botón 1 (El de arriba): Lo envolvemos en GestureDetector
              GestureDetector(
                onTap: () {
                  // Al tocar, navegamos a la lección
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LessonScreen()),
                  );
                },
                child: _LessonButton(
                  color: index == 0 ? const Color(0xFF58CC02) : Colors.grey,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón 2 (El de abajo en zig-zag): Este es solo visual por ahora
              Padding(
                padding: EdgeInsets.only(
                  left: index % 2 == 0 ? 40 : 0, 
                  right: index % 2 != 0 ? 40 : 0
                ),
                child: _LessonButton(
                  color: Colors.grey.shade300, 
                  icon: Icons.lock
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// Widget personalizado para los botones circulares
class _LessonButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _LessonButton({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5), 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}