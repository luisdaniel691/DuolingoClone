import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../lesson/lesson_screen.dart';



import 'package:lottie/lottie.dart';

import '../lesson/pantalla_carga_leccion.dart';

import '../../data/repositories/repositorio_lecciones.dart';



class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});



  @override

  Widget build(BuildContext context) {

    final String? uid = FirebaseAuth.instance.currentUser?.uid;



    if (uid == null) {

      return Scaffold(body: Center(child: Lottie.asset('assets/animaciones/cargando.json', width: 150)));

    }

   

    RepositorioLecciones().sincronizarEnergiaVisible();

    RepositorioLecciones().verificarRachaPerdida();



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

            future: FirebaseFirestore.instance.collection('cursos').doc('ingles').collection('unidades').orderBy('orden').get(),

            builder: (context, snapshotUnidades) {

             

              //verificamos si hay error de internet 

              if (snapshotUnidades.hasError) {

                return Center(

                  child: Padding(

                    padding: const EdgeInsets.all(20.0),

                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        // animación de error

                        Lottie.asset('assets/animaciones/error.json', width: 200),

                        const SizedBox(height: 20),

                        const Text(

                          "¡Ups! Problemas de conexión",

                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),

                          textAlign: TextAlign.center,

                        ),

                        const SizedBox(height: 10),

                        const Text(

                          "Parece que no tienes internet o nuestros servidores están tomando una siesta. Revisa tu conexión y vuelve a intentarlo.",

                          style: TextStyle(fontSize: 16, color: Colors.grey),

                          textAlign: TextAlign.center,

                        ),

                        const SizedBox(height: 30),

                        // Botón para recargar la pantalla

                        ElevatedButton.icon(

                          onPressed: () {

                            // Esto fuerza a la pantalla a redibujarse y volver a intentar

                            (context as Element).markNeedsBuild();

                          },

                          icon: const Icon(Icons.refresh),

                          label: const Text("REINTENTAR", style: TextStyle(fontWeight: FontWeight.bold)),

                          style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.blue,

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))

                          ),

                        )

                      ],

                    ),

                  ),

                );

              }



              //si no hay error verificamos que este cargando 

              if (!snapshotUnidades.hasData) {

                return Center(child: Lottie.asset('assets/animaciones/cargando.json', width: 150));

              }



              // si todo esta bien dibujamos el mapa

              final unidades = snapshotUnidades.data!.docs;





              return ListView.builder(

                itemCount: unidades.length,

                itemBuilder: (context, indiceUnidad) {

                  final datosUnidad = unidades[indiceUnidad].data() as Map<String, dynamic>;

                  final idUnidad = unidades[indiceUnidad].id;

                  final colorUnidad = Color(int.parse(datosUnidad['color'].replaceAll('#', '0xff')));

                 

                  // Lógica para alternar las mascotas: Unidad 1 tiene mascota 1, Unidad 2 tiene mascota 2, etc.

                  final String rutaAnimacion = (indiceUnidad % 2 == 0)

                      ? 'assets/animaciones/mascota1_mapa.json'

                      : 'assets/animaciones/mascota2_mapa.json';



                  return Column(

                    children: [

                      //  EL BLOQUE DE LA UNIDAD CON LA MASCOTA

                      Stack(

                        clipBehavior: Clip.none, // Permite que la mascota sobresalga del cuadro

                        children: [

                          Container(

                            width: double.infinity,

                            margin: const EdgeInsets.only(left: 15, right: 15, top: 40, bottom: 20),

                            padding: const EdgeInsets.all(20),

                            decoration: BoxDecoration(

                              color: colorUnidad,

                              borderRadius: BorderRadius.circular(15),

                            ),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  datosUnidad['titulo'].toUpperCase(),

                                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)

                                ),

                                const SizedBox(height: 5),

                                SizedBox(

                                  width: MediaQuery.of(context).size.width * 0.6, // Evita que el texto choque con la mascota

                                  child: Text(

                                    datosUnidad['subtitulo'],

                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)

                                  ),

                                ),

                              ],

                            ),

                          ),

                          // LA MASCOTA POSICIONADA EN LA ESQUINA DERECHA

                          Positioned(

                            top: 5, // Sube la mascota sobre el contenedor

                            right: 20,

                            child: Lottie.asset(rutaAnimacion, width: 110, height: 110),

                          ),

                        ],

                      ),

                     

                      // LAS 3 LECCIONES (En Zig-Zag)

                      for (int i = 1; i <= 3; i++)

                        Padding(

                          padding: EdgeInsets.only(

                            bottom: 20,

                            left: i == 1 ? 0 : (i == 2 ? 60 : 0),

                            right: i == 3 ? 60 : 0,

                          ),

                          child: GestureDetector(

                            onTap: () {

                              if (energia >= 1) {

                                String idLeccionActual = 'leccion_$i';

                                Navigator.push(

                                  context,

                                  MaterialPageRoute(

                                    builder: (context) => PantallaCargaLeccion(

                                      cursoId: 'ingles',

                                      unidadId: idUnidad,

                                      leccionId: idLeccionActual

                                    ),

                                  ),

                                );

                              } else {

                                mostrarDialogoSinEnergia(context);

                              }

                            },

                            child: _LessonButton(

                              // Pintamos del color de la unidad

                              color: colorUnidad,

                              icon: Icons.star,

                              isEnabled: true, //  todas activas

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





void mostrarDialogoSinEnergia(BuildContext context) {

  showDialog(

    context: context,

    builder: (context) => AlertDialog(

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      content: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          Lottie.asset('assets/animaciones/sin_vidas.json', width: 150),

          const SizedBox(height: 15),

          const Text(

            "¡Te quedaste sin energía!",

            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),

            textAlign: TextAlign.center

          ),

          const SizedBox(height: 10),

          const Text(

            "Vuelve más tarde para seguir aprendiendo o revisa tus apuntes.",

            textAlign: TextAlign.center,

            style: TextStyle(fontSize: 16),

          ),

        ],

      ),

      actionsAlignment: MainAxisAlignment.center,

      actions: [

        ElevatedButton(

          onPressed: () => Navigator.pop(context),

          style: ElevatedButton.styleFrom(

            backgroundColor: Colors.red,

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))

          ),

          child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

        )

      ],

    ),

  );

}