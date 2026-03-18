import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'lesson_screen.dart';

class PantallaCargaLeccion extends StatefulWidget {
  final String cursoId;
  final String unidadId;
  final String leccionId;

  const PantallaCargaLeccion({
    super.key,
    required this.cursoId,
    required this.unidadId,
    required this.leccionId,
  });

  @override
  State<PantallaCargaLeccion> createState() => _PantallaCargaLeccionState();
}

class _PantallaCargaLeccionState extends State<PantallaCargaLeccion> {
  @override
  void initState() {
    super.initState();
    _iniciarTransicion();
  }

  void _iniciarTransicion() async {
    // Congelamos la pantalla por 2.5 segundos para ver la animacion
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Verificamos que el usuario no haya cerrado la app en este tiempo
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          cursoId: widget.cursoId,
          unidadId: widget.unidadId,
          leccionId: widget.leccionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // la animación Lottie
            Lottie.asset('assets/animaciones/cargando.json', width: 200),
            const SizedBox(height: 30),
            const Text(
              "Preparando tu lección...",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF58CC02) 
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "¡Asegúrate de tener el volumen alto!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}