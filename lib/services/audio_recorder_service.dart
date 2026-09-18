/// Servicio wrapper para la grabación de audio.
///
/// Encapsula el paquete `record` proporcionando una interfaz limpia
/// para iniciar/detener grabaciones y monitorear amplitud en tiempo real.
/// Graba en formato WAV (PCM 16-bit) para máxima calidad y facilidad
/// de análisis posterior.
library;

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

class AudioRecorderService {
  /// Instancia del grabador del paquete `record`.
  AudioRecorder? _recorder;

  /// Ruta del último archivo grabado.
  String? _lastRecordingPath;

  /// Indica si actualmente se está grabando.
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get lastRecordingPath => _lastRecordingPath;

  /// Inicializa el grabador si no está creado.
  void _ensureRecorder() {
    _recorder ??= AudioRecorder();
  }

  /// Solicita permiso de micrófono al usuario.
  ///
  /// Retorna true si el permiso fue concedido, false en caso contrario.
  /// Maneja el caso de permiso permanentemente denegado.
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // El usuario denegó permanentemente: debe ir a configuración
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Verifica si el permiso de micrófono está concedido.
  Future<bool> hasPermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Inicia la grabación de audio en formato WAV.
  ///
  /// [textoId] se usa para nombrar el archivo de forma única.
  /// El archivo se guarda en el directorio temporal del dispositivo.
  ///
  /// Throws [Exception] si no hay permiso o si ya se está grabando.
  Future<String> startRecording(String textoId) async {
    _ensureRecorder();

    // Verificar permiso
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception(
          'Permiso de micrófono denegado. '
          'Habilítalo en la configuración del dispositivo.',
        );
      }
    }

    // Verificar que no se esté grabando ya
    if (_isRecording) {
      throw Exception('Ya se está grabando. Detén la grabación actual primero.');
    }

    // Obtener directorio temporal y crear ruta del archivo
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/simi_audio_${textoId}_$timestamp.wav';

    // Configurar y empezar la grabación en WAV (PCM 16-bit)
    const config = RecordConfig(
      encoder: AudioEncoder.wav, // WAV sin compresión
      sampleRate: AppConfig.sampleRate, // 44100 Hz
      numChannels: AppConfig.numChannels, // Mono
      bitRate: 128000,
    );

    await _recorder!.start(config, path: filePath);
    _isRecording = true;
    _lastRecordingPath = filePath;

    return filePath;
  }

  /// Detiene la grabación actual y retorna la ruta del archivo grabado.
  ///
  /// Retorna null si no se estaba grabando.
  Future<String?> stopRecording() async {
    if (!_isRecording || _recorder == null) {
      return null;
    }

    final path = await _recorder!.stop();
    _isRecording = false;
    return path ?? _lastRecordingPath;
  }

  /// Obtiene la amplitud actual del micrófono.
  ///
  /// Útil para visualizar ondas de audio en la UI durante la grabación.
  /// Retorna un valor de amplitud (en dBFS). Valores típicos:
  /// - Silencio: -60 a -40 dB
  /// - Voz normal: -30 a -10 dB
  /// - Voz fuerte: -10 a 0 dB
  Future<Amplitude> getAmplitude() async {
    if (_recorder == null || !_isRecording) {
      return Amplitude(current: -160.0, max: -160.0);
    }
    return await _recorder!.getAmplitude();
  }

  /// Libera los recursos del grabador.
  ///
  /// Debe llamarse cuando el servicio ya no se necesita (en dispose del provider).
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder?.dispose();
    _recorder = null;
  }
}
