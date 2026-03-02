import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/repositorio_usuario.dart';
import '../auth/pantalla_registro.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RepositorioUsuario _repoUsuario = RepositorioUsuario();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // Función para mostrar la ventanita de edición
  void _mostrarDialogoEditar(String nombreActual, String apellidoActual) {
    final TextEditingController nombreController = TextEditingController(text: nombreActual);
    final TextEditingController apellidoController = TextEditingController(text: apellidoActual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: "Apellido"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cerrar sin guardar
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Guardar en Firebase
                await _repoUsuario.actualizarPerfil(
                  nombreController.text.trim(),
                  apellidoController.text.trim(),
                );
                if (mounted) Navigator.pop(context); // Cerrar al terminar
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
              child: const Text("Guardar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay usuario logueado mostramos error
    if (uid == null) return const Center(child: Text("No hay sesión activa"));

    // StreamBuilder: Escucha cambios en tiempo real en el documento del usuario
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // Cargando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hay error
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar perfil"));
        }

        // Obtener los datos
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Usuario no encontrado en base de datos"));
        }

        // Extraemos los datos del JSON de Firebase
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String nombre = data['nombre'] ?? "Sin Nombre";
        final String apellido = data['apellido'] ?? ""; // Puede estar vacío al principio
        final String usuario = data['correo'] ?? "usuario";
        final int xp = data['xp_total'] ?? 0;
        final int racha = data['racha_dias'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Perfil"),
            actions: [
              // BOTÓN DE CONFIGURACIÓN
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _mostrarDialogoEditar(nombre, apellido),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar y Nombre Real
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF58CC02),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  "$nombre $apellido", // Mostramos nombre y apellido
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  usuario, // Mostramos el correo o usuario
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Estadísticas reales que vienen de Firebase
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                      value: racha.toString(),
                      label: "Racha",
                    ),
                    _StatCard(
                      icon: Icons.bolt,
                      color: Colors.blue,
                      value: xp.toString(),
                      label: "Total XP",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                
                const Spacer(),
                
                // Botón Cerrar Sesión
                // Botón Cerrar Sesión con Redirección
                TextButton(
                  onPressed: () async {
                    // Cerrar sesión en Firebase
                    await FirebaseAuth.instance.signOut();

                    // Verificar que el widget siga vivo antes de navegar
                    if (!context.mounted) return;

                    // Borra todo el historial y va al Login
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const PantallaRegistro()),
                      (Route<dynamic> route) => false, // Esto borra las pantallas anteriores
                    );
                  },
                  child: const Text(
                    "CERRAR SESIÓN", 
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                  )
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget pequeño para las tarjetas de estadísticas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}