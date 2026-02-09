import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. Avatar y Nombre 
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF58CC02), // Verde Duolingo
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tu Nombre",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "usuario_123",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 2. Estadísticas 
            const Divider(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _StatCard(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  value: "0",
                  label: "Racha",
                ),
                _StatCard(
                  icon: Icons.bolt,
                  color: Colors.blue,
                  value: "531",
                  label: "Total XP",
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            
            // 3. Área de Amigos 
            const Spacer(),
            ElevatedButton(
              onPressed: () {}, 
              child: const Text("AÑADIR AMIGOS", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
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