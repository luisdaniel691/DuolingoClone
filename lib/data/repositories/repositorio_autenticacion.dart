import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class RepositorioAutenticacion {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 

  // Registrar usuario y crear su documento en la BD
  Future<User?> registrarUsuario({
    required String correo, 
    required String contrasena
  }) async {
    try {
      // Crear cuenta en Auth
      UserCredential credencial = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );

      //Crear documento en Firestore con datos iniciales 
      if (credencial.user != null) {
        await _crearDatosInicialesUsuario(credencial.user!);
      }

      return credencial.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('La contraseña es muy débil.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Ya existe una cuenta con este correo.');
      }
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // Función privada para guardar los datos por defecto
  Future<void> _crearDatosInicialesUsuario(User usuario) async {
    await _firestore.collection('usuarios').doc(usuario.uid).set({
      'id_usuario': usuario.uid,
      'correo': usuario.email,
      'nombre': usuario.email!.split('@')[0], // Usamos la parte antes del @ como nombre temporal
      'xp_total': 0, 
      'energia': 25,
      'racha_dias': 0,
      'ultima_recarga_energia': FieldValue.serverTimestamp(), 
      'curso_actual_id': 'ingles', // ID del curso por defecto
      'lecciones_completadas': [], 
      'ultima_fecha_leccion': null,
    });
  }

  Future<User?> iniciarSesion({
      required String correo, 
      required String contrasena
    }) async {
      try {
        UserCredential credencial = await _auth.signInWithEmailAndPassword(
          email: correo,
          password: contrasena,
        );
        return credencial.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw Exception('No se encontró usuario con ese correo.');
        } else if (e.code == 'wrong-password') {
          throw Exception('Contraseña incorrecta.');
        }
        throw Exception('Error al entrar: ${e.message}');
      }
    }
  
    // Cerrar Sesión
    Future<void> cerrarSesion() async {
      await _auth.signOut();
    }
}