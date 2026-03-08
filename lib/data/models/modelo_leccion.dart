class ModeloLeccion {
  final String id;
  final String titulo;
  final int costoEnergia;
  final int recompensaXp;
  final List<ModeloEjercicio> ejercicios;

  ModeloLeccion({
    required this.id,
    required this.titulo,
    required this.costoEnergia,
    required this.recompensaXp,
    required this.ejercicios,
  });

  //para convertir el JSON de Firebase a Objetos Dart
  factory ModeloLeccion.fromFirestore(Map<String, dynamic> data, String id) {
    return ModeloLeccion(
      id: id,
      titulo: data['titulo'] ?? 'Lección sin título',
      costoEnergia: data['energia_costo'] ?? 0,
      recompensaXp: data['xp_recompensa'] ?? 10,
      ejercicios: (data['ejercicios'] as List<dynamic>)
          .map((e) => ModeloEjercicio.fromMap(e))
          .toList(),
    );
  }
}

class ModeloEjercicio {
  final String pregunta;
  final String tipo; // seleccion,etc
  final List<String> opciones;
  final String respuestaCorrecta;
  
  final String? oracionIncompleta; 
    final Map<String, String>? pares; 
  final String? imagenUrl;

  ModeloEjercicio({
    required this.pregunta,
    required this.tipo,
    required this.opciones,
    required this.respuestaCorrecta,
    this.oracionIncompleta,
    this.pares,
    this.imagenUrl,
  });

  factory ModeloEjercicio.fromMap(Map<String, dynamic> map) {
    return ModeloEjercicio(
      pregunta: map['pregunta'] ?? '',
      tipo: map['tipo'] ?? 'seleccion',
      opciones: List<String>.from(map['opciones'] ?? []),
      respuestaCorrecta: map['respuesta_correcta'] ?? '',
      // Extraemos la oración si existe
      oracionIncompleta: map['oracion_incompleta'],
      // Convertimos el mapa de Firebase a un Map<String, String> de Dart de forma segura
      pares: map['pares'] != null ? Map<String, String>.from(map['pares']) : null,
      imagenUrl: map['imagen_url'],
    );
  }
}