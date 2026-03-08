import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'presentation/main_wrapper.dart'; //  Importamos el wrapper
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/auth/pantalla_registro.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'data/servicios/poblador_lecciones.dart';
//import 'data/servicios/poblador_grande.dart';


void main() async {
  // asegura que los widgets de Flutter se vinculen antes de iniciar servicios
  WidgetsFlutterBinding.ensureInitialized();
  
  //inicialización de Firebase 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  //debo recordar que solo debo ejecutarla cuando vaya a poblar lecciones
  //await PobladorLecciones().subirLeccionDePrueba();
  //await PobladorMasivo().construirCursoCompleto();

  runApp(const DuolingoCloneApp());
}

class DuolingoCloneApp extends StatelessWidget {
  const DuolingoCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duolingo Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      //home: const MainWrapper(), // Arrancamos con el contenedor de pestañas
      //home: const PantallaRegistro(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // si Firebase tiene datos de usuario, va directo al Mapa
          if (snapshot.hasData) {
            return const MainWrapper();
          }
          // si no hay usuario, va al Registro/Login
          return const PantallaRegistro();
        },
      ),
    );
  }
}