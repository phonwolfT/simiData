/// Widget para mostrar el estado del envío de audio al backend.
///
/// Maneja tres estados visuales:
/// 1. Enviando: barra de progreso circular con porcentaje
/// 2. Éxito: ícono de check animado con mensaje de confirmación
/// 3. Error: mensaje de error con botón de reintentar
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstadoEnvio extends StatefulWidget {
  /// Estado actual: 'enviando', 'exito', o 'error'.
  final String estado;

  /// Progreso de envío (0.0 a 1.0), solo relevante cuando estado == 'enviando'.
  final double progreso;

  /// Mensaje de error, solo relevante cuando estado == 'error'.
  final String? errorMessage;

  /// Callback para reintentar el envío.
  final VoidCallback? onReintentar;

  /// Callback para cargar el siguiente texto.
  final VoidCallback? onSiguiente;

  const EstadoEnvio({
    super.key,
    required this.estado,
    this.progreso = 0.0,
    this.errorMessage,
    this.onReintentar,
    this.onSiguiente,
  });

  @override
  State<EstadoEnvio> createState() => _EstadoEnvioState();
}

class _EstadoEnvioState extends State<EstadoEnvio>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(EstadoEnvio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado == 'exito' && oldWidget.estado != 'exito') {
      _checkController.forward();
    } else if (widget.estado != 'exito') {
      _checkController.reset();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor().withAlpha(40),
          width: 1,
        ),
      ),
      child: _buildContent(colorScheme),
    );
  }

  Color _getBorderColor() {
    switch (widget.estado) {
      case 'enviando':
        return Colors.blue;
      case 'exito':
        return const Color(0xFF43A047);
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildContent(ColorScheme colorScheme) {
    switch (widget.estado) {
      case 'enviando':
        return _buildEnviando(colorScheme);
      case 'exito':
        return _buildExito(colorScheme);
      case 'error':
        return _buildError(colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnviando(ColorScheme colorScheme) {
    final porcentaje = (widget.progreso * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progreso circular con porcentaje
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: widget.progreso > 0 ? widget.progreso : null,
                strokeWidth: 5,
                backgroundColor: colorScheme.primary.withAlpha(30),
                color: colorScheme.primary,
              ),
              Text(
                '$porcentaje%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enviando audio...',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'No cierres la aplicación',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.onSurface.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildExito(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Check animado
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF43A047).withAlpha(25),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF43A047),
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Audio enviado exitosamente!',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tu grabación fue registrada correctamente',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.onSurface.withAlpha(120),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: widget.onSiguiente,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
            'Siguiente texto',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.error.withAlpha(25),
          ),
          child: Icon(
            Icons.cloud_off_rounded,
            color: colorScheme.error,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Error al enviar',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: widget.onReintentar,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            'Reintentar',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            backgroundColor: colorScheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
