# Arquitectura de ConMigo

La aplicación **ConMigo** sigue una arquitectura limpia (Clean Architecture) dividida en capas para asegurar la escalabilidad y el mantenimiento del código.

## Capas del Proyecto

1. **Capa de Datos (Data):** 
   - Implementación de **Repositories** que gestionan la comunicación directa con Firebase Firestore y Firebase Auth.
   - Centraliza las peticiones para evitar duplicidad de código.

2. **Capa de Lógica (Logic):** 
   - Se utilizo el patron **BLoC (Business Logic Component)** para separar la interfaz de usuario de la lógica de negocio.
   - Los estados de las lecciones (Cargando, En Progreso, Error) se manejan mediante eventos asíncronos.

3. **Capa de Presentación (Presentation):** 
   - Widgets de Flutter optimizados para una experiencia de usuario fluida.
   - Uso de **BlocBuilder** y **BlocConsumer** para reaccionar a los cambios de estado en tiempo real.

## Backend y Persistencia
- **Firebase Firestore:** Base de datos NoSQL para el almacenamiento de lecciones y progreso del usuario.
- **Firebase Auth:** Gestión de sesiones y perfiles.
- **Estrategia Online-First:** Manejo estricto de conexión con *timeouts* de 3 segundos para garantizar la integridad de los datos en la nube.