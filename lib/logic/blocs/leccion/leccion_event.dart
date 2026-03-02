abstract class LeccionEvent {}

// El usuario intenta entrar a la lección
class ComenzarLeccionEvent extends LeccionEvent {
  final String cursoId;
  final String unidadId;
  final String leccionId;
  ComenzarLeccionEvent(this.cursoId, this.unidadId, this.leccionId);
}

// El usuario selecciona una respuesta
class ResponderPreguntaEvent extends LeccionEvent {
  final String respuestaUsuario;
  ResponderPreguntaEvent(this.respuestaUsuario);
}