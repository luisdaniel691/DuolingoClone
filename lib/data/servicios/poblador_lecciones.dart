import 'package:cloud_firestore/cloud_firestore.dart';

class PobladorLecciones {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> subirLeccionDePrueba() async {
    // Referencia a la lección 1 del curso de ingles
    final docLeccion = _firestore
        .collection('cursos')
        .doc('ingles')
        .collection('unidades')
        .doc('unidad_1')
        .collection('lecciones')
        .doc('leccion_1');

    // Estructura de 8 ejercicios con pura seleccion de mientras
    final listaEjercicios = [
      {
        "tipo": "seleccion",
        "pregunta": "Hello", // Inglés arriba (TTS lee esto)
        "opciones": ["Hola", "Adiós", "Leche"], // Español abajo
        "respuesta_correcta": "Hola"
      },
      {
        "tipo": "seleccion",
        "pregunta": "Cat",
        "opciones": ["Perro", "Gato", "Agua"],
        "respuesta_correcta": "Gato"
      },
      /*{
        "tipo": "seleccion",
        "pregunta": "The man",
        "opciones": ["La mujer", "El hombre", "El niño"],
        "respuesta_correcta": "El hombre"
      },*/
      {
        "tipo": "voz",
        "pregunta": "Toca el micrófono y pronuncia:",
        "oracion_incompleta": "The cat drinks water", // Usamos este campo para mostrar la frase que debe leer
        "opciones": [], // No hay botones de opciones aquí
        "respuesta_correcta": "the cat drinks water" // Todo en minúsculas para que sea fácil de comparar
      },
      {
        "tipo": "seleccion",
        "pregunta": "Water",
        "imagen_url": "https://firebasestorage.googleapis.com/v0/b/duolingoclone-2bcaa.firebasestorage.app/o/ejercicios%2Fbotella.png?alt=media&token=8920ca1d-ea00-48e8-8200-002416a76b12",
        "opciones": ["Agua", "Pan", "Manzana"],
        "respuesta_correcta": "Agua"
      },
      {
        "tipo": "completar",
        "pregunta": "Completa la oración", // Instrucción visual
        "oracion_incompleta": "I ___ water", // TTS lee esto
        "opciones": ["eat", "drink", "sleep"], 
        "respuesta_correcta": "drink"
      },
      {
        "tipo": "seleccion",
        "pregunta": "I eat bread",
        "opciones": ["Yo como pan", "Yo bebo agua", "Tú comes"],
        "respuesta_correcta": "Yo como pan"
      },
      {
        "tipo": "parejas",
        "pregunta": "Toca los pares",
        "pares": {
          "Hello": "Hola",
          "Cat": "Gato",
          "Dog": "Perro",
          "Water": "Agua"
        },
        "opciones": [], 
        "respuesta_correcta": "completado" // esto se manda al BLoC al terminar
      },
      {
        "tipo": "seleccion",
        "pregunta": "Good bye",
        "opciones": ["Hola", "Adiós", "Gracias"],
        "respuesta_correcta": "Adiós"
      },
    ];

    // Subimos los datos
    await docLeccion.set({
      'titulo': 'Intro a Saludos',
      'descripcion': 'Palabras básicas',
      'energia_costo': 10, // Cuesta 10 de energía entrar
      'xp_recompensa': 20, // Se ganan 20 XP al terminar
      'ejercicios': listaEjercicios, // Aquí va el array de 8
    });
    
    print("Lección 1 creada con éxito");
  }
}