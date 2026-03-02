import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RepositorioUsuario {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenemos el ID del usuario actual
  String? get usuarioActualUid => _auth.currentUser?.uid;

  // Funcion para actualizar nombre y apellido
  Future<void> actualizarPerfil(String nuevoNombre, String nuevoApellido) async {
    final uid = usuarioActualUid;
    if (uid == null) return; // Si no hay usuario no hacemos nada

    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'nombre': nuevoNombre,
        'apellido': nuevoApellido, 
      });
    } catch (e) {
      throw Exception("Error al actualizar perfil: $e");
    }
  }
}