/// Validador de archivos de audio grabados.
///
/// Realiza validaciones técnicas sobre el archivo WAV para asegurar
/// que cumple con los requisitos mínimos de calidad antes de enviarlo
/// al backend. Las validaciones incluyen:
///
/// 1. Existencia y tamaño del archivo
/// 2. Duración mínima y máxima
/// 3. Detección de silencio (análisis de amplitud RMS)
///
/// La detección de silencio lee los bytes PCM crudos del archivo WAV,
/// calcula el valor RMS (Root Mean Square) de las amplitudes de las
/// muestras, y lo compara con un umbral configurable.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../config/app_config.dart';
import '../models/audio_validation_result.dart';

class AudioValidator {
  /// Valida un archivo de audio WAV en la ruta especificada.
  ///
  /// Ejecuta las validaciones en orden:
  /// 1. Archivo existe
  /// 2. Tamaño > mínimo
  /// 3. Header WAV válido
  /// 4. Duración dentro del rango permitido
  /// 5. No es silencio (amplitud RMS sobre umbral)
  ///
  /// Retorna un [AudioValidationResult] con el diagnóstico completo.
  static Future<AudioValidationResult> validate(String filePath) async {
    final file = File(filePath);

    // ═══════════════════════════════════════════════════════════════════
    // PASO 1: Verificar que el archivo existe
    // ═══════════════════════════════════════════════════════════════════
    if (!await file.exists()) {
      return AudioValidationResult.invalid(
        reason: 'El archivo de audio no se encontró. '
            'Puede que haya un problema con el almacenamiento.',
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // PASO 2: Verificar tamaño mínimo del archivo
    // ═══════════════════════════════════════════════════════════════════
    final fileSize = await file.length();
    if (fileSize < AppConfig.minFileSizeBytes) {
      return AudioValidationResult.invalid(
        reason: 'El archivo de audio está vacío o corrupto. '
            'Por favor, intenta grabar de nuevo.',
        fileSize: fileSize,
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // PASO 3: Leer y parsear el header WAV
    // ═══════════════════════════════════════════════════════════════════
    // Estructura del header WAV (44 bytes):
    // Bytes 0-3:   "RIFF" (identificador)
    // Bytes 4-7:   Tamaño total del archivo - 8
    // Bytes 8-11:  "WAVE" (formato)
    // Bytes 12-15: "fmt " (subchunk1 ID)
    // Bytes 16-19: Tamaño del subchunk1 (16 para PCM)
    // Bytes 20-21: Formato de audio (1 = PCM)
    // Bytes 22-23: Número de canales
    // Bytes 24-27: Sample rate
    // Bytes 28-31: Byte rate
    // Bytes 32-33: Block align
    // Bytes 34-35: Bits per sample
    // Bytes 36-39: "data" (subchunk2 ID)
    // Bytes 40-43: Tamaño de los datos de audio

    final bytes = await file.readAsBytes();

    if (bytes.length < 44) {
      return AudioValidationResult.invalid(
        reason: 'El archivo de audio es demasiado pequeño para ser válido.',
        fileSize: fileSize,
      );
    }

    // Verificar que es un archivo WAV válido (RIFF...WAVE header)
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));

    if (riff != 'RIFF' || wave != 'WAVE') {
      return AudioValidationResult.invalid(
        reason: 'El archivo no es un WAV válido. '
            'Formato detectado: $riff/$wave',
        fileSize: fileSize,
      );
    }

    // Extraer parámetros del header WAV usando ByteData para lectura little-endian
    final byteData = ByteData.sublistView(bytes);
    final numChannels = byteData.getUint16(22, Endian.little);
    final sampleRate = byteData.getUint32(24, Endian.little);
    final bitsPerSample = byteData.getUint16(34, Endian.little);

    // Buscar el chunk "data" (puede no estar exactamente en byte 36)
    int dataOffset = 12; // Empezar después de "WAVE"
    int dataSize = 0;
    bool foundData = false;

    while (dataOffset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
      final chunkSize = byteData.getUint32(dataOffset + 4, Endian.little);

      if (chunkId == 'data') {
        dataSize = chunkSize;
        dataOffset += 8; // Mover al inicio de los datos de audio
        foundData = true;
        break;
      }

      // Saltar al siguiente chunk
      dataOffset += 8 + chunkSize;
    }

    if (!foundData || dataSize == 0) {
      return AudioValidationResult.invalid(
        reason: 'No se encontraron datos de audio en el archivo WAV.',
        fileSize: fileSize,
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // PASO 4: Calcular y verificar duración
    // ═══════════════════════════════════════════════════════════════════
    // Fórmula: duración = dataSize / (sampleRate * channels * bytesPerSample)
    final bytesPerSample = bitsPerSample ~/ 8;
    final duration = dataSize / (sampleRate * numChannels * bytesPerSample);

    if (duration < AppConfig.minDurationSeconds) {
      return AudioValidationResult.invalid(
        reason: 'El audio es muy corto (${duration.toStringAsFixed(1)}s). '
            'La duración mínima es ${AppConfig.minDurationSeconds.toStringAsFixed(0)} segundo(s).',
        duration: duration,
        fileSize: fileSize,
      );
    }

    if (duration > AppConfig.maxDurationSeconds) {
      return AudioValidationResult.invalid(
        reason: 'El audio es muy largo (${duration.toStringAsFixed(1)}s). '
            'La duración máxima es ${AppConfig.maxDurationSeconds.toStringAsFixed(0)} segundos.',
        duration: duration,
        fileSize: fileSize,
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // PASO 5: Detección de silencio mediante análisis RMS
    // ═══════════════════════════════════════════════════════════════════
    // RMS (Root Mean Square) es una medida estándar de la "potencia"
    // de una señal de audio. Para PCM 16-bit:
    //   - Cada muestra es un entero con signo de 16 bits (-32768 a 32767)
    //   - RMS = sqrt(sum(sample^2) / numSamples)
    //   - Un RMS < umbral indica silencio
    final averageAmplitude = _calculateRmsAmplitude(
      bytes,
      dataOffset,
      dataSize,
      bitsPerSample,
    );

    if (averageAmplitude < AppConfig.silenceThresholdRms) {
      return AudioValidationResult.invalid(
        reason: 'No se detectó voz en la grabación. '
            'Asegúrate de hablar cerca del micrófono e intenta de nuevo.',
        duration: duration,
        fileSize: fileSize,
        averageAmplitude: averageAmplitude,
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // TODAS LAS VALIDACIONES PASARON
    // ═══════════════════════════════════════════════════════════════════
    return AudioValidationResult.valid(
      duration: duration,
      fileSize: fileSize,
      averageAmplitude: averageAmplitude,
    );
  }

  /// Calcula la amplitud RMS (Root Mean Square) de los datos PCM.
  ///
  /// Lee las muestras PCM de 16-bit desde [bytes] empezando en [dataOffset],
  /// leyendo [dataSize] bytes. Cada muestra es un entero con signo de 16 bits
  /// almacenado en formato little-endian.
  ///
  /// RMS = sqrt( (1/N) * Σ(sample_i²) )
  ///
  /// Para evitar overflow con muestras grandes, se usa double para la suma.
  static double _calculateRmsAmplitude(
    Uint8List bytes,
    int dataOffset,
    int dataSize,
    int bitsPerSample,
  ) {
    if (bitsPerSample != 16) {
      // Por ahora solo soportamos PCM 16-bit.
      // Para 8-bit u otros formatos, se necesitaría adaptar la lectura.
      return AppConfig.silenceThresholdRms + 1; // Asumir que no es silencio
    }

    final byteData = ByteData.sublistView(bytes);
    final numSamples = dataSize ~/ 2; // 2 bytes por muestra (16-bit)
    double sumSquares = 0.0;
    int validSamples = 0;

    // Leer cada muestra PCM 16-bit (little-endian, signed)
    for (int i = 0; i < numSamples; i++) {
      final offset = dataOffset + (i * 2);

      // Verificar que no nos salimos de los límites del array
      if (offset + 1 >= bytes.length) break;

      // Leer muestra signed 16-bit little-endian
      final sample = byteData.getInt16(offset, Endian.little);

      // Acumular el cuadrado de la muestra
      sumSquares += (sample.toDouble() * sample.toDouble());
      validSamples++;
    }

    if (validSamples == 0) return 0.0;

    // Calcular RMS: raíz cuadrada de la media de los cuadrados
    return sqrt(sumSquares / validSamples);
  }
}
