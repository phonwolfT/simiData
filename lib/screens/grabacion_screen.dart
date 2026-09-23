/// Pantalla principal de grabación de audio.
///
/// Orquesta todos los widgets según el estado actual del [GrabacionProvider].
/// El layout se divide en tres zonas:
/// 1. Header: nombre de la app + contador de textos grabados
/// 2. Centro: widget de texto quechua/español
/// 3. Inferior: zona de interacción (varía según el estado)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/grabacion_provider.dart';
import '../widgets/texto_display.dart';
import '../widgets/boton_grabar.dart';
import '../widgets/indicador_grabando.dart';
import '../widgets/reproductor_audio.dart';
import '../widgets/estado_envio.dart';

class GrabacionScreen extends StatelessWidget {
  const GrabacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        // Fondo con gradiente sutil
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface,
              colorScheme.primary.withAlpha(8),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<GrabacionProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // ═══════════════════════════════════════════════════
                  // HEADER
                  // ═══════════════════════════════════════════════════
                  _buildHeader(context, provider),

                  // ═══════════════════════════════════════════════════
                  // CONTENIDO PRINCIPAL (scrollable)
                  // ═══════════════════════════════════════════════════
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),

                          // Zona de texto
                          _buildTextoArea(provider),

                          const SizedBox(height: 24),

                          // Zona de interacción (cambia según estado)
                          _buildInteractionArea(context, provider),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Header con logo, nombre y contador de textos.
  Widget _buildHeader(BuildContext context, GrabacionProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo/ícono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(180),
                ],
              ),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Nombre de la app
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SimiData',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Recolección de voz quechua',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Contador de textos grabados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${provider.textosGrabados}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Zona de texto: muestra el texto quechua/español o un placeholder.
  Widget _buildTextoArea(GrabacionProvider provider) {
    switch (provider.estado) {
      case EstadoGrabacion.cargandoTexto:
        return _buildLoadingCard();

      case EstadoGrabacion.errorTexto:
        return _buildErrorCard(
          provider.errorMessage ?? 'Error desconocido',
          onRetry: provider.cargarTexto,
        );

      default:
        if (provider.textoActual != null) {
          return TextoDisplay(
            textoId: provider.textoActual!.id,
            textoQuechua: provider.textoQuechuaIngresado, // Pasar el del provider, no el original
            textoEspanol: provider.textoActual!.textoEspanol,
            onQuechuaChanged: provider.setTextoQuechuaIngresado,
            readOnly: provider.estado != EstadoGrabacion.listoParaGrabar,
          );
        }
        return const SizedBox.shrink();
    }
  }

  /// Zona de interacción: renderiza el widget apropiado según el estado.
  Widget _buildInteractionArea(
      BuildContext context, GrabacionProvider provider) {
    switch (provider.estado) {
      case EstadoGrabacion.cargandoTexto:
        return const SizedBox.shrink(); // Ya se muestra el loading en el texto

      case EstadoGrabacion.errorTexto:
        return const SizedBox.shrink(); // Ya se muestra el error en el texto

      case EstadoGrabacion.listoParaGrabar:
        final isEmpty = provider.textoQuechuaIngresado.trim().isEmpty;
        return BotonGrabar(
          isRecording: false,
          disabled: isEmpty,
          onPressed: isEmpty ? () {} : provider.iniciarGrabacion,
        );

      case EstadoGrabacion.grabando:
        return Column(
          children: [
            IndicadorGrabando(
              duracion: provider.duracionGrabacion,
              amplitudDb: provider.amplitudActual,
            ),
            const SizedBox(height: 24),
            BotonGrabar(
              isRecording: true,
              onPressed: provider.detenerGrabacion,
            ),
          ],
        );

      case EstadoGrabacion.validando:
        return _buildValidating(context);

      case EstadoGrabacion.errorValidacion:
        return _buildValidationError(context, provider);

      case EstadoGrabacion.revision:
        return ReproductorAudio(
          audioPath: provider.audioPath!,
          duracionSegundos: provider.validationResult?.duration,
          onRegrabar: provider.regrabar,
          onConfirmar: provider.confirmarEnvio,
        );

      case EstadoGrabacion.enviando:
        return EstadoEnvio(
          estado: 'enviando',
          progreso: provider.progresoEnvio,
        );

      case EstadoGrabacion.envioExitoso:
        return EstadoEnvio(
          estado: 'exito',
          onSiguiente: provider.siguienteTexto,
        );

      case EstadoGrabacion.errorEnvio:
        return EstadoEnvio(
          estado: 'error',
          errorMessage: provider.errorMessage,
          onReintentar: provider.reintentarEnvio,
        );
    }
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────

  /// Card de carga con shimmer effect.
  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer bars
          _shimmerBar(width: 100, height: 16),
          const SizedBox(height: 20),
          _shimmerBar(width: double.infinity, height: 20),
          const SizedBox(height: 10),
          _shimmerBar(width: 240, height: 20),
          const SizedBox(height: 24),
          _shimmerBar(width: 80, height: 14),
          const SizedBox(height: 12),
          _shimmerBar(width: 200, height: 16),
        ],
      ),
    );
  }

  Widget _shimmerBar({required double height, double? width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// Card de error con botón de reintentar.
  Widget _buildErrorCard(String message, {required VoidCallback onRetry}) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.error.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Error al cargar texto',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reintentar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Indicador de validación en progreso.
  Widget _buildValidating(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const CircularProgressIndicator(strokeWidth: 3),
        const SizedBox(height: 16),
        Text(
          'Validando audio...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onSurface.withAlpha(160),
          ),
        ),
      ],
    );
  }

  /// Error de validación con mensaje y opción de regrabar.
  Widget _buildValidationError(
      BuildContext context, GrabacionProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'Audio inválido',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 20),
          BotonGrabar(
            isRecording: false,
            onPressed: provider.regrabar,
          ),
        ],
      ),
    );
  }
}
