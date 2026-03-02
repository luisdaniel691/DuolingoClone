import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/repositorio_lecciones.dart';
import 'leccion_event.dart';
import 'leccion_state.dart';

class LeccionBloc extends Bloc<LeccionEvent, LeccionState> {
  final RepositorioLecciones _repo;

  LeccionBloc(this._repo) : super(LeccionInicial()) {
    
    on<ComenzarLeccionEvent>((event, emit) async {
      emit(LeccionCargando());
      try {
        // traemos la lección de la nube
        final leccion = await _repo.obtenerLeccion(event.cursoId, event.unidadId, event.leccionId);
        
        // Intentamos cobrar la energía
        final tieneEnergia = await _repo.intentarConsumirEnergia(leccion.costoEnergia);

        if (!tieneEnergia) {
          emit(LeccionError("¡No tienes suficiente energía!"));
          return;
        }

        // Empezamos en el índice 0
        emit(LeccionEnProgreso(
          leccion: leccion, 
          indiceActual: 0, 
          progreso: 0.0
        ));
      } catch (e) {
        emit(LeccionError("Error al cargar: $e"));
      }
    });

    // Logica al responder
    on<ResponderPreguntaEvent>((event, emit) async {
      // Solo podemos responder si la lección está en progreso
      if (state is LeccionEnProgreso) {
        final estadoActual = state as LeccionEnProgreso;
        final ejercicio = estadoActual.ejercicioActual;

        // Verificamos si la respuesta es correcta
        final esCorrecto = event.respuestaUsuario == ejercicio.respuestaCorrecta;

        if (esCorrecto) {
          // RESPUESTA CORRECTA
          
          // Calculamos si era la última pregunta
          final esUltima = estadoActual.indiceActual >= estadoActual.leccion.ejercicios.length - 1;

          if (esUltima) {
            // FIN DE LA LECCIÓN
            await _repo.otorgarRecompensa(estadoActual.leccion.recompensaXp);
            emit(LeccionCompletada(estadoActual.leccion.recompensaXp));
          } else {
            // SIGUIENTE PREGUNTA
            final nuevoIndice = estadoActual.indiceActual + 1;
            final nuevoProgreso = (nuevoIndice) / estadoActual.leccion.ejercicios.length;
            
            emit(LeccionEnProgreso(
              leccion: estadoActual.leccion,
              indiceActual: nuevoIndice,
              progreso: nuevoProgreso,
              respuestaCorrecta: null, // Limpiamos el estado para la nueva pregunta
            ));
          }
        } else {
          // RESPUESTA INCORRECTA 
          // Solo emitimos error visual pero no avanzamos
           emit(LeccionError("Respuesta incorrecta, intenta de nuevo"));
           // Regresamos al estado normal después de un microsegundo para que el usuario pueda intentar
           emit(estadoActual); 
        }
      }
    });
  }
}