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


  void _peito(Canvas c) {
    _path(c, Path()..moveTo(50, 15)
..quadraticBezierTo(38, 7, 28, 14)
..quadraticBezierTo(19, 21, 18, 36)
..lineTo(16, 64)
..quadraticBezierTo(15, 74, 21, 78)
..lineTo(27, 76)
..lineTo(26, 52)
..quadraticBezierTo(26, 44, 32, 40)
..quadraticBezierTo(28, 54, 30, 66)
..quadraticBezierTo(32, 80, 41, 86)
..lineTo(50, 90));
    _path(c, Path()..moveTo(50, 15)
..quadraticBezierTo(62, 7, 72, 14)
..quadraticBezierTo(81, 21, 82, 36)
..lineTo(84, 64)
..quadraticBezierTo(85, 74, 79, 78)
..lineTo(73, 76)
..lineTo(74, 52)
..quadraticBezierTo(74, 44, 68, 40)
..quadraticBezierTo(72, 54, 70, 66)
..quadraticBezierTo(68, 80, 59, 86)
..lineTo(50, 90));
    _path(c, Path()..moveTo(32, 24)
..quadraticBezierTo(36, 34, 42, 38)
..quadraticBezierTo(47, 41, 50, 41)
..quadraticBezierTo(53, 41, 58, 38)
..quadraticBezierTo(64, 34, 68, 24));
    _path(c, Path()..moveTo(34, 32)
..quadraticBezierTo(43, 50, 50, 52)
..quadraticBezierTo(57, 50, 66, 32));
    _line(c, 50, 42, 50, 48);
    _circle(c, 42, 50, 1.8);
    _circle(c, 58, 50, 1.8);
  }

  void _costas(Canvas c) {
    _path(c, Path()..moveTo(50, 14)
..quadraticBezierTo(38, 6, 28, 13)
..quadraticBezierTo(19, 20, 18, 35)
..lineTo(16, 63)
..quadraticBezierTo(15, 73, 21, 77)
..lineTo(27, 75)
..lineTo(26, 52)
..quadraticBezierTo(26, 44, 32, 40)
..quadraticBezierTo(28, 54, 30, 66)
..quadraticBezierTo(32, 80, 41, 86)
..lineTo(50, 90));
    _path(c, Path()..moveTo(50, 14)
..quadraticBezierTo(62, 6, 72, 13)
..quadraticBezierTo(81, 20, 82, 35)
..lineTo(84, 63)
..quadraticBezierTo(85, 73, 79, 77)
..lineTo(73, 75)
..lineTo(74, 52)
..quadraticBezierTo(74, 44, 68, 40)
..quadraticBezierTo(72, 54, 70, 66)
..quadraticBezierTo(68, 80, 59, 86)
..lineTo(50, 90));
    _line(c, 50, 18, 50, 86);
    _path(c, Path()..moveTo(31, 23)
..quadraticBezierTo(36, 36, 45, 45));
    _path(c, Path()..moveTo(69, 23)
..quadraticBezierTo(64, 36, 55, 45));
  }

  void _pernas(Canvas c) {
    _line(c, 33, 10, 67, 10);
    _path(c, Path()..moveTo(33, 10)
..quadraticBezierTo(26, 12, 25, 26)
..quadraticBezierTo(24, 50, 29, 70)
..lineTo(33, 88));
    _path(c, Path()..moveTo(67, 10)
..quadraticBezierTo(74, 12, 75, 26)
..quadraticBezierTo(76, 50, 71, 70)
..lineTo(67, 88));
    _path(c, Path()..moveTo(44, 12)
..quadraticBezierTo(42, 32, 46, 48)
..quadraticBezierTo(50, 54, 54, 48)
..quadraticBezierTo(58, 32, 56, 12));
    _line(c, 46, 48, 44, 86);
    _line(c, 54, 48, 56, 86);
    _path(c, Path()..moveTo(26, 58)
..quadraticBezierTo(30, 62, 34, 58));
    _path(c, Path()..moveTo(74, 58)
..quadraticBezierTo(70, 62, 66, 58));
  }

  void _ombros(Canvas c) {
    _circle(c, 50, 9, 5);
    _path(c, Path()..moveTo(50, 14)
..quadraticBezierTo(38, 8, 28, 18)
..quadraticBezierTo(20, 28, 22, 44)
..quadraticBezierTo(24, 58, 22, 84));
    _path(c, Path()..moveTo(50, 14)
..quadraticBezierTo(62, 8, 72, 18)
..quadraticBezierTo(80, 28, 78, 44)
..quadraticBezierTo(76, 58, 78, 84));
    _path(c, Path()..moveTo(36, 22)
..quadraticBezierTo(44, 18, 50, 20)
..quadraticBezierTo(56, 18, 64, 22));
    _line(c, 50, 22, 50, 84);
  }

  void _biceps(Canvas c) {
    _path(c, Path()..moveTo(22, 82)
..quadraticBezierTo(20, 66, 28, 56)
..quadraticBezierTo(26, 42, 36, 32)
..quadraticBezierTo(47, 20, 60, 22)
..quadraticBezierTo(73, 24, 72, 38)
..quadraticBezierTo(71, 52, 59, 58)
..quadraticBezierTo(47, 63, 42, 71)
..quadraticBezierTo(37, 78, 34, 84)
..lineTo(22, 82));
    _path(c, Path()..moveTo(38, 30)
..quadraticBezierTo(44, 38, 42, 48));
    _circle(c, 24, 86, 4.5);
  }

  void _triceps(Canvas c) {
    _path(c, Path()..moveTo(78, 82)
..quadraticBezierTo(80, 66, 72, 56)
..quadraticBezierTo(74, 42, 64, 32)
..quadraticBezierTo(53, 20, 40, 22)
..quadraticBezierTo(27, 24, 28, 38)
..quadraticBezierTo(29, 52, 41, 58)
..quadraticBezierTo(53, 63, 58, 71)
..quadraticBezierTo(63, 78, 66, 84)
..lineTo(78, 82));
    _path(c, Path()..moveTo(62, 30)
..quadraticBezierTo(56, 38, 58, 48));
    _circle(c, 76, 86, 4.5);
  }

  void _abdomen(Canvas c) {
    _path(c, Path()..moveTo(34, 12)
..quadraticBezierTo(42, 7, 50, 11)
..quadraticBezierTo(58, 7, 66, 12)
..lineTo(72, 38)
..quadraticBezierTo(72, 58, 67, 76)
..lineTo(63, 90)
..lineTo(37, 90)
..lineTo(33, 76)
..quadraticBezierTo(28, 58, 28, 38)
..lineTo(34, 12));
    _line(c, 50, 16, 50, 84);
    _path(c, Path()..moveTo(35, 28)
..lineTo(65, 28));
    _path(c, Path()..moveTo(34, 46)
..lineTo(66, 46));
    _path(c, Path()..moveTo(34, 64)
..lineTo(66, 64));
    _path(c, Path()..moveTo(35, 82)
..lineTo(65, 82));
    _line(c, 42, 28, 42, 82);
    _line(c, 58, 28, 58, 82);
  }

  void _gluteos(Canvas c) {
    _path(c, Path()..moveTo(30, 22)
..quadraticBezierTo(16, 36, 16, 54)
..quadraticBezierTo(16, 72, 30, 80));
    _path(c, Path()..moveTo(70, 22)
..quadraticBezierTo(84, 36, 84, 54)
..quadraticBezierTo(84, 72, 70, 80));
    _line(c, 50, 22, 50, 84);
  }

  void _posterior(Canvas c) {
    _path(c, Path()..moveTo(26, 14)
..quadraticBezierTo(24, 36, 36, 52)
..quadraticBezierTo(46, 66, 60, 70)
..quadraticBezierTo(68, 72, 70, 80));
    _path(c, Path()..moveTo(48, 62)
..quadraticBezierTo(58, 68, 62, 78)
..lineTo(60, 88));
    _path(c, Path()..moveTo(36, 22)
..quadraticBezierTo(44, 30, 46, 42));
  }

  void _panturrilha(Canvas c) {
    _path(c, Path()..moveTo(42, 8)
..quadraticBezierTo(40, 30, 42, 52)
..quadraticBezierTo(43, 70, 44, 84));
    _path(c, Path()..moveTo(54, 8)
..quadraticBezierTo(66, 20, 62, 40)
..quadraticBezierTo(58, 54, 50, 66)
..quadraticBezierTo(46, 74, 46, 84));
    _line(c, 36, 88, 56, 88);
  }

  void _lombar(Canvas c) {
    _line(c, 50, 10, 50, 90);
    _circle(c, 50, 24, 4.5);
    _circle(c, 50, 40, 4.5);
    _circle(c, 50, 56, 4.5);
    _circle(c, 50, 72, 4.5);
    _line(c, 30, 62, 70, 62);
  }

  void _antebraco(Canvas c) {
    _path(c, Path()..moveTo(28, 18)
..lineTo(40, 58)
..lineTo(60, 58)
..lineTo(72, 18));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(38, 58, 24, 24), Radius.circular(6))));
  }

  void _trapezio(Canvas c) {
    _circle(c, 50, 16, 8);
    _line(c, 50, 24, 50, 48);
    _line(c, 18, 48, 82, 48);
    _line(c, 24, 48, 50, 26);
    _line(c, 76, 48, 50, 26);
    _line(c, 32, 48, 32, 88);
    _line(c, 68, 48, 68, 88);
  }

  void _pescoco(Canvas c) {
    _circle(c, 50, 22, 12);
    _line(c, 50, 34, 50, 82);
    _line(c, 36, 50, 64, 50);
    _line(c, 38, 64, 62, 64);
  }

  void _cardio(Canvas c) {
    _path(c, Path()..moveTo(50, 80)
..cubicTo(20, 56, 16, 28, 32, 20)
..cubicTo(42, 14, 48, 20, 50, 28)
..cubicTo(52, 20, 58, 14, 68, 20)
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
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 30, 14, 40), Radius.circular(4))));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(22, 36, 10, 28), Radius.circular(3))));
    _line(c, 32, 50, 68, 50);
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(68, 36, 10, 28), Radius.circular(3))));
    _path(c, Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(78, 30, 14, 40), Radius.circular(4))));
  }

  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.group != group || old.color != color;
}
