import 'package:flutter/material.dart';

/// Tokens visuais do aplicativo.
///
/// Tema exclusivamente escuro, uma única cor de destaque (volt),
/// poucos elementos, tipografia grande e legível durante o treino.
class C {
  C._();

  static const Color bg = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF141417);
  static const Color surface2 = Color(0xFF1D1D21);
  static const Color stroke = Color(0xFF27272D);
  static const Color text = Color(0xFFF4F4F6);
  static const Color textDim = Color(0xFF9C9CA6);
  static const Color textFaint = Color(0xFF5E5E68);

  /// Cor de destaque para ações importantes (volt).
  static const Color accent = Color(0xFFC8F542);
  static const Color accentSoft = Color(0x26C8F542);
  static const Color accentInk = Color(0xFF11140A);

  static const Color danger = Color(0xFFFF6B6B);
  static const Color dangerSoft = Color(0x26FF6B6B);
}

/// Fontes do aplicativo.
class AppFonts {
  AppFonts._();

  static const String body = 'Inter';
  static const String display = 'SpaceGrotesk';
}

/// Estilos de texto reutilizáveis (números grandes, rótulos técnicos).
class AppText {
  AppText._();

  static const TextStyle displayXl = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: C.text,
  );

  static const TextStyle displayL = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: C.text,
  );

  static const TextStyle displayM = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: C.text,
  );

  /// Rótulo técnico pequeno, com espaçamento de letras (ex.: AQUECIMENTO).
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: C.textFaint,
  );

  static const TextStyle labelAccent = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: C.accent,
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
    letterSpacing: 1.4,
  );
}

/// Tema escuro do aplicativo.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: C.bg,
      canvasColor: C.bg,
      dialogBackgroundColor: C.surface,
      indicatorColor: C.accent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      dividerColor: C.stroke,
      colorScheme: const ColorScheme.dark(
        primary: C.accent,
        onPrimary: C.accentInk,
        secondary: C.surface2,
        onSecondary: C.text,
        surface: C.surface,
        onSurface: C.text,
        error: C.danger,
        onError: C.bg,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: C.text,
        displayColor: C.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: C.bg,
        foregroundColor: C.text,
        elevation: 0,
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
    );
  }
}
