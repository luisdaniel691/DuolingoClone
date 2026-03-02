import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/modelo_leccion.dart';

class RepositorioLecciones {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener la lección desde Firebase
  Future<ModeloLeccion> obtenerLeccion(String cursoId, String unidadId, String leccionId) async {
    try {
      final doc = await _firestore
          .collection('cursos')
          .doc(cursoId)
          .collection('unidades')
          .doc(unidadId)
          .collection('lecciones')
          .doc(leccionId)
          .get();

      if (!doc.exists) throw Exception("La lección no existe");
      
      return ModeloLeccion.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception("Error al cargar lección: $e");
    }
  }

  // Pago de energia al entrar o iniciar una leccion
  Future<bool> intentarConsumirEnergia(int costo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userRef = _firestore.collection('usuarios').doc(uid);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("Usuario no encontrado");

      final int energiaActual = snapshot.data()?['energia'] ?? 0;

      if (energiaActual >= costo) {
        // Si alcanza, restamos y guardamos
        transaction.update(userRef, {'energia': energiaActual - costo});
        return true; // Éxito
      } else {
        return false; // No alcanza
      }
    });
  }

  // Dar XP al usuario al finalizar la leccion
  Future<void> otorgarRecompensa(int xpGanada) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('usuarios').doc(uid);
    
    // Incremento atómico (seguro para bases de datos)
    await userRef.update({
      'xp_total': FieldValue.increment(xpGanada),
      'lecciones_completadas': FieldValue.arrayUnion(['leccion_1_completada']) // Marca histórica
    });
  }
}