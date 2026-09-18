/// Servicio para comunicación con la API del backend.
///
/// Maneja dos operaciones principales:
/// 1. Obtener textos pendientes de grabar (GET)
/// 2. Enviar audios grabados (POST multipart)
///
/// Incluye un modo mock para desarrollo sin backend.
library;

import 'dart:math';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/texto_model.dart';

class ApiService {
  late final Dio _dio;

  // ─── Datos Mock ─────────────────────────────────────────────────────
  // Textos de ejemplo en quechua con sus traducciones al español.
  // Se usan cuando AppConfig.useMockData == true.
  static final List<Map<String, dynamic>> _mockTextos = [
    {
      'id': '1',
      'textoQuechua': 'Allillanchu, imaynallan kashkanki?',
      'textoEspanol': '¿Cómo estás, cómo te encuentras?',
    },
    {
      'id': '2',
      'textoQuechua': 'Ñuqap sutiy María, kaypi tiyani.',
      'textoEspanol': 'Mi nombre es María, vivo aquí.',
    },
    {
      'id': '3',
      'textoQuechua': 'Kunanqa intiq ruphayninpi llankashani.',
      'textoEspanol': 'Ahora estoy trabajando bajo el sol.',
    },
    {
      'id': '4',
      'textoQuechua': 'Tayta mamayta munani, paykunaqa allinmi.',
      'textoEspanol': 'Quiero a mis padres, ellos están bien.',
    },
    {
      'id': '5',
      'textoQuechua': 'Kay llaqtapi ashka runakunam kawsanku.',
      'textoEspanol': 'En este pueblo viven muchas personas.',
    },
    {
      'id': '6',
      'textoQuechua': 'Paramunña, yakuqa mayu hina phawarin.',
      'textoEspanol': 'Ya está lloviendo, el agua corre como río.',
    },
    {
      'id': '7',
      'textoQuechua': 'Wasi ukhupi mikhunata waykushani.',
      'textoEspanol': 'Dentro de la casa estoy cocinando comida.',
    },
    {
      'id': '8',
      'textoQuechua': 'Uywakuna chakrapiñam mikhushanku.',
      'textoEspanol': 'Los animales ya están comiendo en la chacra.',
    },
    {
      'id': '9',
      'textoQuechua': 'Paqarinqa fiestam kanqa, tukuy runa hamunanku.',
      'textoEspanol': 'Mañana habrá fiesta, toda la gente debe venir.',
    },
    {
      'id': '10',
      'textoQuechua': 'Ñuqaqa yachay wasiman rinay, yachakunaypaq.',
      'textoEspanol': 'Yo debo ir a la escuela, para aprender.',
    },
  ];

  /// Índice actual del texto mock que se está sirviendo.
  int _mockIndex = 0;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.getTimeoutMs),
      receiveTimeout: Duration(milliseconds: AppConfig.getTimeoutMs),
      sendTimeout: Duration(milliseconds: AppConfig.uploadTimeoutMs),
    ));
  }

  /// Obtiene el siguiente texto pendiente de grabar desde la API.
  ///
  /// En modo mock, devuelve textos de la lista local de ejemplo,
  /// ciclando a través de ellos secuencialmente.
  ///
  /// Throws [Exception] si hay un error de red o el servidor responde
  /// con un código de error.
  Future<TextoModel> getTextoPendiente() async {
    // ── Modo Mock ──
    if (AppConfig.useMockData) {
      // Simular latencia de red
      await Future.delayed(const Duration(milliseconds: 800));

      final textoJson = _mockTextos[_mockIndex % _mockTextos.length];
      _mockIndex++;
      return TextoModel.fromJson(textoJson);
    }

    // ── Modo Real ──
    try {
      final response = await _dio.get(AppConfig.textosPendienteEndpoint);

      if (response.statusCode == 200 && response.data != null) {
        return TextoModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 204) {
        throw Exception('No hay más textos pendientes por grabar.');
      } else {
        throw Exception(
            'Error del servidor: código ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_parseDioError(e));
    }
  }

  /// Envía un audio grabado al backend como multipart/form-data.
  ///
  /// [textoId] - ID del texto asociado al audio.
  /// [audioPath] - Ruta local del archivo de audio a subir.
  /// [onProgress] - Callback opcional para reportar progreso de subida (0.0 a 1.0).
  ///
  /// Retorna true si el envío fue exitoso, false en caso contrario.
  /// Throws [Exception] si hay un error de red.
  Future<bool> enviarAudio(
    String textoId,
    String audioPath, {
    required String textoQuechuaIngresado,
    void Function(double progress)? onProgress,
  }) async {
    // ── Modo Mock ──
    if (AppConfig.useMockData) {
      // Simular subida progresiva
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        onProgress?.call(i / 10);
      }
      // Simular éxito con 95% probabilidad, error con 5%
      if (Random().nextDouble() < 0.05) {
        throw Exception('Error simulado de red (modo mock).');
      }
      return true;
    }

    // ── Modo Real ──
    try {
      final formData = FormData.fromMap({
        'texto_id': textoId,
        'texto_quechua': textoQuechuaIngresado,
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'audio_$textoId.wav',
        ),
      });

      final response = await _dio.post(
        AppConfig.audiosEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(sent / total);
          }
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(_parseDioError(e));
    }
  }

  /// Convierte un [DioException] en un mensaje de error legible para el usuario.
  String _parseDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado. Verifica tu conexión a internet.';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado. El archivo es muy grande o la conexión es lenta.';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. El servidor no responde.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      case DioExceptionType.badResponse:
        return 'Error del servidor: ${e.response?.statusCode ?? "desconocido"}';
      default:
        return 'Error de red: ${e.message ?? "desconocido"}';
    }
  }
}
