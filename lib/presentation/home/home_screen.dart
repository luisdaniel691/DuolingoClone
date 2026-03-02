import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de datos
import 'package:firebase_auth/firebase_auth.dart'; // Autenticación
import '../lesson/lesson_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // obtenemos el ID del usuario actual
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    // si por alguna razón no hay usuario, mostramos carga
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // envolvemos todo el Scaffold en un StreamBuilder
    // esto hace que la pantalla se redibuje sola si cambia la energía o XP
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snapshot) {
        
        // Variables por defecto (mientras carga)
        int energia = 0;
        int xp = 0;
        // La racha la dejamos estática de mientrass
        int racha = 0; 

        // Si ya descargó datos, actualizamos las variables
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          energia = data['energia'] ?? 0;
          xp = data['xp_total'] ?? 0;
          racha = data['racha_dias'] ?? 0;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1, // Sombra suave
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bandera (Estática por ahora)
                const Icon(Icons.flag, color: Colors.grey, size: 30),
                
                // Racha (Fuego) 
                Row(children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  Text(" $racha", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))
                ]),
                
                // XP (Rayo) - DATO REAL
                Row(children: [
                  const Icon(Icons.bolt, color: Colors.blue), // Usamos Bolt para XP temporalmente o Estrella
                  Text(" $xp XP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                ]),

                // ENERGÍA (Corazón) - DATO REAL
                Row(children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  Text(" $energia", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                ]),
              ],
            ),
          ),
          
          // El cuerpo del mapa
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 5, 
            itemBuilder: (context, index) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Validamos si tiene energía antes de dejarlo ir a la pantalla
                      if (energia > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LessonScreen()),
                        );
                      } else {
                        // Mensaje si no tiene energía
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("¡No tienes suficiente energía!"),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    },
                    child: _LessonButton(
                      // Pinta verde solo el primero, gris los demás (Lógica temporal)
                      color: index == 0 ? const Color(0xFF58CC02) : Colors.grey,
                      icon: Icons.star,
                      isEnabled: index == 0, // Solo el primero brilla
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Decoración en zig-zag
                  Padding(
                    padding: EdgeInsets.only(
                      left: index % 2 == 0 ? 40 : 0, 
                      right: index % 2 != 0 ? 40 : 0
                    ),
                    child: _LessonButton(
                      color: Colors.grey.shade300, 
                      icon: Icons.lock,
                      isEnabled: false,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _LessonButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isEnabled; // Para saber si le ponemos sombra bonita o no

  const _LessonButton({
    required this.color, 
    required this.icon,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // Sombra inferior para efecto 3D 
        boxShadow: [
          BoxShadow(
            color: isEnabled ? Colors.green.shade800 : Colors.grey.shade500, 
            offset: const Offset(0, 6),
            blurRadius: 0, // Borde duro tipo caricatura
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 40),
    );
  }
}