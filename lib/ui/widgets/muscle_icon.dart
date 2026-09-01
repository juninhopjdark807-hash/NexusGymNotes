import 'package:flutter/material.dart';

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
          size: size * 0.70,
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
    final swScreen = (side * 0.075).clamp(1.8, 2.6);
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


  void _peito(Canvas c) {
    _path(c, Path()..moveTo(28, 14)
..quadraticBezierTo(40, 6, 50, 8)
..quadraticBezierTo(60, 6, 72, 14)
..quadraticBezierTo(80, 22, 80, 38)
..lineTo(78, 82)
..quadraticBezierTo(50, 90, 22, 82)
..lineTo(20, 38)
..quadraticBezierTo(20, 22, 28, 14));
    _path(c, Path()..moveTo(26, 44)
..quadraticBezierTo(38, 56, 50, 57)
..quadraticBezierTo(62, 56, 74, 44));
    _line(c, 50, 50, 50, 86);
  }

  void _costas(Canvas c) {
    _path(c, Path()..moveTo(28, 14)
..quadraticBezierTo(40, 6, 50, 8)
..quadraticBezierTo(60, 6, 72, 14)
..quadraticBezierTo(80, 22, 80, 38)
..lineTo(78, 82)
..quadraticBezierTo(50, 90, 22, 82)
..lineTo(20, 38)
..quadraticBezierTo(20, 22, 28, 14));
    _line(c, 50, 10, 50, 88);
    _path(c, Path()..moveTo(34, 22)
..quadraticBezierTo(50, 36, 66, 22));
    _path(c, Path()..moveTo(36, 46)
..quadraticBezierTo(50, 56, 64, 46));
  }

  void _pernas(Canvas c) {
    _line(c, 30, 12, 70, 12);
    _path(c, Path()..moveTo(30, 12)
..quadraticBezierTo(21, 22, 22, 44)
..quadraticBezierTo(23, 66, 31, 84)
..lineTo(38, 90));
    _path(c, Path()..moveTo(70, 12)
..quadraticBezierTo(79, 22, 78, 44)
..quadraticBezierTo(77, 66, 69, 84)
..lineTo(62, 90));
    _path(c, Path()..moveTo(41, 20)
..quadraticBezierTo(47, 34, 50, 40)
..quadraticBezierTo(53, 34, 59, 20));
    _line(c, 45, 46, 43, 88);
    _line(c, 55, 46, 57, 88);
  }

  void _ombros(Canvas c) {
    _circle(c, 50, 9, 5);
    _line(c, 50, 14, 50, 20);
    _circle(c, 27, 32, 12);
    _circle(c, 73, 32, 12);
    _path(c, Path()..moveTo(27, 44)
..quadraticBezierTo(26, 64, 26, 86));
    _path(c, Path()..moveTo(73, 44)
..quadraticBezierTo(74, 64, 74, 86));
  }

  void _biceps(Canvas c) {
    _path(c, Path()..moveTo(16, 40)
..quadraticBezierTo(14, 26, 28, 22)
..lineTo(56, 16)
..quadraticBezierTo(68, 14, 70, 26)
..quadraticBezierTo(72, 38, 64, 44)
..lineTo(46, 54)
..quadraticBezierTo(34, 60, 28, 70)
..quadraticBezierTo(24, 76, 28, 82)
..lineTo(40, 86)
..quadraticBezierTo(52, 84, 54, 76)
..quadraticBezierTo(56, 68, 48, 62)
..quadraticBezierTo(40, 56, 36, 50)
..quadraticBezierTo(30, 42, 20, 42));
    _circle(c, 52, 88, 4);
    _path(c, Path()..moveTo(34, 28)
..quadraticBezierTo(44, 26, 52, 30));
  }

  void _triceps(Canvas c) {
    _path(c, Path()..moveTo(84, 40)
..quadraticBezierTo(86, 26, 72, 22)
..lineTo(44, 16)
..quadraticBezierTo(32, 14, 30, 26)
..quadraticBezierTo(28, 38, 36, 44)
..lineTo(54, 54)
..quadraticBezierTo(66, 60, 72, 70)
..quadraticBezierTo(76, 76, 72, 82)
..lineTo(60, 86)
..quadraticBezierTo(48, 84, 46, 76)
..quadraticBezierTo(44, 68, 52, 62)
..quadraticBezierTo(60, 56, 64, 50)
..quadraticBezierTo(70, 42, 80, 42));
    _circle(c, 48, 88, 4);
    _path(c, Path()..moveTo(66, 28)
..quadraticBezierTo(56, 26, 48, 30));
  }

  void _abdomen(Canvas c) {
    _path(c, Path()..moveTo(34, 10)
..quadraticBezierTo(42, 6, 50, 8)
..quadraticBezierTo(58, 6, 66, 10)
..lineTo(72, 36)
..quadraticBezierTo(74, 60, 63, 76)
..quadraticBezierTo(50, 86, 37, 76)
..quadraticBezierTo(26, 60, 28, 36)
..lineTo(34, 10));
    _line(c, 50, 16, 50, 80);
    _line(c, 32, 34, 68, 34);
    _line(c, 31, 56, 69, 56);
    _line(c, 41, 22, 41, 34);
    _line(c, 59, 22, 59, 34);
  }

  void _gluteos(Canvas c) {
    _path(c, Path()..moveTo(47, 16)
..quadraticBezierTo(27, 8, 21, 30)
..quadraticBezierTo(16, 54, 30, 68)
..quadraticBezierTo(40, 76, 47, 68));
    _path(c, Path()..moveTo(53, 16)
..quadraticBezierTo(73, 8, 79, 30)
..quadraticBezierTo(84, 54, 70, 68)
..quadraticBezierTo(60, 76, 53, 68));
    _line(c, 50, 18, 50, 80);
  }

  void _posterior(Canvas c) {
    _path(c, Path()..moveTo(22, 12)
..quadraticBezierTo(12, 30, 20, 48)
..quadraticBezierTo(26, 60, 24, 74)
..quadraticBezierTo(22, 84, 14, 88)
..lineTo(30, 88)
..quadraticBezierTo(38, 80, 38, 68)
..quadraticBezierTo(38, 56, 34, 44)
..quadraticBezierTo(42, 46, 48, 40)
..quadraticBezierTo(60, 28, 56, 16)
..quadraticBezierTo(44, 8, 22, 12));
    _line(c, 12, 88, 30, 88);
    _path(c, Path()..moveTo(40, 24)
..quadraticBezierTo(50, 22, 52, 32));
  }

  void _panturrilha(Canvas c) {
    _path(c, Path()..moveTo(34, 10)
..quadraticBezierTo(20, 20, 24, 42)
..quadraticBezierTo(27, 60, 38, 68)
..quadraticBezierTo(46, 74, 44, 88)
..lineTo(58, 88)
..quadraticBezierTo(62, 74, 54, 66)
..quadraticBezierTo(64, 56, 62, 40)
..quadraticBezierTo(60, 20, 46, 10)
..quadraticBezierTo(40, 6, 34, 10));
    _path(c, Path()..moveTo(42, 24)
..quadraticBezierTo(50, 34, 48, 48)
..quadraticBezierTo(46, 58, 40, 64));
    _line(c, 34, 88, 58, 88);
  }

  void _lombar(Canvas c) {
    _line(c, 50, 10, 50, 90);
    _circle(c, 50, 26, 5);
    _circle(c, 50, 44, 5);
    _circle(c, 50, 62, 5);
    _circle(c, 50, 80, 5);
    _line(c, 28, 64, 72, 64);
  }

  void _antebraco(Canvas c) {
    _path(c, Path()..moveTo(28, 16)
..lineTo(40, 58)
..lineTo(60, 58)
..lineTo(72, 16));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(38, 58, 24, 24), Radius.circular(6))));
  }

  void _trapezio(Canvas c) {
    _circle(c, 50, 14, 7);
    _line(c, 50, 21, 50, 44);
    _line(c, 20, 44, 80, 44);
    _line(c, 26, 44, 50, 24);
    _line(c, 74, 44, 50, 24);
    _line(c, 32, 44, 32, 86);
    _line(c, 68, 44, 68, 86);
  }

  void _pescoco(Canvas c) {
    _circle(c, 50, 16, 8);
    _path(c, Path()..moveTo(50, 24)
..lineTo(50, 48));
    _path(c, Path()..moveTo(20, 62)
..quadraticBezierTo(50, 44, 80, 62));
    _path(c, Path()..moveTo(32, 62)
..quadraticBezierTo(32, 74, 30, 86));
    _path(c, Path()..moveTo(68, 62)
..quadraticBezierTo(68, 74, 70, 86));
  }

  void _cardio(Canvas c) {
    _path(c, Path()..moveTo(50, 80)
..cubicTo(20, 56, 16, 28, 34, 20)
..cubicTo(44, 14, 48, 22, 50, 30)
..cubicTo(52, 22, 56, 14, 66, 20)
..cubicTo(84, 28, 80, 56, 50, 80));
    _path(c, Path()..moveTo(14, 48)
..lineTo(28, 48)
..lineTo(34, 34)
..lineTo(42, 62)
..lineTo(50, 42)
..lineTo(56, 48)
..lineTo(86, 48));
  }

  void _outros(Canvas c) {
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 28, 14, 44), Radius.circular(4))));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(22, 35, 10, 30), Radius.circular(3))));
    _line(c, 32, 50, 68, 50);
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(68, 35, 10, 30), Radius.circular(3))));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(78, 28, 14, 44), Radius.circular(4))));
  }

  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.group != group || old.color != color;
}
