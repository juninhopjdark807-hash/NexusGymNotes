import 'package:flutter/material.dart';

/// Tokens visuais — Fase 3 (identidade premium / futurista).
///
/// Dark mode, accent roxo usado com parcimônia, tipografia geométrica
/// (Space Grotesk ≈ Exo 2) e surfaces grafite.
class C {
  C._();

  static const Color bg = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF16181D);
  static const Color surface2 = Color(0xFF23262B);
  static const Color stroke = Color(0xFF2C3038);
  static const Color strokeSoft = Color(0x14FFFFFF);

  static const Color text = Color(0xFFE6E6E6);
  static const Color textDim = Color(0xFF9A9AA3);
  static const Color textFaint = Color(0xFF5C5E68);

  /// Accent principal (ações, seleção, progresso).
  static const Color accent = Color(0xFF6C5CFF);
  static const Color accentSecondary = Color(0xFF9A8CFF);
  static const Color accentSoft = Color(0x336C5CFF);
  static const Color accentGlow = Color(0x1A6C5CFF);
  static const Color accentInk = Color(0xFFF4F2FF);

  static const Color danger = Color(0xFFFF6B7A);
  static const Color dangerSoft = Color(0x26FF6B7A);

  static const Color success = Color(0xFF4ADE80);
  static const Color successSoft = Color(0x1A4ADE80);
}

/// Fontes do aplicativo.
///
/// Space Grotesk: display geométrico (direção Exo 2).
/// Inter: corpo legível.
class AppFonts {
  AppFonts._();

  static const String body = 'Inter';
  static const String display = 'SpaceGrotesk';
}

/// Estilos de texto reutilizáveis.
class AppText {
  AppText._();

  static const TextStyle displayXl = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: C.text,
  );

  static const TextStyle displayL = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: C.text,
  );

  static const TextStyle displayM = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: C.text,
  );

  /// Rótulo técnico pequeno (ex.: AQUECIMENTO).
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: C.textFaint,
  );

  static const TextStyle labelAccent = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: C.accentSecondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    height: 1.4,
    color: C.text,
  );

  static const TextStyle bodyDim = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    height: 1.4,
    color: C.textDim,
  );

  static const TextStyle bodyFaint = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    height: 1.4,
    color: C.textFaint,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  /// Números de peso/reps — hierarquia máxima no treino.
  static const TextStyle metric = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 48,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: C.text,
  );
}

/// Tema escuro do aplicativo.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: C.bg,
      tabBarTheme: const TabBarThemeData(indicatorColor: C.accent),
      highlightColor: Colors.transparent,
      splashColor: C.accentSoft,
      dividerColor: C.stroke,
      colorScheme: const ColorScheme.dark(
        primary: C.accent,
        onPrimary: C.accentInk,
        secondary: C.accentSecondary,
        onSecondary: C.accentInk,
        surface: C.surface,
        onSurface: C.text,
        error: C.danger,
        onError: C.bg,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: C.text,
        displayColor: C.text,
        fontFamily: AppFonts.body,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: C.bg,
        foregroundColor: C.text,
        elevation: 0,
        centerTitle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: C.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: C.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: C.strokeSoft),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: C.surface2,
        contentTextStyle: TextStyle(color: C.text, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: C.accent,
        foregroundColor: C.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: C.textFaint, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.danger),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: C.accent,
        linearTrackColor: C.surface2,
      ),
    );
  }
}
