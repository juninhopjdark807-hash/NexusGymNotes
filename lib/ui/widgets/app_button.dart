import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum AppButtonVariant { primary, ghost, danger }

/// Botão grande, com alvo de toque amplo — pensado para uso durante o treino.
///
/// O rótulo pode ser longo (ex.: "Próximo: Supino inclinado") e é truncado
/// com reticências em vez de gerar overflow horizontal.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.height = 60,
    this.iconAtEnd = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final double height;

  /// Se true, o ícone fica à direita do texto (ex.: seta "próximo").
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (Color bg, Color fg) = switch (variant) {
      AppButtonVariant.primary => (C.accent, C.accentInk),
      AppButtonVariant.ghost => (C.surface2, C.text),
      AppButtonVariant.danger => (C.dangerSoft, C.danger),
    };

    final iconWidget = icon == null
        ? null
        : Icon(icon, size: 18, color: fg);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        splashColor: C.accentSoft,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: height,
            width: expanded ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: variant == AppButtonVariant.ghost
                  ? Border.all(color: C.stroke)
                  : null,
              boxShadow: variant == AppButtonVariant.primary && enabled
                  ? [
                      BoxShadow(
                        color: C.accent.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null && !iconAtEnd) ...[
                  iconWidget,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.button.copyWith(
                      color: fg,
                      // letterSpacing alto estoura nomes longos em telas estreitas
                      letterSpacing: label.length > 22 ? 0.6 : 1.2,
                      height: 1.15,
                      fontSize: label.length > 28 ? 12.5 : 14,
                    ),
                  ),
                ),
                if (iconWidget != null && iconAtEnd) ...[
                  const SizedBox(width: 6),
                  iconWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de voltar (seta) para cabeçalhos.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.surface2,
            border: Border.all(color: C.strokeSoft),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: C.textDim,
            size: 16,
          ),
        ),
      ),
    );
  }
}
