#!/usr/bin/env python3
"""Generate lib/ui/widgets/muscle_icon.dart from tool/icons/spec.json.

The spec is the single source of truth — same geometry validated in the
Python preview and compiled into the Flutter painter.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = json.load(open(os.path.join(HERE, "spec.json"), encoding="utf-8"))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "lib", "ui", "widgets", "muscle_icon.dart"))


def nums(seq):
    return ", ".join(f"{v:g}" for v in seq)


def dart_cmd(cmd):
    if cmd[0] == "M":
        return f"..moveTo({nums(cmd[1:])})"
    if cmd[0] == "L":
        return f"..lineTo({nums(cmd[1:])})"
    if cmd[0] == "Q":
        return f"..quadraticBezierTo({nums(cmd[1:])})"
    if cmd[0] == "C":
        return f"..cubicTo({nums(cmd[1:])})"
    raise ValueError(cmd)


def method(name, prims):
    lines = [f"  void _{name}(Canvas c) {{"]
    for p in prims:
        t = p["t"]
        if t == "line":
            x1, y1, x2, y2 = p["p"]
            lines.append(f"    _line(c, {nums([x1, y1, x2, y2])});")
        elif t == "circle":
            cx, cy, r = p["p"]
            lines.append(f"    _circle(c, {nums([cx, cy, r])});")
        elif t == "rrect":
            x, y, w, h, r = p["p"]
            lines.append(
                f"    _path(c, Path()..addRRect(RRect.fromRectAndRadius("
                f"Rect.fromLTWH({nums([x, y, w, h])}), Radius.circular({r:g}))));"
            )
        elif t == "path":
            body = "\n".join(dart_cmd(cmd) for cmd in p["d"])
            lines.append(f"    _path(c, Path(){body});")
        else:
            raise ValueError(t)
    lines.append("  }")
    return "\n".join(lines)


HEADER = """import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone monoline de grupo muscular — visual fiel às prévias aprovadas.
///
/// Geometria definida em `tool/icons/spec.json` (grade 0–100) e compilada
/// aqui por `tool/icons/gen_dart.py`. Não edite este arquivo à mão: edite o
/// spec e regenere.
class MuscleIcon extends StatelessWidget {
  const MuscleIcon({
    super.key,
    required this.group,
    this.size = 18,
    this.color,
    this.active = false,
  });

  final MuscleGroup group;
  final double size;
  final Color? color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? const Color(0xFFE8E4FF) : C.textDim);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MusclePainter(group: group, color: c),
      ),
    );
  }
}

/// Badge circular roxo com glow (cards da home).
class MuscleBadge extends StatelessWidget {
  const MuscleBadge({
    super.key,
    required this.group,
    this.size = 36,
    this.active = false,
  });

  final MuscleGroup group;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? RadialGradient(
                colors: [
                  const Color(0xFF2A2460),
                  C.accent.withValues(alpha: 0.22),
                  const Color(0xFF16122E),
                ],
                stops: const [0.0, 0.55, 1.0],
              )
            : null,
        color: active ? null : C.surface2,
        border: Border.all(
          color: active ? const Color(0xFF8B7CFF) : C.stroke,
          width: 1.6,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: C.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Center(
        child: MuscleIcon(
          group: group,
          // Ícone maior no círculo para legibilidade (~64%).
          size: size * 0.64,
          active: active,
        ),
      ),
    );
  }
}

typedef WorkoutIcon = MuscleIcon;

// =============================================================================

class _MusclePainter extends CustomPainter {
  _MusclePainter({required this.group, required this.color});

  final MuscleGroup group;
  final Color color;

  late Paint _s;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final pad = side * 0.04;
    final inner = side - pad * 2;
    final scale = inner / 100.0;
    // Traço fino monoline: ~5.5% do ícone, compensado pela escala do canvas.
    final swScreen = (side * 0.055).clamp(1.6, 2.4);
    _s = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = swScreen / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(pad, pad);
    canvas.scale(scale, scale);

    switch (group) {
      case MuscleGroup.peito:
        _peito(canvas);
      case MuscleGroup.costas:
        _costas(canvas);
      case MuscleGroup.ombros:
        _ombros(canvas);
      case MuscleGroup.biceps:
        _biceps(canvas);
      case MuscleGroup.triceps:
        _triceps(canvas);
      case MuscleGroup.quadriceps:
      case MuscleGroup.pernas:
        _pernas(canvas);
      case MuscleGroup.posteriorCoxa:
        _posterior(canvas);
      case MuscleGroup.gluteos:
        _gluteos(canvas);
      case MuscleGroup.panturrilhas:
        _panturrilha(canvas);
      case MuscleGroup.abdomen:
        _abdomen(canvas);
      case MuscleGroup.lombar:
        _lombar(canvas);
      case MuscleGroup.antebraco:
        _antebraco(canvas);
      case MuscleGroup.trapezio:
        _trapezio(canvas);
      case MuscleGroup.pescoco:
        _pescoco(canvas);
      case MuscleGroup.cardio:
        _cardio(canvas);
      case MuscleGroup.outros:
        _outros(canvas);
    }
    canvas.restore();
  }

  // ---- helpers (coords em 0–100) ----

  void _line(Canvas c, double x1, double y1, double x2, double y2) {
    c.drawLine(Offset(x1, y1), Offset(x2, y2), _s);
  }

  void _path(Canvas c, Path p) => c.drawPath(p, _s);

  void _circle(Canvas c, double x, double y, double r) {
    c.drawCircle(Offset(x, y), r, _s);
  }

"""


def main():
    parts = [HEADER]
    order = [
        "peito", "costas", "pernas", "ombros", "biceps", "triceps",
        "abdomen", "gluteos", "posterior", "panturrilha", "lombar",
        "antebraco", "trapezio", "pescoco", "cardio", "outros",
    ]
    for name in order:
        parts.append(method(name, SPEC[name]))
        parts.append("")
    parts.append("""  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.group != group || old.color != color;
}
""")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    print("generated", OUT)


if __name__ == "__main__":
    main()
