import '../../../data/models/modelo_leccion.dart';

abstract class LeccionState {}

class LeccionInicial extends LeccionState {}

class LeccionCargando extends LeccionState {}

// Este es el estado principal, y muestra el ejercicio actual
class LeccionEnProgreso extends LeccionState {
  final ModeloLeccion leccion;
  final int indiceActual; // ¿Vamos en la 0, la 1 o la 7?
  final double progreso; // Para la barra de arriba (0.0 a 1.0)
  final bool? respuestaCorrecta; // null=esperando, true=verde, false=rojo

  LeccionEnProgreso({
    required this.leccion,
    required this.indiceActual,
    this.progreso = 0,
    this.respuestaCorrecta,
  });
    
  // Getter para saber cuál ejercicio pintar
  ModeloEjercicio get ejercicioActual => leccion.ejercicios[indiceActual];
}

class LeccionCompletada extends LeccionState {
  final int xpGanada;
  LeccionCompletada(this.xpGanada);
}

class LeccionError extends LeccionState {
  final String mensaje;
  LeccionError(this.mensaje);
}