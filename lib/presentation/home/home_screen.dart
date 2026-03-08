import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import '../lesson/lesson_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snapshotUsuario) {
        int energia = 0;
        int xp = 0;
        int racha = 0; 

        if (snapshotUsuario.hasData && snapshotUsuario.data!.exists) {
          final data = snapshotUsuario.data!.data() as Map<String, dynamic>;
          energia = data['energia'] ?? 0;
          xp = data['xp_total'] ?? 0;
          racha = data['racha_dias'] ?? 0;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.flag, color: Colors.grey, size: 30),
                Row(children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  Text(" $racha", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))
                ]),
                Row(children: [
                  const Icon(Icons.bolt, color: Colors.blue),
                  Text(" $xp XP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                ]),
                Row(children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  Text(" $energia", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                ]),
              ],
            ),
          ),
          
          body: FutureBuilder<QuerySnapshot>(
            // traemos las unidades ordenadas del 1 al 3
            future: FirebaseFirestore.instance.collection('cursos').doc('ingles').collection('unidades').orderBy('orden').get(),
            builder: (context, snapshotUnidades) {
              
              if (!snapshotUnidades.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final unidades = snapshotUnidades.data!.docs;

              return ListView.builder(
                itemCount: unidades.length,
                itemBuilder: (context, indexUnidad) {
                  final dataUnidad = unidades[indexUnidad].data() as Map<String, dynamic>;
                  final idUnidad = unidades[indexUnidad].id; // unidad_1, unidad_2, etc
                  
                  // Convertimos el string Hex a Color de Dart
                  final colorUnidad = Color(int.parse(dataUnidad['color'].replaceAll('#', '0xff')));

                  return Column(
                    children: [
                      // EL BLOQUE DE LA UNIDAD (Header)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorUnidad,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dataUnidad['titulo'].toUpperCase(), 
                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 5),
                            Text(
                              dataUnidad['subtitulo'], 
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                      
                      // LAS 3 LECCIONES en Zig-Zag
                      // las dibujamos estaticas de momento
                      for (int i = 1; i <= 3; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 20,
                            // Lógica matemática simple para el zig-zag (Izquierda, Centro, Derecha)
                            left: i == 1 ? 0 : (i == 2 ? 60 : 0),
                            right: i == 3 ? 60 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (energia >= 10) {
                                // Creamos el ID dinámico de la lección (leccion_1, leccion_2, leccion_3)
                                String idLeccionActual = 'leccion_$i';

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonScreen(
                                      cursoId: 'ingles',         // El curso siempre es inglés por ahora
                                      unidadId: idUnidad,        // Viene de la base de datos (unidad_1, unidad_2...)
                                      leccionId: idLeccionActual // El número del botón que se toco
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("¡No tienes energía!"), backgroundColor: Colors.red)
                                );
                              }
                            },
                            child: _LessonButton(
                              // Pintamos del color de la unidad
                              color: colorUnidad, 
                              icon: Icons.star,
                              isEnabled: true, // Por ahora todas activas
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// Widget para los botones circulares
class _LessonButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isEnabled;

  const _LessonButton({
    required this.color, 
    required this.icon,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: isEnabled ? color : Colors.grey.shade300,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isEnabled ? color.withOpacity(0.6) : Colors.grey.shade400, 
            offset: const Offset(0, 6),
            blurRadius: 0,
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 35),
    );
  }
}