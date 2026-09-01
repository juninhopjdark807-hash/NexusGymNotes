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
    _path(c, Path()..moveTo(26, 12)
..quadraticBezierTo(36, 4, 50, 6)
..quadraticBezierTo(64, 4, 74, 12)
..quadraticBezierTo(84, 20, 84, 36)
..quadraticBezierTo(84, 56, 76, 74)
..quadraticBezierTo(72, 84, 62, 88)
..lineTo(38, 88)
..quadraticBezierTo(28, 84, 24, 74)
..quadraticBezierTo(16, 56, 16, 36)
..quadraticBezierTo(16, 20, 26, 12));
    _path(c, Path()..moveTo(40, 10)
..quadraticBezierTo(44, 16, 50, 16)
..quadraticBezierTo(56, 16, 60, 10));
    _path(c, Path()..moveTo(26, 26)
..quadraticBezierTo(38, 38, 50, 40)
..quadraticBezierTo(62, 38, 74, 26));
    _path(c, Path()..moveTo(40, 24)
..quadraticBezierTo(44, 30, 50, 32)
..quadraticBezierTo(56, 30, 60, 24));
    _path(c, Path()..moveTo(28, 32)
..quadraticBezierTo(36, 52, 50, 56)
..quadraticBezierTo(64, 52, 72, 32));
    _line(c, 50, 40, 50, 60);
    _path(c, Path()..moveTo(22, 48)
..quadraticBezierTo(20, 60, 24, 72));
    _path(c, Path()..moveTo(78, 48)
..quadraticBezierTo(80, 60, 76, 72));
    _path(c, Path()..moveTo(30, 74)
..quadraticBezierTo(38, 68, 46, 72)
..quadraticBezierTo(50, 74, 54, 72)
..quadraticBezierTo(62, 68, 70, 74));
  }

  void _costas(Canvas c) {
    _path(c, Path()..moveTo(26, 12)
..quadraticBezierTo(36, 4, 50, 6)
..quadraticBezierTo(64, 4, 74, 12)
..quadraticBezierTo(84, 20, 84, 36)
..quadraticBezierTo(84, 56, 76, 74)
..quadraticBezierTo(72, 84, 62, 88)
..lineTo(38, 88)
..quadraticBezierTo(28, 84, 24, 74)
..quadraticBezierTo(16, 56, 16, 36)
..quadraticBezierTo(16, 20, 26, 12));
    _path(c, Path()..moveTo(34, 10)
..quadraticBezierTo(42, 18, 50, 18)
..quadraticBezierTo(58, 18, 66, 10));
    _line(c, 50, 12, 50, 86);
    _path(c, Path()..moveTo(32, 34)
..quadraticBezierTo(40, 46, 46, 62)
..quadraticBezierTo(36, 58, 30, 48));
    _path(c, Path()..moveTo(68, 34)
..quadraticBezierTo(60, 46, 54, 62)
..quadraticBezierTo(64, 58, 70, 48));
    _path(c, Path()..moveTo(26, 40)
..quadraticBezierTo(24, 56, 28, 70));
    _path(c, Path()..moveTo(74, 40)
..quadraticBezierTo(76, 56, 72, 70));
    _path(c, Path()..moveTo(40, 74)
..quadraticBezierTo(50, 70, 60, 74)
..quadraticBezierTo(56, 80, 50, 82)
..quadraticBezierTo(44, 80, 40, 74));
  }

  void _pernas(Canvas c) {
    _path(c, Path()..moveTo(22, 12)
..quadraticBezierTo(34, 6, 50, 8)
..quadraticBezierTo(66, 6, 78, 12)
..quadraticBezierTo(84, 16, 84, 26)
..lineTo(82, 34)
..quadraticBezierTo(74, 40, 62, 42)
..quadraticBezierTo(62, 50, 64, 66)
..quadraticBezierTo(66, 80, 70, 88)
..lineTo(76, 92)
..lineTo(70, 94)
..quadraticBezierTo(62, 92, 58, 84)
..quadraticBezierTo(54, 70, 54, 52)
..quadraticBezierTo(54, 44, 50, 44)
..quadraticBezierTo(46, 44, 46, 52)
..quadraticBezierTo(46, 70, 42, 84)
..quadraticBezierTo(38, 92, 30, 94)
..lineTo(24, 92)
..quadraticBezierTo(30, 88, 34, 80)
..quadraticBezierTo(36, 66, 38, 50)
..quadraticBezierTo(38, 42, 26, 34)
..lineTo(16, 26)
..quadraticBezierTo(16, 16, 22, 12));
    _path(c, Path()..moveTo(38, 16)
..quadraticBezierTo(46, 22, 50, 22)
..quadraticBezierTo(54, 22, 62, 16));
    _path(c, Path()..moveTo(60, 20)
..quadraticBezierTo(68, 22, 72, 30));
    _path(c, Path()..moveTo(40, 20)
..quadraticBezierTo(32, 22, 28, 30));
    _line(c, 50, 26, 50, 38);
    _path(c, Path()..moveTo(50, 46)
..lineTo(50, 74));
    _path(c, Path()..moveTo(42, 50)
..quadraticBezierTo(46, 56, 46, 61));
    _path(c, Path()..moveTo(58, 50)
..quadraticBezierTo(54, 56, 54, 61));
  }

  void _ombros(Canvas c) {
    _circle(c, 50, 8, 4.5);
    _line(c, 50, 12, 50, 16);
    _path(c, Path()..moveTo(50, 16)
..quadraticBezierTo(38, 12, 30, 18)
..quadraticBezierTo(20, 24, 20, 38)
..quadraticBezierTo(20, 50, 26, 58)
..quadraticBezierTo(30, 64, 32, 76)
..lineTo(32, 90));
    _path(c, Path()..moveTo(50, 16)
..quadraticBezierTo(62, 12, 70, 18)
..quadraticBezierTo(80, 24, 80, 38)
..quadraticBezierTo(80, 50, 74, 58)
..quadraticBezierTo(70, 64, 68, 76)
..lineTo(68, 90));
    _path(c, Path()..moveTo(31, 20)
..quadraticBezierTo(44, 14, 56, 14)
..quadraticBezierTo(69, 14, 69, 20));
    _path(c, Path()..moveTo(24, 26)
..quadraticBezierTo(30, 34, 30, 44)
..quadraticBezierTo(30, 54, 24, 60));
    _path(c, Path()..moveTo(76, 26)
..quadraticBezierTo(70, 34, 70, 44)
..quadraticBezierTo(70, 54, 76, 60));
    _path(c, Path()..moveTo(28, 42)
..quadraticBezierTo(38, 36, 62, 36)
..quadraticBezierTo(72, 36, 72, 42));
    _path(c, Path()..moveTo(36, 44)
..quadraticBezierTo(42, 52, 42, 62)
..quadraticBezierTo(42, 72, 36, 78));
    _path(c, Path()..moveTo(64, 44)
..quadraticBezierTo(58, 52, 58, 62)
..quadraticBezierTo(58, 72, 64, 78));
  }

  void _biceps(Canvas c) {
    _path(c, Path()..moveTo(54, 10)
..quadraticBezierTo(66, 8, 70, 16)
..lineTo(74, 50)
..quadraticBezierTo(74, 58, 66, 62)
..quadraticBezierTo(48, 66, 30, 66)
..quadraticBezierTo(18, 64, 20, 50)
..quadraticBezierTo(24, 44, 40, 42)
..quadraticBezierTo(56, 41, 62, 48)
..lineTo(56, 18)
..quadraticBezierTo(54, 12, 54, 10));
    _path(c, Path()..moveTo(28, 46)
..quadraticBezierTo(44, 38, 58, 44));
    _path(c, Path()..moveTo(62, 50)
..quadraticBezierTo(68, 56, 68, 62));
    _circle(c, 60, 12, 4);
  }

  void _triceps(Canvas c) {
    _path(c, Path()..moveTo(46, 10)
..quadraticBezierTo(34, 8, 30, 16)
..lineTo(26, 50)
..quadraticBezierTo(26, 58, 34, 62)
..quadraticBezierTo(52, 66, 70, 66)
..quadraticBezierTo(82, 64, 80, 50)
..quadraticBezierTo(76, 44, 60, 42)
..quadraticBezierTo(44, 41, 38, 48)
..lineTo(44, 18)
..quadraticBezierTo(46, 12, 46, 10));
    _path(c, Path()..moveTo(72, 46)
..quadraticBezierTo(56, 38, 42, 44));
    _path(c, Path()..moveTo(38, 50)
..quadraticBezierTo(32, 56, 32, 62));
    _circle(c, 40, 12, 4);
  }

  void _abdomen(Canvas c) {
    _path(c, Path()..moveTo(28, 12)
..quadraticBezierTo(36, 4, 50, 6)
..quadraticBezierTo(64, 4, 72, 12)
..quadraticBezierTo(80, 20, 80, 36)
..quadraticBezierTo(80, 56, 74, 72)
..quadraticBezierTo(70, 84, 60, 88)
..lineTo(40, 88)
..quadraticBezierTo(30, 84, 26, 72)
..quadraticBezierTo(20, 56, 20, 36)
..quadraticBezierTo(20, 20, 28, 12));
    _path(c, Path()..moveTo(33, 16)
..quadraticBezierTo(42, 22, 50, 22)
..quadraticBezierTo(58, 22, 67, 16));
    _path(c, Path()..moveTo(26, 28)
..quadraticBezierTo(38, 34, 50, 34)
..quadraticBezierTo(62, 34, 74, 28));
    _line(c, 50, 34, 50, 84);
    _path(c, Path()..moveTo(32, 44)
..lineTo(68, 44));
    _path(c, Path()..moveTo(32, 58)
..lineTo(68, 58));
    _path(c, Path()..moveTo(33, 72)
..lineTo(67, 72));
    _path(c, Path()..moveTo(41, 34)
..quadraticBezierTo(40, 78, 42, 84));
    _path(c, Path()..moveTo(59, 34)
..quadraticBezierTo(60, 78, 58, 84));
    _path(c, Path()..moveTo(24, 40)
..quadraticBezierTo(22, 58, 26, 72));
    _path(c, Path()..moveTo(76, 40)
..quadraticBezierTo(78, 58, 74, 72));
    _path(c, Path()..moveTo(32, 88)
..quadraticBezierTo(44, 82, 50, 84)
..quadraticBezierTo(56, 82, 68, 88));
  }

  void _gluteos(Canvas c) {
    _path(c, Path()..moveTo(18, 26)
..quadraticBezierTo(26, 16, 50, 18)
..quadraticBezierTo(74, 16, 82, 26)
..quadraticBezierTo(88, 36, 84, 48)
..quadraticBezierTo(79, 62, 66, 70)
..quadraticBezierTo(56, 76, 50, 74)
..quadraticBezierTo(44, 76, 34, 70)
..quadraticBezierTo(21, 62, 16, 48)
..quadraticBezierTo(12, 36, 18, 26));
    _line(c, 50, 18, 50, 74);
    _path(c, Path()..moveTo(24, 30)
..quadraticBezierTo(34, 20, 48, 24));
    _path(c, Path()..moveTo(76, 30)
..quadraticBezierTo(66, 20, 52, 24));
    _path(c, Path()..moveTo(22, 46)
..quadraticBezierTo(32, 56, 44, 60));
    _path(c, Path()..moveTo(78, 46)
..quadraticBezierTo(68, 56, 56, 60));
    _line(c, 50, 74, 50, 84);
  }

  void _posterior(Canvas c) {
    _path(c, Path()..moveTo(18, 22)
..quadraticBezierTo(34, 18, 52, 32)
..quadraticBezierTo(66, 44, 70, 56)
..quadraticBezierTo(72, 66, 64, 72)
..quadraticBezierTo(56, 78, 56, 88)
..lineTo(62, 90)
..quadraticBezierTo(68, 90, 70, 86)
..lineTo(76, 82)
..quadraticBezierTo(78, 74, 78, 66)
..quadraticBezierTo(78, 52, 68, 38)
..quadraticBezierTo(52, 20, 30, 14)
..quadraticBezierTo(22, 12, 18, 22));
    _path(c, Path()..moveTo(30, 24)
..quadraticBezierTo(42, 30, 52, 42)
..quadraticBezierTo(60, 52, 62, 62));
    _path(c, Path()..moveTo(52, 52)
..quadraticBezierTo(60, 58, 62, 68));
    _line(c, 56, 88, 70, 90);
  }

  void _panturrilha(Canvas c) {
    _path(c, Path()..moveTo(42, 10)
..quadraticBezierTo(34, 14, 32, 28)
..quadraticBezierTo(30, 44, 36, 54)
..quadraticBezierTo(42, 62, 44, 70)
..lineTo(46, 86)
..lineTo(54, 86)
..lineTo(52, 70)
..quadraticBezierTo(54, 60, 60, 52)
..quadraticBezierTo(66, 42, 64, 28)
..quadraticBezierTo(62, 14, 52, 10)
..quadraticBezierTo(46, 8, 42, 10));
    _path(c, Path()..moveTo(48, 14)
..quadraticBezierTo(44, 28, 48, 44)
..quadraticBezierTo(50, 54, 50, 64));
    _path(c, Path()..moveTo(38, 24)
..quadraticBezierTo(44, 34, 42, 46));
    _path(c, Path()..moveTo(42, 58)
..quadraticBezierTo(50, 54, 56, 56));
    _line(c, 40, 90, 58, 90);
  }

  void _lombar(Canvas c) {
    _path(c, Path()..moveTo(28, 14)
..quadraticBezierTo(36, 8, 50, 10)
..quadraticBezierTo(64, 8, 72, 14)
..quadraticBezierTo(78, 22, 78, 36)
..quadraticBezierTo(78, 52, 72, 64)
..quadraticBezierTo(67, 73, 60, 76));
    _path(c, Path()..moveTo(28, 14)
..quadraticBezierTo(22, 22, 22, 36)
..quadraticBezierTo(22, 52, 28, 64)
..quadraticBezierTo(33, 73, 40, 76));
    _line(c, 50, 10, 50, 78);
    _path(c, Path()..moveTo(40, 12)
..quadraticBezierTo(50, 16, 60, 12));
    _path(c, Path()..moveTo(34, 26)
..quadraticBezierTo(42, 30, 50, 30)
..quadraticBezierTo(58, 30, 66, 26));
    _path(c, Path()..moveTo(36, 40)
..quadraticBezierTo(42, 44, 50, 44)
..quadraticBezierTo(58, 44, 64, 40));
    _path(c, Path()..moveTo(42, 56)
..quadraticBezierTo(50, 58, 58, 56));
    _path(c, Path()..moveTo(46, 60)
..quadraticBezierTo(40, 68, 38, 78));
    _path(c, Path()..moveTo(54, 60)
..quadraticBezierTo(60, 68, 62, 78));
    _path(c, Path()..moveTo(40, 78)
..quadraticBezierTo(50, 74, 60, 78));
  }

  void _antebraco(Canvas c) {
    _path(c, Path()..moveTo(34, 10)
..quadraticBezierTo(44, 6, 52, 10)
..quadraticBezierTo(62, 14, 64, 24)
..quadraticBezierTo(66, 34, 60, 44)
..quadraticBezierTo(56, 52, 58, 60)
..quadraticBezierTo(58, 66, 56, 70));
    _path(c, Path()..moveTo(34, 10)
..quadraticBezierTo(26, 18, 26, 30)
..quadraticBezierTo(26, 40, 34, 48)
..quadraticBezierTo(40, 54, 42, 62)
..quadraticBezierTo(42, 68, 40, 72));
    _path(c, Path()..moveTo(50, 74)
..quadraticBezierTo(40, 78, 32, 82)
..quadraticBezierTo(28, 84, 30, 88)
..quadraticBezierTo(32, 92, 38, 92)
..quadraticBezierTo(48, 92, 56, 86)
..quadraticBezierTo(62, 82, 66, 84)
..quadraticBezierTo(68, 88, 64, 92)
..quadraticBezierTo(52, 98, 38, 96)
..quadraticBezierTo(26, 94, 24, 88)
..quadraticBezierTo(22, 82, 30, 78)
..quadraticBezierTo(40, 72, 52, 70));
    _path(c, Path()..moveTo(42, 20)
..quadraticBezierTo(52, 28, 54, 40)
..quadraticBezierTo(56, 56, 52, 68));
    _path(c, Path()..moveTo(44, 24)
..quadraticBezierTo(36, 34, 40, 50)
..quadraticBezierTo(42, 60, 46, 66));
  }

  void _trapezio(Canvas c) {
    _circle(c, 50, 10, 6);
    _line(c, 50, 16, 50, 22);
    _path(c, Path()..moveTo(50, 22)
..quadraticBezierTo(40, 20, 34, 26)
..quadraticBezierTo(26, 32, 26, 44)
..quadraticBezierTo(26, 54, 30, 60)
..quadraticBezierTo(32, 64, 30, 76)
..lineTo(30, 88));
    _path(c, Path()..moveTo(50, 22)
..quadraticBezierTo(60, 20, 66, 26)
..quadraticBezierTo(74, 32, 74, 44)
..quadraticBezierTo(74, 54, 70, 60)
..quadraticBezierTo(68, 64, 70, 76)
..lineTo(70, 88));
    _path(c, Path()..moveTo(32, 26)
..quadraticBezierTo(44, 18, 56, 18)
..quadraticBezierTo(68, 18, 68, 26));
    _path(c, Path()..moveTo(30, 32)
..quadraticBezierTo(42, 26, 50, 28)
..quadraticBezierTo(58, 26, 70, 32));
    _line(c, 50, 30, 50, 84);
    _path(c, Path()..moveTo(34, 46)
..quadraticBezierTo(36, 56, 34, 64));
    _path(c, Path()..moveTo(66, 46)
..quadraticBezierTo(64, 56, 66, 64));
  }

  void _pescoco(Canvas c) {
    _circle(c, 50, 16, 8);
    _path(c, Path()..moveTo(42, 22)
..quadraticBezierTo(50, 18, 58, 22)
..quadraticBezierTo(64, 26, 64, 38)
..quadraticBezierTo(64, 52, 58, 62)
..quadraticBezierTo(53, 68, 50, 72));
    _path(c, Path()..moveTo(42, 22)
..quadraticBezierTo(36, 26, 36, 38)
..quadraticBezierTo(36, 52, 42, 62)
..quadraticBezierTo(47, 68, 50, 72));
    _path(c, Path()..moveTo(40, 34)
..quadraticBezierTo(50, 30, 60, 34));
    _path(c, Path()..moveTo(42, 48)
..quadraticBezierTo(50, 44, 58, 48));
    _path(c, Path()..moveTo(36, 60)
..quadraticBezierTo(44, 54, 56, 54)
..quadraticBezierTo(64, 54, 64, 60));
    _line(c, 50, 74, 50, 86);
  }

  void _cardio(Canvas c) {
    _path(c, Path()..moveTo(50, 82)
..cubicTo(18, 58, 14, 28, 34, 20)
..cubicTo(44, 14, 48, 22, 50, 30)
..cubicTo(52, 22, 56, 14, 66, 20)
..cubicTo(86, 28, 82, 58, 50, 82));
    _path(c, Path()..moveTo(12, 48)
..lineTo(30, 48)
..lineTo(36, 34)
..lineTo(44, 62)
..lineTo(52, 42)
..lineTo(58, 48)
..lineTo(88, 48));
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
