import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0; // 0 = Home, 1 = Perfil

  // Lista de las pantallas principales
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El cuerpo cambia según el índice seleccionado
      body: _screens[_currentIndex],
      
      // La barra de navegación inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Actualiza la pantalla
          });
        },
        selectedItemColor: const Color(0xFF58CC02), 
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,  
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 30),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face, size: 30),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}