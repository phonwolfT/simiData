/// Resultado de la validación de un archivo de audio grabado.
///
/// Contiene información detallada sobre si el audio es válido para ser
/// enviado al backend, incluyendo el motivo de rechazo si no lo es,
/// y métricas técnicas del audio (duración, tamaño, amplitud).
library;

class AudioValidationResult {
  /// Indica si el audio pasó todas las validaciones.
  final bool isValid;

  /// Mensaje descriptivo del error si el audio no es válido.
  /// null si el audio es válido.
  final String? errorMessage;

  /// Duración del audio en segundos (calculada desde el header WAV).
  final double? duration;

  /// Tamaño del archivo en bytes.
  final int? fileSize;

  /// Amplitud RMS promedio del audio.
  /// Valores bajos indican silencio o audio vacío.
  final double? averageAmplitude;

  const AudioValidationResult({
    required this.isValid,
    this.errorMessage,
    this.duration,
    this.fileSize,
    this.averageAmplitude,
  });

  /// Resultado exitoso de validación.
  factory AudioValidationResult.valid({
    required double duration,
    required int fileSize,
    required double averageAmplitude,
  }) {
    return AudioValidationResult(
      isValid: true,
      duration: duration,
      fileSize: fileSize,
      averageAmplitude: averageAmplitude,
    );
  }

  /// Resultado fallido de validación con motivo.
  factory AudioValidationResult.invalid({
    required String reason,
    double? duration,
    int? fileSize,
    double? averageAmplitude,
  }) {
    return AudioValidationResult(
      isValid: false,
      errorMessage: reason,
      duration: duration,
      fileSize: fileSize,
      averageAmplitude: averageAmplitude,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'AudioValidation: VÁLIDO '
          '(duración: ${duration?.toStringAsFixed(1)}s, '
          'tamaño: ${fileSize}B, '
          'amplitud: ${averageAmplitude?.toStringAsFixed(0)})';
    }
    return 'AudioValidation: INVÁLIDO - $errorMessage';
  }
}
