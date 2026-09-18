/// Modelo de datos para los textos en quechua que deben ser grabados.
///
/// Cada [TextoModel] representa un texto obtenido del backend que el
/// usuario debe leer en voz alta y grabar. Incluye el texto en quechua
/// (principal) y una traducción al español (referencia).
library;

/// Estados posibles de un texto en el flujo de grabación.
enum EstadoTexto {
  /// El texto aún no ha sido grabado.
  pendiente,

  /// El audio fue grabado localmente pero no se ha enviado al backend.
  grabado,

  /// El audio fue enviado exitosamente al backend.
  enviado,
}

class TextoModel {
  /// Identificador único del texto (asignado por el backend).
  final String id;

  /// Texto en quechua que debe ser leído en voz alta.
  final String textoQuechua;

  /// Traducción al español del texto (referencia para el usuario).
  final String textoEspanol;

  /// Estado actual del texto en el flujo de grabación.
  EstadoTexto estado;

  TextoModel({
    required this.id,
    required this.textoQuechua,
    required this.textoEspanol,
    this.estado = EstadoTexto.pendiente,
  });

  /// Crea un [TextoModel] desde un mapa JSON recibido de la API.
  ///
  /// Espera la estructura:
  /// ```json
  /// {
  ///   "id": "123" | 123,
  ///   "textoQuechua": "Allillanchu",
  ///   "textoEspanol": "¿Cómo estás?"
  /// }
  /// ```
  factory TextoModel.fromJson(Map<String, dynamic> json) {
    return TextoModel(
      // Soporta tanto int como String para el ID
      id: json['id'].toString(),
      textoQuechua: json['textoQuechua'] as String? ?? '',
      textoEspanol: json['textoEspanol'] as String? ?? '',
      estado: EstadoTexto.pendiente,
    );
  }

  /// Convierte el modelo a un mapa JSON (útil para almacenamiento local).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textoQuechua': textoQuechua,
      'textoEspanol': textoEspanol,
      'estado': estado.name,
    };
  }

  @override
  String toString() =>
      'TextoModel(id: $id, quechua: "$textoQuechua", español: "$textoEspanol")';
}
