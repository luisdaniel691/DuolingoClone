import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../data/repositories/repositorio_lecciones.dart';
import '../../logic/blocs/leccion/leccion_bloc.dart';
import '../../logic/blocs/leccion/leccion_event.dart';
import '../../logic/blocs/leccion/leccion_state.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // inyectamos el BLoC al crear la pantalla
    return BlocProvider(
      create: (context) => LeccionBloc(RepositorioLecciones())
        ..add(ComenzarLeccionEvent(
          'ingles', // ID del Curso
          'unidad_1',      // ID de la Unidad
          'leccion_1'      // ID de la Lección
        )),
      child: const _VistaLeccion(),
    );
  }
}

class _VistaLeccion extends StatefulWidget {
  const _VistaLeccion();

  @override
  State<_VistaLeccion> createState() => _VistaLeccionState();
}

class _VistaLeccionState extends State<_VistaLeccion> {
  // estado local para saber qué botón seleccionó el usuario visualmente
  String? _opcionSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // BlocConsumer escucha cambios y reconstruye la UI
        child: BlocConsumer<LeccionBloc, LeccionState>(
          listener: (context, state) {
            // EFECTOS SECUNDARIOS (Navegación, Alertas)
            if (state is LeccionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.mensaje), backgroundColor: Colors.red),
              );
              if (state.mensaje.contains("energía")) {
                Navigator.pop(context); // Sacarlo si no tiene energía
              }
            } else if (state is LeccionCompletada) {
              _mostrarDialogoVictoria(context, state.xpGanada);
            }
          },
          builder: (context, state) {
            // CONSTRUCCIÓN VISUAL
            if (state is LeccionCargando) {
              return const Center(child: CircularProgressIndicator());
            } 
            
            if (state is LeccionEnProgreso) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // bARRA DE PROGRESO
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close), 
                          onPressed: () => Navigator.pop(context)
                        ),
                        Expanded(
                          child: LinearPercentIndicator(
                            lineHeight: 18.0,
                            percent: state.progreso, // Viene del BLoC (0.0 a 1.0)
                            backgroundColor: Colors.grey[300],
                            progressColor: const Color(0xFF58CC02),
                            barRadius: const Radius.circular(10),
                            animation: true,
                            animateFromLastPercent: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // LA PREGUNTA
                    Text(
                      state.ejercicioActual.pregunta,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    
                    const Spacer(),
                    
                    // LAS OPCIONES (Dinámicas)
                    ...state.ejercicioActual.opciones.map((opcion) {
                      final estaSeleccionada = _opcionSeleccionada == opcion;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _opcionSeleccionada = opcion;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: estaSeleccionada ? Colors.blue.withOpacity(0.1) : Colors.white,
                              border: Border.all(
                                color: estaSeleccionada ? Colors.blue : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              opcion,
                              style: TextStyle(
                                fontSize: 18,
                                color: estaSeleccionada ? Colors.blue : Colors.black87,
                                fontWeight: estaSeleccionada ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    const Spacer(),
                    
                    // BOTÓN COMPROBAR
                    ElevatedButton(
                      onPressed: _opcionSeleccionada == null 
                        ? null // deshabilitado si no eligió nada
                        : () {
                            // enviamos la respuesta al BLoC
                            context.read<LeccionBloc>().add(
                              ResponderPreguntaEvent(_opcionSeleccionada!)
                            );
                            // limpiamos la selección local para la siguiente pregunta
                            setState(() => _opcionSeleccionada = null);
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF58CC02),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        )
                      ),
                      child: const Text("COMPROBAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            }

            return const Center(child: Text("Preparando lección..."));
          },
        ),
      ),
    );
  }

  // DIÁLOGO DE VICTORIA , cuando la leccion se completo
  void _mostrarDialogoVictoria(BuildContext context, int xp) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a usar el botón
      builder: (context) => AlertDialog(
        title: const Text("¡Lección Completada! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.yellow, size: 80),
            const SizedBox(height: 10),
            Text("Ganaste +$xp XP", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("¡Sigue así!", style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra dialogo
              Navigator.pop(context); // Regresa al Mapa
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
            child: const Text("CONTINUAR", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}