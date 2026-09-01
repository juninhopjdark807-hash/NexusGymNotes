import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Splash do aplicativo: fundo dark + asset "icone" GRANDE e centralizado.
///
/// Exibida enquanto o banco é aberto. Diferente do splash nativo do
/// Android 12+ (que mascara a arte em um círculo e corta a parte inferior
/// do logo), aqui o asset é exibido completo, sem máscara, sem círculo e
/// sem moldura — proporção original mantida.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Mesmo tom do launch nativo (Android/iOS) — transição sem "piscada".
  static const Color _bg = Color(0xFF0B0B0D);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Presença visual forte: ~78% do menor lado (com limites) — o logo fica
    // GRANDE e emoldurado pela tela inteira, sem padding excessivo. O asset
    // é quadrado e quase sem margens internas, então toda a arte aparece.
    final iconSize = (math.min(size.width, size.height) * 0.78)
        .clamp(240.0, 340.0)
        .toDouble();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Iluminação roxa discreta atrás da marca (identidade do ícone).
              // Sutil o bastante para não "encolher" visualmente o logo.
              IgnorePointer(
                child: Container(
                  width: iconSize * 1.55,
                  height: iconSize * 1.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        C.accent.withValues(alpha: 0.10),
                        C.accent.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              Image.asset(
                'icone',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
