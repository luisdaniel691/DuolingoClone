import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  // Función para subir foto a Firebase Storage y guardar la URL
  Future<void> actualizarFotoPerfil(File imagen) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Subir la imagen a Firebase Storage
      await desbloquearLogro('personalizando');
      final ref = FirebaseStorage.instance.ref().child('avatares_usuarios').child('$uid.jpg');
      await ref.putFile(imagen);

      // Obtener la URL pública
      final url = await ref.getDownloadURL();

      // Guardarla en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'foto_perfil': url,
        'es_avatar_local': false, //  para saber que es una URL de internet
      });
    } catch (e) {
      throw Exception('Error al subir la imagen: $e');
    }
  }

  // Función para guardar la selección de un avatar local
  Future<void> actualizarAvatarLocal(String rutaAsset) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await desbloquearLogro('personalizando');
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'foto_perfil': rutaAsset,
      'es_avatar_local': true, //  para saber que es una ruta de assets
    });
  }

  // Función para desbloquear cualquier logro
  Future<void> desbloquearLogro(String idLogro) async {
    final uid = usuarioActualUid;
    if (uid == null) return;

    // arrayUnion agrega el elemento SOLO si no existe en la lista (evita duplicados)
    await _firestore.collection('usuarios').doc(uid).update({
      'logros_desbloqueados': FieldValue.arrayUnion([idLogro])
    });
  }

}

