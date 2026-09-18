/// Provider principal que maneja el estado de la pantalla de grabación.
///
/// Implementa una máquina de estados que controla todo el flujo:
/// CargandoTexto → ListoParaGrabar → Grabando → Validando →
/// Revision/ErrorValidacion → Enviando → EnvioExitoso → (siguiente texto)
///
/// Coordina los servicios de API, grabación y validación de audio.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/texto_model.dart';
import '../models/audio_validation_result.dart';
import '../services/api_service.dart';
import '../services/audio_recorder_service.dart';
import '../utils/audio_validator.dart';

/// Estados posibles de la pantalla de grabación.
enum EstadoGrabacion {
  /// Cargando un texto desde la API.
  cargandoTexto,

  /// Error al cargar el texto (problema de red).
  errorTexto,

  /// Texto cargado, listo para iniciar grabación.
  listoParaGrabar,

  /// Grabando audio activamente.
  grabando,

  /// Validando el audio grabado (duración, silencio, etc.).
  validando,

  /// El audio no pasó la validación.
  errorValidacion,

  /// Audio válido, el usuario puede escucharlo y decidir.
  revision,

  /// Enviando el audio al backend.
  enviando,

  /// Error al enviar el audio.
  errorEnvio,

  /// Audio enviado exitosamente.
  envioExitoso,
}

class GrabacionProvider extends ChangeNotifier {
  // ─── Servicios ──────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  final AudioRecorderService _recorderService = AudioRecorderService();

  // ─── Estado ─────────────────────────────────────────────────────────
  EstadoGrabacion _estado = EstadoGrabacion.cargandoTexto;
  TextoModel? _textoActual;
  String? _audioPath;
  AudioValidationResult? _validationResult;
  String? _errorMessage;
  double _progresoEnvio = 0.0;
  String _textoQuechuaIngresado = '';
  Duration _duracionGrabacion = Duration.zero;
  double _amplitudActual = -160.0; // dBFS, mínimo
  int _textosGrabados = 0;

  // Timer para actualizar la duración y amplitud durante la grabación
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  // ─── Getters ────────────────────────────────────────────────────────
  EstadoGrabacion get estado => _estado;
  TextoModel? get textoActual => _textoActual;
  String? get audioPath => _audioPath;
  AudioValidationResult? get validationResult => _validationResult;
  String? get errorMessage => _errorMessage;
  double get progresoEnvio => _progresoEnvio;
  Duration get duracionGrabacion => _duracionGrabacion;
  double get amplitudActual => _amplitudActual;
  int get textosGrabados => _textosGrabados;
  String get textoQuechuaIngresado => _textoQuechuaIngresado;

  void setTextoQuechuaIngresado(String value) {
    _textoQuechuaIngresado = value;
    notifyListeners();
  }

  // ─── Inicialización ─────────────────────────────────────────────────

  /// Carga el primer texto pendiente al iniciar.
  GrabacionProvider() {
    cargarTexto();
  }

  // ─── Acciones del Flujo ─────────────────────────────────────────────

  /// Carga el siguiente texto pendiente desde la API.
  ///
  /// Transiciones: * → CargandoTexto → ListoParaGrabar | ErrorTexto
  Future<void> cargarTexto() async {
    _estado = EstadoGrabacion.cargandoTexto;
    _errorMessage = null;
    _audioPath = null;
    _validationResult = null;
    _progresoEnvio = 0.0;
    _duracionGrabacion = Duration.zero;
    notifyListeners();

    try {
      _textoActual = await _apiService.getTextoPendiente();
      _textoQuechuaIngresado = _textoActual!.textoQuechua;
      _estado = EstadoGrabacion.listoParaGrabar;
    } catch (e) {
      _estado = EstadoGrabacion.errorTexto;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  /// Inicia la grabación de audio.
  ///
  /// Transición: ListoParaGrabar → Grabando
  Future<void> iniciarGrabacion() async {
    if (_textoActual == null) return;

    try {
      _audioPath = await _recorderService.startRecording(_textoActual!.id);
      _estado = EstadoGrabacion.grabando;
      _duracionGrabacion = Duration.zero;
      _recordingStartTime = DateTime.now();

      // Timer que actualiza duración y amplitud cada 100ms
      _recordingTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateRecordingInfo(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _estado = EstadoGrabacion.errorValidacion;
      notifyListeners();
    }
  }

  /// Actualiza la información de la grabación en curso (duración + amplitud).
  Future<void> _updateRecordingInfo() async {
    if (_recordingStartTime != null) {
      _duracionGrabacion = DateTime.now().difference(_recordingStartTime!);
    }

    try {
      final amp = await _recorderService.getAmplitude();
      _amplitudActual = amp.current;
    } catch (_) {
      // Ignorar errores de amplitud (no crítico)
    }

    notifyListeners();
  }

  /// Detiene la grabación y ejecuta la validación del audio.
  ///
  /// Transición: Grabando → Validando → Revision | ErrorValidacion
  Future<void> detenerGrabacion() async {
    // Detener el timer de actualización
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartTime = null;

    _estado = EstadoGrabacion.validando;
    notifyListeners();

    try {
      final path = await _recorderService.stopRecording();

      if (path == null) {
        _estado = EstadoGrabacion.errorValidacion;
        _errorMessage = 'No se pudo obtener el archivo de audio.';
        notifyListeners();
        return;
      }

      _audioPath = path;

      // ── Validar el audio ──
      final result = await AudioValidator.validate(path);
      _validationResult = result;

      if (result.isValid) {
        // Audio válido: ir a revisión para que el usuario escuche
        _estado = EstadoGrabacion.revision;
      } else {
        // Audio inválido: mostrar error y permitir regrabar
        _estado = EstadoGrabacion.errorValidacion;
        _errorMessage = result.errorMessage;

        // Eliminar el archivo inválido
        await _deleteAudioFile(path);
        _audioPath = null;
      }
    } catch (e) {
      _estado = EstadoGrabacion.errorValidacion;
      _errorMessage = 'Error al procesar el audio: ${e.toString()}';
    }

    notifyListeners();
  }

  /// Permite al usuario volver a grabar (descartando el audio actual).
  ///
  /// Transición: Revision | ErrorValidacion → ListoParaGrabar
  Future<void> regrabar() async {
    // Eliminar el archivo de audio anterior si existe
    if (_audioPath != null) {
      await _deleteAudioFile(_audioPath!);
    }

    _audioPath = null;
    _validationResult = null;
    _errorMessage = null;
    _duracionGrabacion = Duration.zero;
    _estado = EstadoGrabacion.listoParaGrabar;
    notifyListeners();
  }

  /// Confirma y envía el audio al backend.
  ///
  /// Transición: Revision → Enviando → EnvioExitoso | ErrorEnvio
  Future<void> confirmarEnvio() async {
    if (_audioPath == null || _textoActual == null) return;

    _estado = EstadoGrabacion.enviando;
    _progresoEnvio = 0.0;
    notifyListeners();

    try {
      final success = await _apiService.enviarAudio(
        _textoActual!.id,
        _audioPath!,
        textoQuechuaIngresado: _textoQuechuaIngresado,
        onProgress: (progress) {
          _progresoEnvio = progress;
          notifyListeners();
        },
      );

      if (success) {
        _textoActual!.estado = EstadoTexto.enviado;
        _textosGrabados++;
        _estado = EstadoGrabacion.envioExitoso;

        // Eliminar el archivo local después de envío exitoso
        await _deleteAudioFile(_audioPath!);
        _audioPath = null;
      } else {
        _estado = EstadoGrabacion.errorEnvio;
        _errorMessage = 'El servidor no aceptó el audio. Intenta de nuevo.';
      }
    } catch (e) {
      _estado = EstadoGrabacion.errorEnvio;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  /// Reintenta el envío del audio al backend.
  ///
  /// Transición: ErrorEnvio → Enviando
  Future<void> reintentarEnvio() async {
    await confirmarEnvio();
  }

  /// Carga el siguiente texto después de un envío exitoso.
  ///
  /// Transición: EnvioExitoso → CargandoTexto
  Future<void> siguienteTexto() async {
    await cargarTexto();
  }

  // ─── Utilidades ─────────────────────────────────────────────────────

  /// Elimina un archivo de audio del almacenamiento local.
  Future<void> _deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // No es crítico si falla la eliminación
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderService.dispose();
    super.dispose();
  }
}
