import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Card premium padrão (surface grafite, borda sutil, raio 18).
class NexusCard extends StatelessWidget {
  const NexusCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.selected = false,
    this.accentTop = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool selected;
  final bool accentTop;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final decoration = BoxDecoration(
      color: C.surface,
      borderRadius: radius,
      border: Border.all(
        color: selected ? C.accent.withValues(alpha: 0.45) : C.strokeSoft,
        width: selected ? 1.2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        if (selected)
          BoxShadow(
            color: C.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
      ],
    );

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      foregroundDecoration: accentTop
          ? BoxDecoration(
              borderRadius: radius,
              border: const Border(
                top: BorderSide(color: C.accent, width: 2),
              ),
            )
          : null,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;

    // margin já aplicado no Container acima — não duplicar.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: C.accentSoft,
        highlightColor: C.accentGlow,
        child: content,
      ),
    );
  }
}
