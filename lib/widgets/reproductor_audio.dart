/// Reproductor de audio para escuchar la grabación antes de confirmar.
///
/// Usa el paquete `just_audio` para reproducir el archivo WAV grabado.
/// Incluye:
/// - Botón play/pause
/// - Seekbar (slider de progreso)
/// - Duración total y posición actual
/// - Botones de acción: "Volver a grabar" y "Confirmar y enviar"
library;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

class ReproductorAudio extends StatefulWidget {
  /// Ruta local del archivo de audio a reproducir.
  final String audioPath;

  /// Duración del audio (obtenida de la validación).
  final double? duracionSegundos;

  /// Callback cuando el usuario presiona "Volver a grabar".
  final VoidCallback onRegrabar;

  /// Callback cuando el usuario presiona "Confirmar y enviar".
  final VoidCallback onConfirmar;

  const ReproductorAudio({
    super.key,
    required this.audioPath,
    this.duracionSegundos,
    required this.onRegrabar,
    required this.onConfirmar,
  });

  @override
  State<ReproductorAudio> createState() => _ReproductorAudioState();
}

class _ReproductorAudioState extends State<ReproductorAudio> {
  late AudioPlayer _player;
  bool _isLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setFilePath(widget.audioPath);
      setState(() => _isLoaded = true);
    } catch (e) {
      setState(() => _error = 'Error al cargar el audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return _buildError(colorScheme);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Escucha tu grabación',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Player
          if (_isLoaded) ...[
            // Botón play/pause + seekbar
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final playing = playerState?.playing ?? false;
                final processingState = playerState?.processingState;

                // Auto-rewind al terminar
                if (processingState == ProcessingState.completed) {
                  _player.seek(Duration.zero);
                  _player.pause();
                }

                return Row(
                  children: [
                    // Botón play/pause
                    GestureDetector(
                      onTap: () {
                        if (playing) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(playing),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Seekbar + tiempos
                    Expanded(
                      child: Column(
                        children: [
                          StreamBuilder<Duration>(
                            stream: _player.positionStream,
                            builder: (context, posSnapshot) {
                              final position =
                                  posSnapshot.data ?? Duration.zero;
                              final duration =
                                  _player.duration ?? Duration.zero;

                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 4,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                              enabledThumbRadius: 7),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 14),
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor:
                                          colorScheme.primary.withAlpha(40),
                                      thumbColor: colorScheme.primary,
                                      overlayColor:
                                          colorScheme.primary.withAlpha(30),
                                    ),
                                    child: Slider(
                                      value: duration.inMilliseconds > 0
                                          ? (position.inMilliseconds /
                                                  duration.inMilliseconds)
                                              .clamp(0.0, 1.0)
                                          : 0.0,
                                      onChanged: (value) {
                                        _player.seek(Duration(
                                          milliseconds: (value *
                                                  duration.inMilliseconds)
                                              .toInt(),
                                        ));
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withAlpha(120),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withAlpha(120),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              // Volver a grabar
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _player.stop();
                    widget.onRegrabar();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Regrabar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: colorScheme.onSurface.withAlpha(180),
                    side: BorderSide(
                      color: colorScheme.outline.withAlpha(60),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Confirmar y enviar
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _player.stop();
                    widget.onConfirmar();
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(
                    'Enviar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: widget.onRegrabar,
            child: const Text('Volver a grabar'),
          ),
        ],
      ),
    );
  }
}
