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
        "pregunta": "¿Cómo se dice 'Hola'?",
        "opciones": ["Hello", "Good bye", "Milk"],
        "respuesta_correcta": "Hello"
      },
      {
        "tipo": "seleccion",
        "pregunta": "¿Cómo se dice 'Gato'?",
        "opciones": ["Dog", "Cat", "Water"],
        "respuesta_correcta": "Cat"
      },
      {
        "tipo": "seleccion",
        "pregunta": "El hombre",
        "opciones": ["The woman", "The man", "The boy"],
        "respuesta_correcta": "The man"
      },
      {
        "tipo": "seleccion",
        "pregunta": "¿Qué es esto? (Agua)",
        "opciones": ["Water", "Bread", "Apple"],
        "respuesta_correcta": "Water"
      },
      {
        "tipo": "seleccion",
        "pregunta": "Traduce: 'Mujer'",
        "opciones": ["Man", "Woman", "She"],
        "respuesta_correcta": "Woman"
      },
      {
        "tipo": "seleccion",
        "pregunta": "I eat bread",
        "opciones": ["Yo como pan", "Yo bebo agua", "Tú comes"],
        "respuesta_correcta": "Yo como pan"
      },
      {
        "tipo": "seleccion",
        "pregunta": "¿Cómo se dice 'Perro'?",
        "opciones": ["Cat", "Horse", "Dog"],
        "respuesta_correcta": "Dog"
      },
      {
        "tipo": "seleccion",
        "pregunta": "Última: Traduce 'Adiós'",
        "opciones": ["Hello", "Good bye", "Thanks"],
        "respuesta_correcta": "Good bye"
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