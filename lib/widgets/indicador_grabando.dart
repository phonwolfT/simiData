/// Indicador visual de grabación en progreso.
///
/// Muestra:
/// 1. Barras de amplitud animadas que responden al nivel de audio del micrófono
/// 2. Un temporizador (MM:SS) que se actualiza en tiempo real
/// 3. Un punto rojo parpadeante indicando "REC"
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndicadorGrabando extends StatefulWidget {
  /// Duración actual de la grabación.
  final Duration duracion;

  /// Amplitud actual del micrófono (en dBFS, típicamente -160 a 0).
  final double amplitudDb;

  const IndicadorGrabando({
    super.key,
    required this.duracion,
    required this.amplitudDb,
  });

  @override
  State<IndicadorGrabando> createState() => _IndicadorGrabandoState();
}

class _IndicadorGrabandoState extends State<IndicadorGrabando>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  // Historial de amplitudes para las barras (últimas N muestras)
  final List<double> _amplitudeHistory = List.filled(30, 0.0);
  int _historyIndex = 0;

  @override
  void initState() {
    super.initState();
    // Animación de parpadeo para el indicador "REC"
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(IndicadorGrabando oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Agregar nueva amplitud al historial
    if (widget.amplitudDb != oldWidget.amplitudDb) {
      // Normalizar amplitud de dBFS (-160..0) a 0..1
      final normalized = _normalizeAmplitude(widget.amplitudDb);
      _amplitudeHistory[_historyIndex % _amplitudeHistory.length] = normalized;
      _historyIndex++;
    }
  }

  /// Normaliza la amplitud de dBFS a un rango de 0.0 a 1.0.
  /// -160 dBFS → 0.0 (silencio total)
  /// 0 dBFS → 1.0 (máximo)
  double _normalizeAmplitude(double dbFs) {
    // Clampear el rango
    final clamped = dbFs.clamp(-60.0, 0.0);
    // Mapear linealmente de [-60, 0] a [0, 1]
    return (clamped + 60) / 60;
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE53935).withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador REC parpadeante + temporizador
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _blinkController,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'REC',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDuration(widget.duracion),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barras de amplitud
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _AmplitudePainter(
                amplitudes: List.from(_amplitudeHistory),
                color: const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter para dibujar barras de amplitud.
class _AmplitudePainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _AmplitudePainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = amplitudes.length;
    final barWidth = size.width / (barCount * 2 - 1);
    final maxHeight = size.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      // Altura de la barra (mínimo 3px para que siempre se vea algo)
      final amplitude = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = max(3.0, amplitude * maxHeight);

      // Gradiente de color: más intenso cuanto más alta la amplitud
      final opacity = (0.3 + amplitude * 0.7).clamp(0.0, 1.0);
      paint.color = color.withAlpha((opacity * 255).toInt());

      // Posición centrada verticalmente
      final x = i * barWidth * 2;
      final y = (maxHeight - barHeight) / 2;

      // Dibujar barra con bordes redondeados
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmplitudePainter oldDelegate) => true;
}
