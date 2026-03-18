import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/repositorio_usuario.dart';
import '../auth/pantalla_registro.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RepositorioUsuario _repoUsuario = RepositorioUsuario();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;


  

  // Función para mostrar la ventana de edición
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

  
    final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarDeGaleria() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (imagen != null) {
      Navigator.pop(context); // Cierra el modal
      await _repoUsuario.actualizarFotoPerfil(File(imagen.path));
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (imagen != null) {
      Navigator.pop(context);
      await _repoUsuario.actualizarFotoPerfil(File(imagen.path));
    }
  }

  void _seleccionarAvatarLocal(String ruta) async {
    Navigator.pop(context);
    await _repoUsuario.actualizarAvatarLocal(ruta);
  }

// El Modal
  void _mostrarOpcionesAvatar() {
    // Lista de avatares locales ( carpeta assets/avatares)
    final List<String> avataresLocales = [
      'assets/avatares/oso_estudiante.png',
      'assets/avatares/oso_cafe.png',
      'assets/avatares/oso_premio.png',
      'assets/avatares/oso_creativo.png',

    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea( 
          child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Cambiar foto de perfil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotonAccionAvatar(icono: Icons.camera_alt, texto: "Cámara", onTap: _tomarFoto),
                  _BotonAccionAvatar(icono: Icons.photo_library, texto: "Galería", onTap: _seleccionarDeGaleria),
                ],
              ),
              const Divider(height: 30),
              const Text("Elige un avatar:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Carrusel de avatares locales
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: avataresLocales.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _seleccionarAvatarLocal(avataresLocales[index]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 15),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: AssetImage(avataresLocales[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
        // Cargando
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
        final String apellido = data['apellido'] ?? ""; 
        final String usuario = data['correo'] ?? "usuario";
        final int xp = data['xp_total'] ?? 0;
        final int racha = data['racha_dias'] ?? 0;
        final String? fotoUrl = data['foto_perfil'];
        final bool esAvatarLocal = data['es_avatar_local'] ?? false;
        final List<dynamic> logrosDesbloqueados = data['logros_desbloqueados'] ?? [];

        return Scaffold(
          resizeToAvoidBottomInset: false,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar y Nombre Real
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.blue.shade300,
                      backgroundImage: fotoUrl != null
                          ? (esAvatarLocal
                              ? AssetImage(fotoUrl) as ImageProvider
                              : NetworkImage(fotoUrl))
                          : null,
                      child: fotoUrl == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.white) 
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 5,
                      child: GestureDetector(
                        onTap: _mostrarOpcionesAvatar, // llama al modal
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
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
                
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Tus Logros", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),
                
                // Carrusel horizontal de logros
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.center, // Centra las medallas
                    spacing: 15, // Espacio horizontal entre medallas
                    runSpacing: 20, // Espacio vertical (cuando bajan de renglón)
                    children: [
                      _MedallaLogro(
                        titulo: "Primeros\npasos", 
                        icono: Icons.directions_walk, 
                        colorActivo: Colors.green, 
                        estaDesbloqueado: logrosDesbloqueados.contains('primeros_pasos'),
                        descripcion: "Completa tu primera lección para ganar esta medalla.",
                      ),
                      _MedallaLogro(
                        titulo: "Fuego\ninicial", 
                        icono: Icons.local_fire_department, 
                        colorActivo: Colors.orange, 
                        estaDesbloqueado: logrosDesbloqueados.contains('fuego_inicial'),
                        descripcion: "Mantén una racha de aprendizaje por 3 días consecutivos.",
                      ),
                      _MedallaLogro(
                        titulo: "Mente\nbrillante", 
                        icono: Icons.lightbulb, 
                        colorActivo: Colors.amber, 
                        estaDesbloqueado: logrosDesbloqueados.contains('mente_brillante'),
                        descripcion: "Acumula un total de 1000 puntos de Experiencia (XP).",
                      ),
                      _MedallaLogro(
                        titulo: "Modo\nmaratón", 
                        icono: Icons.timer, 
                        colorActivo: Colors.purple, 
                        estaDesbloqueado: logrosDesbloqueados.contains('modo_maraton'),
                        descripcion: "Completa 5 lecciones en un solo día.",
                      ),
                      _MedallaLogro(
                        titulo: "Personali-\nzando", 
                        icono: Icons.face, 
                        colorActivo: Colors.blue, 
                        estaDesbloqueado: logrosDesbloqueados.contains('personalizando'),
                        descripcion: "Cambia tu foto de avatar por primera vez.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
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

// Widget para las tarjetas de estadísticas
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

// Widget para los botones de Cámara y Galería en el Modal
class _BotonAccionAvatar extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _BotonAccionAvatar({required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade50, child: Icon(icono, color: Colors.blue)),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}


// Widget para diseñar cada medalla de logro
class _MedallaLogro extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorActivo;
  final bool estaDesbloqueado;
  final String descripcion;

  const _MedallaLogro({
    required this.titulo,
    required this.icono,
    required this.colorActivo,
    required this.estaDesbloqueado,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Muestra una ventana con la descripción al tocar la medalla
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            // Reemplazamos los saltos de línea por espacios para el título del modal
            title: Text(titulo.replaceAll('\n', ' '), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono, 
                  size: 60, 
                  color: estaDesbloqueado ? colorActivo : Colors.grey.shade400
                ),
                const SizedBox(height: 15),
                
                Text(
                  descripcion, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 16)
                ),                
                const SizedBox(height: 15),
                Text(
                  estaDesbloqueado ? "¡Logro Desbloqueado!" : "Aún bloqueado",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: estaDesbloqueado ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        );
      },
      child: SizedBox(
        width: 90, // ancho para que quepan 3 por renglón
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: estaDesbloqueado ? colorActivo.withOpacity(0.15) : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: estaDesbloqueado ? colorActivo : Colors.grey.shade400,
                  width: 3,
                ),
              ),
              child: Icon(
                icono,
                size: 35,
                color: estaDesbloqueado ? colorActivo : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: estaDesbloqueado ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}