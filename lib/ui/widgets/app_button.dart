import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum AppButtonVariant { primary, ghost, danger }

/// Botão grande, com alvo de toque amplo — pensado para uso durante o treino.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;

  /// `null` desabilita o botão.
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (Color bg, Color fg) = switch (variant) {
      AppButtonVariant.primary => (C.accent, C.accentInk),
      AppButtonVariant.ghost => (C.surface2, C.text),
      AppButtonVariant.danger => (C.dangerSoft, C.danger),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: height,
            width: expanded ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: variant == AppButtonVariant.ghost
                  ? Border.all(color: C.stroke)
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: AppText.button.copyWith(color: fg),
                  ),
                ],
              ),
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
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: C.textDim, size: 18),
        ),
      ),
    );
  }
}
