import 'package:cloud_firestore/cloud_firestore.dart';

class PobladorMasivo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> construirCursoCompleto() async {
    print("Iniciando construcción masiva del curso");

    // Definimos las 3 Unidades iniciales
    final unidades = [
      {
        "id": "unidad_1",
        "titulo": "Unidad 1",
        "subtitulo": "Saluda y despídete",
        "color": "#58CC02", // Verde
        "orden": 1
      },
      {
        "id": "unidad_2",
        "titulo": "Unidad 2",
        "subtitulo": "Habla de tus estudios",
        "color": "#CE82FF", // Morado
        "orden": 2
      },
      {
        "id": "unidad_3",
        "titulo": "Unidad 3",
        "subtitulo": "Describe a tu familia",
        "color": "#00CD9C", // Turquesa
        "orden": 3
      }
    ];

    final plantillaEjercicios = [
      {"tipo": "seleccion", "pregunta": "Hello", "opciones": ["Hola", "Adiós", "Gracias"], "respuesta_correcta": "Hola"},
      {"tipo": "completar", "pregunta": "Completa", "oracion_incompleta": "I ___ water", "opciones": ["eat", "drink", "sleep"], "respuesta_correcta": "drink"},
      {"tipo": "parejas", "pregunta": "Pares", "pares": {"Hello": "Hola", "Cat": "Gato", "Dog": "Perro", "Water": "Agua"}, "opciones": [], "respuesta_correcta": "completado"},
      {"tipo": "seleccion", "pregunta": "Cat", "opciones": ["Perro", "Gato", "Pez"], "respuesta_correcta": "Gato"},
      {"tipo": "seleccion", "pregunta": "Dog", "opciones": ["Perro", "Gato", "Pez"], "respuesta_correcta": "Perro"},
      {"tipo": "completar", "pregunta": "Completa", "oracion_incompleta": "She is my ___", "opciones": ["father", "mother", "brother"], "respuesta_correcta": "mother"},
      {"tipo": "seleccion", "pregunta": "Thanks", "opciones": ["Hola", "Por favor", "Gracias"], "respuesta_correcta": "Gracias"},
      {"tipo": "seleccion", "pregunta": "Goodbye", "opciones": ["Hola", "Adiós", "Sí"], "respuesta_correcta": "Adiós"},
    ];

    // Bucle para crear las unidades y sus lecciones
    for (var unidad in unidades) {
      // Guardamos los datos de la Unidad (Para los bloques verdes del Home)
      await _firestore
          .collection('cursos')
          .doc('ingles')
          .collection('unidades')
          .doc(unidad['id'] as String)
          .set({
        'titulo': unidad['titulo'],
        'subtitulo': unidad['subtitulo'],
        'color': unidad['color'],
        'orden': unidad['orden'],
      });

      print("Creada ${unidad['titulo']}");

      // Bucle para crear 3 lecciones por cada unidad
      for (int i = 1; i <= 3; i++) {
        String leccionId = "leccion_$i";
        
        await _firestore
            .collection('cursos')
            .doc('ingles')
            .collection('unidades')
            .doc(unidad['id'] as String)
            .collection('lecciones')
            .doc(leccionId)
            .set({
          'titulo': 'Lección $i',
          'energia_costo': 10,
          'xp_recompensa': 20,
          'orden': i,
          'ejercicios': plantillaEjercicios, // Aquí ponemos los 8 ejercicios
        });
      }
      print("Creadas 3 lecciones para ${unidad['titulo']}");
    }

    print("Realizadas 9 lecciones y 72 ejercicios");
  }
}