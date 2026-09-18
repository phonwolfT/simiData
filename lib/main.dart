/// Entry point de la aplicación SimiData.
///
/// Configura el tema visual (inspirado en tonos andinos), el Provider
/// de estado global, y establece GrabacionScreen como pantalla inicial.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/grabacion_provider.dart';
import 'screens/grabacion_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fijar orientación vertical (mejor para lectura de textos)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const SimiDataApp());
}

class SimiDataApp extends StatelessWidget {
  const SimiDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════════════
    // Paleta de colores andinos:
    // - Primary: Terracota cálido (#B85C38) - tierra, cerámica
    // - Secondary: Dorado cosecha (#D4A574) - maíz, sol
    // - Accent: Verde bosque (#2D6A4F) - naturaleza andina
    // - Surface: Crema suave (#FFF8F0) - pergamino
    // ═══════════════════════════════════════════════════════════════════

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB85C38), // Terracota
      brightness: Brightness.light,
      primary: const Color(0xFFB85C38),
      secondary: const Color(0xFFD4A574),
      tertiary: const Color(0xFF2D6A4F),
      surface: const Color(0xFFFFF8F0),
      onSurface: const Color(0xFF2C1810),
      error: const Color(0xFFD32F2F),
    );

    return ChangeNotifierProvider(
      create: (_) => GrabacionProvider(),
      child: MaterialApp(
        title: 'SimiData',
        debugShowCheckedModeBanner: false,

        // ── Tema ──
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,

          // Tipografía base con Inter
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),

          // AppBar
          appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          // Botones elevados
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Botones outlined
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Scaffolds
          scaffoldBackgroundColor: colorScheme.surface,
        ),

        home: const GrabacionScreen(),
      ),
    );
  }
}
