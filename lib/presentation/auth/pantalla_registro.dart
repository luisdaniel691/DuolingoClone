import 'package:flutter/material.dart';
import '../../data/repositories/repositorio_autenticacion.dart';
import '../main_wrapper.dart'; 

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final RepositorioAutenticacion _authRepo = RepositorioAutenticacion();
  
  // Esta variable controla si estamos registrandonos o iniciando sesion
  bool _esRegistro = false; 
  bool _cargando = false;
  String? _mensajeError;

  void _autenticarUsuario() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      if (_esRegistro) {
        // MODO REGISTRO
        await _authRepo.registrarUsuario(
          correo: _correoController.text.trim(),
          contrasena: _passController.text.trim(),
        );
      } else {
        // MODO LOGIN 
        await _authRepo.iniciarSesion(
          correo: _correoController.text.trim(),
          contrasena: _passController.text.trim(),
        );
      }

      if (mounted) {
        // Si todo sale bien, vamos al contenedor principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      }
    } catch (e) {
      setState(() {
        // Limpiamos el mensaje de error para que sea legible
        _mensajeError = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // El titulo cambia segun el modo
        title: Text(_esRegistro ? "Crear Perfil" : "Iniciar Sesión"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _esRegistro ? "¡Empieza tu racha!" : "¡Bienvenido de vuelta!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            
            if (_mensajeError != null) ...[
              const SizedBox(height: 10),
              Text(
                _mensajeError!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 30),
            
            // BOTON PRINCIPAL (Verde)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _autenticarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _cargando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _esRegistro ? "CREAR CUENTA" : "ENTRAR", // Texto dinamico
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
            
            const SizedBox(height: 20),

            // BOTON PARA CAMBIAR DE MODO
            TextButton(
              onPressed: () {
                setState(() {
                  _esRegistro = !_esRegistro; // Invertimos el valor (true a false)
                  _mensajeError = null; // Limpiamos errores viejos
                });
              },
              child: Text(
                _esRegistro 
                  ? "¿Ya tienes cuenta? INICIA SESIÓN" 
                  : "¿Nuevo aquí? CREAR CUENTA",
                style: const TextStyle(
                  color: Colors.blue, 
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}