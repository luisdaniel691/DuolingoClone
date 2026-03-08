import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../data/repositories/repositorio_lecciones.dart';
import '../../logic/blocs/leccion/leccion_bloc.dart';
import '../../logic/blocs/leccion/leccion_event.dart';
import '../../logic/blocs/leccion/leccion_state.dart';

class LessonScreen extends StatelessWidget {
  // Agregamos las variables que va a recibir
  final String cursoId;
  final String unidadId;
  final String leccionId;

  const LessonScreen({
    super.key, 
    required this.cursoId, 
    required this.unidadId, 
    required this.leccionId
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeccionBloc(RepositorioLecciones())
        // Le pasamos las variables dinámicas al evento
        ..add(ComenzarLeccionEvent(cursoId, unidadId, leccionId)),
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
  String? _opcionSeleccionada;
  final FlutterTts _flutterTts = FlutterTts(); // Instancia del lector de voz

  // Función para leer el texto en inglés
  Future<void> _hablar(String texto) async {
    await _flutterTts.setLanguage("en-US"); // Idioma inglés
    await _flutterTts.setSpeechRate(0.5); // Velocidad un poco más lenta para aprender
    await _flutterTts.speak(texto);
  }

  // Limpiar el motor de voz al salir
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LeccionBloc, LeccionState>(
          listener: (context, state) {
            if (state is LeccionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.mensaje), backgroundColor: Colors.red),
              );
              if (state.mensaje.contains("energía")) Navigator.pop(context);
            } else if (state is LeccionCompletada) {
              _mostrarDialogoVictoria(context, state.xpGanada);
            }
          },
          builder: (context, state) {
            if (state is LeccionCargando) {
              return const Center(child: CircularProgressIndicator());
            } 
            
            if (state is LeccionEnProgreso) {
              final ejercicio = state.ejercicioActual;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BARRA DE PROGRESO
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close), 
                          onPressed: () => Navigator.pop(context)
                        ),
                        Expanded(
                          child: LinearPercentIndicator(
                            lineHeight: 18.0,
                            percent: state.progreso,
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
                    
                    // PREGUNTA CON BOTÓN DE VOZ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Botón de bocina azul 
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.blue, size: 36),
                          onPressed: () {
                            String textoALeer = "";
                            
                            // Si es de completar, lee la oración en inglés (cambiando "___" por "blank" para que suene bien)
                            if (ejercicio.tipo == 'completar' && ejercicio.oracionIncompleta != null) {
                              textoALeer = ejercicio.oracionIncompleta!.replaceAll("___", " ");
                            } else {
                              // Si es selección normal, lee la pregunta (ej: "Hello")
                              textoALeer = ejercicio.pregunta;
                            }
                            
                            _hablar(textoALeer);
                          },
                        ),
                        Expanded(
                          child: Text(
                            ejercicio.pregunta,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // MOSTRAR IMAGEN SI EXISTE
                    if (ejercicio.imagenUrl != null && ejercicio.imagenUrl!.isNotEmpty) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            ejercicio.imagenUrl!,
                            height: 150, // Altura para que no desborde la pantalla
                            fit: BoxFit.contain,
                            // Muestra un circulito de carga mientras baja la imagen de Firebase
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 150, 
                                child: Center(child: CircularProgressIndicator())
                              );
                            },
                            // Por si hay error al cargar
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Si es COMPLETAR ESPACIOS
                    if (ejercicio.tipo == 'completar' && ejercicio.oracionIncompleta != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        child: Text(
                          ejercicio.oracionIncompleta!,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: _opcionSeleccionada != null ? Colors.blue : Colors.black
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                    ] 
                    //Si es PAREJAS
                    else if (ejercicio.tipo == 'parejas' && ejercicio.pares != null) ...[
                      Expanded(
                        child: Center(
                          child: JuegoParejas(
                            pares: ejercicio.pares!,
                            onCompletado: () {
                              // Cuando el minijuego avisa que terminó, mandamos la respuesta al BLoC automáticamente
                              context.read<LeccionBloc>().add(ResponderPreguntaEvent("completado"));
                            },
                          ),
                        ),
                      ),
                    ]
                    // Si es SELECCIÓN MÚLTIPLE (Default)  
                    else ...[
                      const Spacer(),
                    ],

                    // OPCIONES (Sirven para ambos tipos)
                    ...ejercicio.opciones.map((opcion) {
                      final estaSeleccionada = _opcionSeleccionada == opcion;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => setState(() => _opcionSeleccionada = opcion),
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
                    }),
                    
                    const Spacer(),
                    
                    // BOTÓN COMPROBAR
                    ElevatedButton(
                      onPressed: _opcionSeleccionada == null 
                        ? null 
                        : () {
                            context.read<LeccionBloc>().add(ResponderPreguntaEvent(_opcionSeleccionada!));
                            setState(() => _opcionSeleccionada = null);
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF58CC02),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
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

  void _mostrarDialogoVictoria(BuildContext context, int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("¡Lección Completada!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.yellow, size: 80),
            const SizedBox(height: 10),
            Text("Ganaste +$xp XP", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
            child: const Text("CONTINUAR", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}


class JuegoParejas extends StatefulWidget {
  final Map<String, String> pares;
  final VoidCallback onCompletado; // Función que se ejecuta al ganar

  const JuegoParejas({super.key, required this.pares, required this.onCompletado});

  @override
  State<JuegoParejas> createState() => _JuegoParejasState();
}

class _JuegoParejasState extends State<JuegoParejas> {
  List<String> _fichas = [];
  String? _seleccionado;
  final Set<String> _resueltos = {};

  @override
  void initState() {
    super.initState();
    _prepararFichas();
  }

  // cuando cambiamos de pregunta de parejas a otra de parejas necesitamos reiniciar el juego
  @override
  void didUpdateWidget(JuegoParejas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pares != widget.pares) {
      _prepararFichas();
      _seleccionado = null;
      _resueltos.clear();
    }
  }

  void _prepararFichas() {
    // Juntamos palabras en inglés y español en una sola lista y las mezclamos
    _fichas = widget.pares.keys.toList()..addAll(widget.pares.values);
    _fichas.shuffle(); 
  }

  void _manejarToque(String texto) {
    if (_resueltos.contains(texto)) return; // Ignorar si ya se emparejó

    setState(() {
      if (_seleccionado == null) {
        // Seleccionamos la primera ficha
        _seleccionado = texto; 
      } else if (_seleccionado == texto) {
        // Si se toca la misma ficha la deselecciona
        _seleccionado = null;
      } else {
        // Tenemos dos seleccionadas, preguntamos si es par
        bool esPar = (widget.pares[_seleccionado] == texto) || (widget.pares[texto] == _seleccionado);
        
        if (esPar) {
          // si es correcto el par entonces las guardamos como resueltas
          _resueltos.add(_seleccionado!);
          _resueltos.add(texto);
        }
        
        // Limpiamos la selección actual sin importar si fue correcto o no
        _seleccionado = null; 
        
        // Verificamos si ya se emparejaron todas las fichas
        if (_resueltos.length == _fichas.length) {
          widget.onCompletado();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      alignment: WrapAlignment.center,
      children: _fichas.map((texto) {
        final estaResuelto = _resueltos.contains(texto);
        final estaSeleccionado = _seleccionado == texto;

        return GestureDetector(
          onTap: () => _manejarToque(texto),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              // Si está resuelto, se vuelve gris clarito. Si está seleccionado, azul.
              color: estaResuelto ? Colors.grey.shade200 : (estaSeleccionado ? Colors.blue.shade50 : Colors.white),
              border: Border.all(
                color: estaResuelto ? Colors.transparent : (estaSeleccionado ? Colors.blue : Colors.grey.shade300),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 18,
                // Ocultamos el texto si ya se emparejó para dar el efecto de que desaparecen
                color: estaResuelto ? Colors.transparent : Colors.black87, 
                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}