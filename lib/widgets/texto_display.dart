/// Widget para mostrar el texto en quechua y su traducción al español.
///
/// El texto en quechua se muestra con tipografía grande y destacada
/// como elemento protagonista. La traducción al español aparece debajo
/// en un tamaño más pequeño y con color atenuado como referencia.
///
/// Incluye animación de entrada suave (fade-in + slide-up).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextoDisplay extends StatefulWidget {
  /// Texto en quechua (protagonista).
  final String textoQuechua;

  /// Traducción al español (referencia).
  final String textoEspanol;

  /// ID del texto (para mostrar al usuario).
  final String textoId;

  /// Callback cuando el usuario edita el texto en Quechua.
  final ValueChanged<String>? onQuechuaChanged;

  /// Si es true, deshabilita la edición y oculta el cursor.
  final bool readOnly;

  const TextoDisplay({
    super.key,
    required this.textoQuechua,
    required this.textoEspanol,
    required this.textoId,
    this.onQuechuaChanged,
    this.readOnly = false,
  });

  @override
  State<TextoDisplay> createState() => _TextoDisplayState();
}

class _TextoDisplayState extends State<TextoDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void didUpdateWidget(TextoDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animar cuando cambia el texto
    if (oldWidget.textoId != widget.textoId) {
      _animController.reset();
      _animController.forward();
    }
    // Quitar el foco si pasa a modo solo lectura
    if (widget.readOnly && !oldWidget.readOnly) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Fondo con glassmorphism sutil
            color: colorScheme.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withAlpha(40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiqueta "Español" con badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ESPAÑOL',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${widget.textoId}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Traducción al español (contexto)
              Text(
                widget.textoEspanol,
                style: GoogleFonts.merriweather(
                  fontSize: 22,
                  fontWeight: FontWeight.w700, // Hacerlo negrita para que se note más
                  height: 1.4,
                  color: colorScheme.onSurface, // Color oscuro/negro sólido
                ),
              ),

              const SizedBox(height: 20),

              // Divider sutil
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.outline.withAlpha(0),
                      colorScheme.outline.withAlpha(50),
                      colorScheme.outline.withAlpha(0),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Etiqueta "Quechua"
              Text(
                'QUECHUA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface.withAlpha(100),
                ),
              ),

              const SizedBox(height: 8),

              // Texto en quechua - campo de entrada editable
              IgnorePointer(
                ignoring: widget.readOnly,
                child: TextFormField(
                  initialValue: widget.textoQuechua,
                  onChanged: widget.onQuechuaChanged,
                  readOnly: widget.readOnly,
                  maxLines: null, // Permitir múltiples líneas si es largo
                style: GoogleFonts.merriweather(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe la traducción en quechua aquí...',
                  hintStyle: GoogleFonts.merriweather(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
