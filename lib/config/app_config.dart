/// Configuración global de la aplicación SimiData.
///
/// Centraliza todas las constantes configurables: URL de la API,
/// umbrales de validación de audio, y parámetros de grabación.
library;

class AppConfig {
  // ─── API ──────────────────────────────────────────────────────────────
  /// URL base de la API. Cambiar cuando se tenga el backend real.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Endpoint para obtener el siguiente texto pendiente de grabar.
  static const String textosPendienteEndpoint = '/api/data/';

  /// Endpoint base para enviar el audio grabado (se añadirá el ID).
  static const String audiosEndpoint = '/api/data/';

  // ─── Validación de Audio ──────────────────────────────────────────────
  /// Duración mínima permitida para un audio (en segundos).
  static const double minDurationSeconds = 1.0;

  /// Duración máxima permitida para un audio (en segundos).
  static const double maxDurationSeconds = 60.0;

  /// Tamaño mínimo del archivo de audio (en bytes).
  /// Un WAV de 1 segundo a 44100 Hz mono 16-bit = ~88 KB.
  static const int minFileSizeBytes = 1000;

  /// Umbral de amplitud RMS promedio para detectar silencio.
  /// Para PCM 16-bit (rango -32768 a 32767), un valor RMS < 200
  /// indica que el audio es esencialmente silencio.
  static const double silenceThresholdRms = 200.0;

  // ─── Parámetros de Grabación ──────────────────────────────────────────
  /// Frecuencia de muestreo (44100 Hz es estándar de calidad CD).
  static const int sampleRate = 44100;

  /// Número de canales (1 = mono, suficiente para voz).
  static const int numChannels = 1;

  /// Bits por muestra (16-bit es estándar para PCM).
  static const int bitsPerSample = 16;

  // ─── Modo Mock ────────────────────────────────────────────────────────
  /// Si es true, usa datos locales simulados en lugar de la API real.
  /// Activar durante desarrollo sin backend.
  static const bool useMockData = false;

  // ─── Timeouts ─────────────────────────────────────────────────────────
  /// Timeout para peticiones GET (en milisegundos).
  static const int getTimeoutMs = 15000;

  /// Timeout para subida de archivos (en milisegundos).
  static const int uploadTimeoutMs = 120000;
}
