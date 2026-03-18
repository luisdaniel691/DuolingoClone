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
      
      return ModeloLeccion.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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
    
    await userRef.update({
      'xp_total': FieldValue.increment(xpGanada),
      'lecciones_completadas': FieldValue.arrayUnion(['leccion_1_completada']) // Marca histórica
    });
  }


  Future<void> validarYConsumirEnergia() async {
    final String? usuarioId = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioId == null) throw Exception("Usuario no autenticado");

    // Descargamos los datos del usuario
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).get();
    
    // Si por alguna razón no tiene los campos, le damos los valores por defecto
    int energiaGuardada = doc['energia'] ?? 25;
    Timestamp ultimaRecargaTs = doc['ultima_recarga_energia'] ?? Timestamp.now();
    DateTime ultimaRecarga = ultimaRecargaTs.toDate();

    final int maxEnergia = 25;
    final int minutosPorVida = 5;

    int energiaActual = energiaGuardada;
    DateTime nuevaFechaRecarga = ultimaRecarga;

    // CALCULAMOS LA REGENERACIÓN PASIVA
    if (energiaGuardada < maxEnergia) {
      final ahora = DateTime.now();
      final minutosPasados = ahora.difference(ultimaRecarga).inMinutes;
      final vidasGanadas = minutosPasados ~/ minutosPorVida;

      if (vidasGanadas > 0) {
        energiaActual += vidasGanadas;
        
        if (energiaActual >= maxEnergia) {
          // Si llegó o se pasó de 25, lo topamos a 25 y la fecha es HOY
          energiaActual = maxEnergia;
          nuevaFechaRecarga = ahora;
        } else {
          // Si no llegó a 25, adelantamos la fecha solo el tiempo exacto que gastó
          nuevaFechaRecarga = ultimaRecarga.add(Duration(minutes: vidasGanadas * minutosPorVida));
        }
      }
    } else {
      // Si por error tenía más de 25 lo arreglamos automáticamente a 25
      energiaActual = maxEnergia;
      nuevaFechaRecarga = DateTime.now();
    }

    // VERIFICAMOS SI LE ALCANZA PARA ENTRAR A LA LECCIÓN
    if (energiaActual > 0) {
      // Le restamos 1 vida por jugar
      int energiaFinal = energiaActual - 1;
      
      // Si estaba lleno (25) y le restamos 1, empieza a correr el reloj justo AHORA
      if (energiaActual == maxEnergia) {
        nuevaFechaRecarga = DateTime.now();
      }

      // Actualizamos la BD
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'energia': energiaFinal,
        'ultima_recarga_energia': Timestamp.fromDate(nuevaFechaRecarga),
      });
      
      // Si todo sale bien, la función termina en silencio y deja que la lección empiece
      return; 
      
    } else {
      //  SI NO TIENE ENERGÍA, LANZAMOS EL ERROR EXACTO
      throw Exception("¡Sin energía! Espera unos minutos para recuperar vidas.");
    }
  }

// Esta función actualiza la base de datos para que el usuario vea su energía subir
  Future<void> sincronizarEnergiaVisible() async {
    final String? usuarioId = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioId == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).get();
    
    int energiaGuardada = doc['energia'] ?? 25;
    Timestamp ultimaRecargaTs = doc['ultima_recarga_energia'] ?? Timestamp.now();
    DateTime ultimaRecarga = ultimaRecargaTs.toDate();

    final int maxEnergia = 25;
    final int minutosPorVida = 5;

    // Si ya tiene 25, no hacemos nada
    if (energiaGuardada >= maxEnergia) return;

    final ahora = DateTime.now();
    final minutosPasados = ahora.difference(ultimaRecarga).inMinutes;
    final vidasGanadas = minutosPasados ~/ minutosPorVida;

    // Si pasaron los 5 minutos, le sumamos la vida en la base de datos
    if (vidasGanadas > 0) {
      int energiaActual = energiaGuardada + vidasGanadas;
      DateTime nuevaFechaRecarga;
      
      if (energiaActual >= maxEnergia) {
        energiaActual = maxEnergia;
        nuevaFechaRecarga = ahora;
      } else {
        nuevaFechaRecarga = ultimaRecarga.add(Duration(minutes: vidasGanadas * minutosPorVida));
      }

      // Guardamos para que el UI y firebase vean el número subir
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'energia': energiaActual,
        'ultima_recarga_energia': Timestamp.fromDate(nuevaFechaRecarga),
      });
    }
  }


  // Función para evaluar y actualizar la racha de días consecutivos
  Future<void> actualizarRacha() async {
    final String? usuarioId = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioId == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    int rachaActual = data['racha_dias'] ?? 0;
    
    // Obtenemos el momento exacto de hoy a las 00:00:00 para evitar fallos por horas
    DateTime ahora = DateTime.now();
    DateTime hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // Verificamos si existe el campo 'ultima_fecha_leccion'
    if (!data.containsKey('ultima_fecha_leccion') || data['ultima_fecha_leccion'] == null) {
      // Es su primera lección 
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'racha_dias': 1,
        'ultima_fecha_leccion': Timestamp.fromDate(hoy),
      });
      return;
    }

    // Si ya tiene una fecha, la convertimos a dia a las 00:00:00
    DateTime ultimaFecha = (data['ultima_fecha_leccion'] as Timestamp).toDate();
    DateTime ultimoDiaJugado = DateTime(ultimaFecha.year, ultimaFecha.month, ultimaFecha.day);

    // Calculamos la diferencia exacta en días
    int diferenciaDias = hoy.difference(ultimoDiaJugado).inDays;

    if (diferenciaDias == 1) {
      // si jugo ayer mantiene la racha
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'racha_dias': rachaActual + 1,
        'ultima_fecha_leccion': Timestamp.fromDate(hoy),
      });
    } else if (diferenciaDias > 1) {
      // Se saltó un día o más. Pierde la racha y se reinicia a 1.
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'racha_dias': 1,
        'ultima_fecha_leccion': Timestamp.fromDate(hoy),
      });
    }
    // Si diferenciaDias == 0, significa que ya hizo una lección hoy. 
    // No hacemos nada, ya tiene su racha del día asegurada.
  }


  // Esta función revisa silenciosamente si el usuario perdió su racha por no jugar ayer
  Future<void> verificarRachaPerdida() async {
    final String? usuarioId = FirebaseAuth.instance.currentUser?.uid;
    if (usuarioId == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Si nunca ha jugado, no hay racha que perder
    if (!data.containsKey('ultima_fecha_leccion') || data['ultima_fecha_leccion'] == null) return;

    DateTime ahora = DateTime.now();
    DateTime hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    DateTime ultimaFecha = (data['ultima_fecha_leccion'] as Timestamp).toDate();
    DateTime ultimoDiaJugado = DateTime(ultimaFecha.year, ultimaFecha.month, ultimaFecha.day);

    int diferenciaDias = hoy.difference(ultimoDiaJugado).inDays;

    // Si pasaron 2 días o más, y su racha es mayor a 0, se la reiniciamos a 0
    int rachaActual = data['racha_dias'] ?? 0;
    if (diferenciaDias > 1 && rachaActual > 0) {
      await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).update({
        'racha_dias': 0, 
        // No actualizamos la fecha, para que cuando juegue, la diferenciaDias 
        // siga siendo > 1 y la función de terminar lección le dé su racha de 1.
      });
    }
  }

  // Evalúa todos los logros de progreso al terminar una lección
  Future<void> evaluarLogrosPostLeccion() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<dynamic> logros = data['logros_desbloqueados'] ?? [];
    int xpTotal = data['xp_total'] ?? 0;
    int racha = data['racha_dias'] ?? 0;

    int leccionesHoy = data['lecciones_hoy'] ?? 0;
    DateTime ahora = DateTime.now();
    DateTime hoy = DateTime(ahora.year, ahora.month, ahora.day);
    DateTime? fechaLeccionesHoy = data['fecha_lecciones_hoy'] != null 
        ? (data['fecha_lecciones_hoy'] as Timestamp).toDate() 
        : null;

    if (fechaLeccionesHoy == null || fechaLeccionesHoy.difference(hoy).inDays != 0) {
      leccionesHoy = 1; // Primer lección de un nuevo día
    } else {
      leccionesHoy += 1; // Sumamos a las de hoy
    }

    // Guardamos el contador diario
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'lecciones_hoy': leccionesHoy,
      'fecha_lecciones_hoy': Timestamp.fromDate(hoy),
    });

    if (!logros.contains('primeros_pasos')) {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'logros_desbloqueados': FieldValue.arrayUnion(['primeros_pasos'])
      });
    }
    if (racha >= 3 && !logros.contains('fuego_inicial')) {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'logros_desbloqueados': FieldValue.arrayUnion(['fuego_inicial'])
      });
    }
    if (xpTotal >= 1000 && !logros.contains('mente_brillante')) {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'logros_desbloqueados': FieldValue.arrayUnion(['mente_brillante'])
      });
    }
    if (leccionesHoy >= 5 && !logros.contains('modo_maraton')) {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'logros_desbloqueados': FieldValue.arrayUnion(['modo_maraton'])
      });
    }
  }


}