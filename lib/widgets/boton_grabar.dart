/// Botón animado para iniciar y detener la grabación de audio.
///
/// Cambia visualmente entre dos estados:
/// - "Grabar" (verde con ícono de micrófono)
/// - "Detener" (rojo con ícono de stop)
///
/// Incluye una animación de pulso cuando está disponible para grabar
/// y feedback háptico al presionar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BotonGrabar extends StatefulWidget {
  /// Si es true, muestra el botón en modo "Detener" (rojo).
  /// Si es false, muestra en modo "Grabar" (verde).
  final bool isRecording;

  /// Callback cuando se presiona el botón.
  final VoidCallback onPressed;

  /// Si es true, el botón está deshabilitado.
  final bool disabled;

  const BotonGrabar({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  State<BotonGrabar> createState() => _BotonGrabarState();
}

class _BotonGrabarState extends State<BotonGrabar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de pulso (anillo que se expande cuando está listo para grabar)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Repetir el pulso solo cuando NO está grabando
    if (!widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }

    // Animación de escala al presionar
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BotonGrabar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !oldWidget.isRecording) {
      // Empezó a grabar: detener pulso
      _pulseController.stop();
      _pulseController.reset();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      // Dejó de grabar: reanudar pulso
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (widget.disabled) return;

    // Feedback háptico
    HapticFeedback.mediumImpact();

    // Animación de presión
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isRec = widget.isRecording;

    // Colores según estado
    final primaryColor = isRec
        ? const Color(0xFFE53935) // Rojo para detener
        : const Color(0xFF43A047); // Verde para grabar
    final shadowColor = primaryColor.withAlpha(80);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón principal con anillo de pulso
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Anillo de pulso (solo cuando no está grabando)
                  if (!isRec)
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withAlpha(
                                (60 * (1.3 - _pulseAnimation.value)).toInt()),
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                  // Botón circular
                  GestureDetector(
                    onTap: widget.disabled ? null : _handlePress,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.disabled
                            ? Colors.grey.shade400
                            : primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.disabled
                                ? Colors.transparent
                                : shadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isRec ? Icons.stop_rounded : Icons.mic_rounded,
                          key: ValueKey(isRec),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // Etiqueta
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isRec ? 'Toca para detener' : 'Toca para grabar',
            key: ValueKey(isRec),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isRec
                  ? const Color(0xFFE53935)
                  : Theme.of(context).colorScheme.onSurface.withAlpha(160),
            ),
          ),
        ),
      ],
    );
  }
}
