import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../data/repositories/repositorio_lecciones.dart';
import '../../logic/blocs/leccion/leccion_bloc.dart';
import '../../logic/blocs/leccion/leccion_event.dart';
import '../../logic/blocs/leccion/leccion_state.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

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
  bool _mostrarFeedback = false; 
  bool _fueCorrecto = false;


  final TextEditingController _controladorTexto = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Función para leer el texto en inglés
  Future<void> _hablar(String texto) async {
    await _flutterTts.setLanguage("en-US"); // Idioma inglés
    await _flutterTts.setSpeechRate(0.5); // la velocidad con la que habla
    await _flutterTts.speak(texto);
  }

  void _lanzarFeedback(bool acerto) async {
    // Reproducimos el sonido
    if (acerto) {
      await _audioPlayer.play(AssetSource('sonidos/acierto.mp3'));
    } else {
      await _audioPlayer.play(AssetSource('sonidos/error.mp3'));
    }

    // Mostramos la barra
    setState(() {
      _fueCorrecto = acerto;
      _mostrarFeedback = true;
    });
  }

  // Limpiar el motor de voz al salir
  @override
  void dispose() {
    _flutterTts.stop();
    _controladorTexto.dispose();
    super.dispose();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LeccionBloc, LeccionState>(
          listener: (context, state) {
            if (state is LeccionError) {
              // Solo mostramos el mensaje rojo de Flutter si es por falta de energía
              
              if (state.mensaje.toLowerCase().contains("energía")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.mensaje), backgroundColor: Colors.red),
                );
                Navigator.pop(context); // sacamos de la lección
              }
            } else if (state is LeccionCompletada) {
              _audioPlayer.play(AssetSource('sonidos/victoria.mp3'));
              _mostrarDialogoVictoria(context, state.xpGanada);
            }
          },
          builder: (context, state) {
            if (state is LeccionCargando) {
              return const Center(child: CircularProgressIndicator());
            } 

            if (state is LeccionError && !state.mensaje.toLowerCase().contains("energía")) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/animaciones/error.json', width: 200),
                        const SizedBox(height: 20),
                        const Text(
                          "¡Sin conexión!", 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No pudimos descargar esta lección. Revisa tu internet y vuelve a intentarlo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context), // Regresa al mapa
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("VOLVER AL MAPA", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                );
              }
            
            if (state is LeccionEnProgreso) {
              final ejercicio = state.ejercicioActual;

              

      return Stack(
          children: [
            // EL CONTENIDO DE LA LECCIÓN (Congelado si hay feedback)
            IgnorePointer(
              ignoring: _mostrarFeedback,
              child: Padding(
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
                            
                            // Si es de completar, lee la oración en inglés (cambiando "___" por "." para que suene un espacio)
                            if (ejercicio.tipo == 'completar' && ejercicio.oracionIncompleta != null) {
                              textoALeer = ejercicio.oracionIncompleta!.replaceAll("___", ".");
                            } else {
                              // Si es selección normal, lee la pregunta 
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
                          child: CachedNetworkImage(
                            imageUrl: ejercicio.imagenUrl!,
                            height: 150, // Altura para que no desborde la pantalla
                            fit: BoxFit.contain,
                            // Muestra un circulito de carga la primera vez que baja la imagen
                            placeholder: (context, url) => const SizedBox(
                                height: 150, 
                                child: Center(child: CircularProgressIndicator())
                            ),
                            // Por si hay error al cargar
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      //  CAJA DE TEXTO
                      TextField(
                        controller: _controladorTexto,
                        onChanged: (textoEscrito) {
                          // Conectamos lo que escribe con la variable del botón COMPROBAR
                          setState(() {
                            // Si borra todo, se vuelve null y el botón se apaga
                            _opcionSeleccionada = textoEscrito.trim().isEmpty ? null : textoEscrito.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Escribe tu respuesta aquí...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15), 
                            borderSide: const BorderSide(color: Colors.blue, width: 2)
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 18),
                        textInputAction: TextInputAction.done, // Muestra el botón de Listo en el teclado del celular
                      ),
                      const Spacer(),
                    ]


                    //Si es PAREJAS
                    else if (ejercicio.tipo == 'parejas' && ejercicio.pares != null) ...[
                      Expanded(
                          child: JuegoParejas(
                            pares: ejercicio.pares!,
                            onCompletado: () {
                              // Cuando termina mandamos la respuesta al BLoC automáticamente
                              _lanzarFeedback(true);
                              setState(() {
                                _fueCorrecto = true;
                                _mostrarFeedback = true;
                              });
                            },
                          ),
                        //),
                      ),
                    ]

                    // Si es de voz
                    else if (ejercicio.tipo == 'voz') ...[
                      Expanded(
                        child: EjercicioVoz(
                          textoAEscuchar: ejercicio.oracionIncompleta ?? "",
                          respuestaCorrecta: ejercicio.respuestaCorrecta,
                          onCompletado: () {
                            _lanzarFeedback(true);
                            setState(() {
                              _fueCorrecto = true;
                              _mostrarFeedback = true; // Esto hace que salga el Lottie de correcto.json
                            });
                          },
                        ),
                      ),
                    ]


                    // Si es SELECCIÓN MÚLTIPLE (Default)  
                    else ...[
                      const Spacer(),
                        // OPCIONES
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
                    ],

                         
                    
                    if (ejercicio.tipo != 'parejas') ...[
                      const Spacer(),
                    ],
                    
                    // BOTÓN COMPROBAR
                    ElevatedButton(
                      onPressed: (_opcionSeleccionada == null || _mostrarFeedback) 
                        ? null 
                        : () {
                            // Validamos si acertó
                            bool acerto = _opcionSeleccionada!.toLowerCase() == ejercicio.respuestaCorrecta.toLowerCase();
                            _lanzarFeedback(acerto);
                            // Mostramos la barra en lugar de avanzar
                            setState(() {
                              _fueCorrecto = acerto;
                              _mostrarFeedback = true;
                            });
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
               ),
              ),
              // LA BARRA DE FEEDBACK ANIMADA (Encima de todo)
                  if (_mostrarFeedback)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: BarraRetroalimentacion(
                        esCorrecto: _fueCorrecto,
                        respuestaCorrecta: ejercicio.respuestaCorrecta,
                        onContinuar: () {
                          // avanzamos la lección en el BLoC
                          String respuestaAEnviar = "fallo";
                          if (_fueCorrecto) {
                            // Si es de parejas mandamos "completado", si no, mandamos la respuesta normal
                            respuestaAEnviar = ejercicio.tipo == 'parejas' ? "completado" : ejercicio.respuestaCorrecta;
                          }

                          // avanzamos la lección en el BLoC
                          context.read<LeccionBloc>().add(
                            ResponderPreguntaEvent(respuestaAEnviar)
                          );
                          
                          // Ocultamos la barra y limpiamos para la siguiente
                          setState(() {
                            _mostrarFeedback = false;
                            _opcionSeleccionada = null;
                            _controladorTexto.clear();
                          });
                        },
                      ),
                    ),
                ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¡Lección Completada!", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // animacion de victoria
            Lottie.asset(
              'assets/animaciones/victoria.json', 
              width: 150, 
              height: 150, 
              repeat: true // se repite mientras se mira la XP
            ),
            const SizedBox(height: 15),
            Text(
              "Ganaste +$xp XP", 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF58CC02))
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Sale de la lección y vuelve al mapa
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            child: const Text("CONTINUAR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Center(
        child: Wrap(
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
     ),
      );
    
   
  }
}

class EjercicioVoz extends StatefulWidget {
  final String textoAEscuchar;
  final String respuestaCorrecta;
  final VoidCallback onCompletado;

  const EjercicioVoz({
    super.key,
    required this.textoAEscuchar,
    required this.respuestaCorrecta,
    required this.onCompletado,
  });

  @override
  State<EjercicioVoz> createState() => _EjercicioVozState();
}

class _EjercicioVozState extends State<EjercicioVoz> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoReconocido = "Toca el micrófono para hablar...";
  bool _esCorrecto = false;
  
  late final AnimationController _animController;
  Timer? _vigilante; // timer de seguridad

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(EjercicioVoz oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textoAEscuchar != widget.textoAEscuchar) {
      _apagarMicrofono();
      setState(() {
        _textoReconocido = "Toca el micrófono para hablar...";
        _esCorrecto = false;
      });
    }
  }

  @override
  void dispose() {
    _vigilante?.cancel(); // Matamos al vigilante al salir
    _animController.dispose();
    _speech.cancel(); 
    super.dispose();
    
  }

  // MÉTODO PARA FORZAR APAGADO
  void _apagarMicrofono() {
    _vigilante?.cancel(); // Detenemos el timer
    _speech.stop();       // Forzamos apagado del hardware
    if (mounted) {
      setState(() => _isListening = false);
      _animController.reset(); // Reiniciamos animación
    }
  }

  void _escuchar() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) setState(() => _textoReconocido = "Permiso de micrófono denegado");
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        // Aunque la librería falle en avisarnos, lo dejamos por si acaso
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') _apagarMicrofono();
        },
        onError: (val) => _apagarMicrofono(),
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);
        _animController.repeat(); 
        
        // Revisa cada 500 milisegundos el estado REAL del hardware
        _vigilante = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (mounted && _isListening && !_speech.isListening) {
            // Si nuestra pantalla dice "estoy escuchando" pero el hardware dice "no",
            // significa que se apagó en secreto, aun asi apagamos todo
            _apagarMicrofono(); 
          }
        });

        _speech.listen(
          localeId: 'en_US', 
          partialResults: true, 
          pauseFor: const Duration(seconds: 3), 
          listenFor: const Duration(seconds: 8), 
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textoReconocido = val.recognizedWords;
                
                if (_textoReconocido.toLowerCase() == widget.respuestaCorrecta.toLowerCase()) {
                  _esCorrecto = true;
                  _apagarMicrofono(); // Apagamos todo al acertar
                  
                  Future.delayed(const Duration(milliseconds: 0), () {
                    if (mounted) widget.onCompletado();
                  });
                }
              });
            }
          },
        );
      }
    } else {
      _apagarMicrofono(); // Apagado manual si el usuario toca el botón
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.textoAEscuchar,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10), 
          
          GestureDetector(
            onTap: _escuchar,
            child: Lottie.asset(
              'assets/animaciones/ondas_voz.json',
              controller: _animController,
              width: 110,  
              height: 110, 
              fit: BoxFit.contain, 
              onLoaded: (composition) {
                _animController.duration = composition.duration;
              },
            ),
          ),

          const SizedBox(height: 10), 
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: SingleChildScrollView(
                child: Text(
                  _textoReconocido,
                  style: TextStyle(
                    fontSize: 18, 
                    color: _esCorrecto ? Colors.green : Colors.grey.shade800,
                    fontStyle: FontStyle.italic
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarraRetroalimentacion extends StatelessWidget {
  final bool esCorrecto;
  final String respuestaCorrecta;
  final VoidCallback onContinuar;

  const BarraRetroalimentacion({
    super.key,
    required this.esCorrecto,
    required this.respuestaCorrecta,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorFondo = esCorrecto ? const Color(0xFFD7FFB8) : const Color(0xFFFFE0E0);
    final Color colorTexto = esCorrecto ? const Color(0xFF58CC02) : const Color(0xFFEA2B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
        ]
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
                  ),
                  child: Lottie.asset(
                    esCorrecto ? 'assets/animaciones/correcto.json' : 'assets/animaciones/incorrecto.json',
                    repeat: false, // Para que la palomita no parpadee infinitamente
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esCorrecto ? "¡Excelente!" : "¡Uy! Intenta de nuevo",
                        style: TextStyle(color: colorTexto, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (!esCorrecto)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            "Solución: $respuestaCorrecta",
                            style: TextStyle(color: colorTexto.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            // Botón Continuar
            ElevatedButton(
              onPressed: onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTexto,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("CONTINUAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}