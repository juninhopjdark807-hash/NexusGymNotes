import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone monoline de grupo muscular — visual alinhado às prévias aprovadas.
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
          // Ícone maior no círculo para legibilidade (~62%).
          size: size * 0.62,
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
    // Padding interno para o stroke não cortar.
    final pad = side * 0.06;
    final inner = side - pad * 2;
    final scale = inner / 100.0;
    // Stroke em px de tela → compensado pela escala do canvas.
    final swScreen = (side * 0.08).clamp(1.7, 2.6);
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
        _barbell(canvas);
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

  // ---- PEITO (prévia: torso frontal peitoral) ----
  void _peito(Canvas c) {
    // Contorno externo ombros + braços + base peito.
    final outline = Path()
      ..moveTo(22, 78) // braço esq baixo
      ..lineTo(20, 48)
      ..quadraticBezierTo(18, 28, 28, 18) // ombro esq
      ..quadraticBezierTo(38, 10, 46, 22) // clavícula esq → centro
      ..lineTo(50, 28) // entalhe peitoral
      ..lineTo(54, 22)
      ..quadraticBezierTo(62, 10, 72, 18) // ombro dir
      ..quadraticBezierTo(82, 28, 80, 48)
      ..lineTo(78, 78); // braço dir baixo
    _path(c, outline);

    // Arco inferior dos peitorais (U).
    final pecs = Path()
      ..moveTo(28, 42)
      ..quadraticBezierTo(36, 58, 50, 62)
      ..quadraticBezierTo(64, 58, 72, 42);
    _path(c, pecs);

    // Separação superior dos peitorais.
    _line(c, 42, 30, 50, 36);
    _line(c, 58, 30, 50, 36);

    // Marcas peitorais.
    _circle(c, 38, 48, 2.2);
    _circle(c, 62, 48, 2.2);
  }

  // ---- COSTAS (prévia: costas em V + coluna + lâminas) ----
  void _costas(Canvas c) {
    // Contorno costas.
    final outline = Path()
      ..moveTo(22, 80)
      ..lineTo(18, 42)
      ..quadraticBezierTo(16, 22, 28, 14) // ombro esq
      ..quadraticBezierTo(38, 8, 50, 12) // trapézio
      ..quadraticBezierTo(62, 8, 72, 14)
      ..quadraticBezierTo(84, 22, 82, 42)
      ..lineTo(78, 80);
    _path(c, outline);

    // Coluna.
    _line(c, 50, 16, 50, 78);

    // Lâminas / dorsais.
    final left = Path()
      ..moveTo(28, 28)
      ..quadraticBezierTo(36, 40, 42, 55)
      ..quadraticBezierTo(34, 50, 28, 42);
    _path(c, left);
    final right = Path()
      ..moveTo(72, 28)
      ..quadraticBezierTo(64, 40, 58, 55)
      ..quadraticBezierTo(66, 50, 72, 42);
    _path(c, right);

    // Braços.
    _line(c, 22, 30, 16, 70);
    _line(c, 78, 30, 84, 70);
  }

  // ---- PERNAS (prévia: coxas de frente com V interno) ----
  void _pernas(Canvas c) {
    // Contorno externo esquerdo.
    final outerL = Path()
      ..moveTo(28, 8)
      ..lineTo(22, 45)
      ..quadraticBezierTo(20, 62, 26, 92);
    _path(c, outerL);
    // Contorno externo direito.
    final outerR = Path()
      ..moveTo(72, 8)
      ..lineTo(78, 45)
      ..quadraticBezierTo(80, 62, 74, 92);
    _path(c, outerR);

    // Parte superior (quadril).
    _line(c, 28, 8, 72, 8);

    // V interno (adutores) — marca da prévia.
    final inner = Path()
      ..moveTo(42, 12)
      ..quadraticBezierTo(46, 40, 50, 55)
      ..quadraticBezierTo(54, 40, 58, 12);
    _path(c, inner);

    // Continuação das pernas internas para baixo.
    _line(c, 50, 55, 42, 92);
    _line(c, 50, 55, 58, 92);

    // Marcas dos joelhos / vastus.
    final kneeL = Path()
      ..moveTo(28, 58)
      ..quadraticBezierTo(34, 62, 38, 58);
    _path(c, kneeL);
    final kneeR = Path()
      ..moveTo(72, 58)
      ..quadraticBezierTo(66, 62, 62, 58);
    _path(c, kneeR);
  }

  // ---- OMBROS (prévia: deltóides) ----
  void _ombros(Canvas c) {
    // Ombro esquerdo.
    final l = Path()
      ..moveTo(50, 22)
      ..cubicTo(38, 14, 22, 22, 20, 38)
      ..cubicTo(18, 52, 28, 58, 36, 55)
      ..cubicTo(40, 42, 44, 32, 50, 28);
    _path(c, l);
    // Ombro direito.
    final r = Path()
      ..moveTo(50, 22)
      ..cubicTo(62, 14, 78, 22, 80, 38)
      ..cubicTo(82, 52, 72, 58, 64, 55)
      ..cubicTo(60, 42, 56, 32, 50, 28);
    _path(c, r);
    // Tronco.
    _line(c, 38, 55, 38, 88);
    _line(c, 62, 55, 62, 88);
    // Pescoço.
    _line(c, 50, 12, 50, 22);
    _circle(c, 50, 10, 5);
  }

  // ---- BÍCEPS (prévia: flex clássico) ----
  void _biceps(Canvas c) {
    // Braço flexionado.
    final arm = Path()
      ..moveTo(28, 82) // punho
      ..quadraticBezierTo(22, 70, 28, 55) // antebraço
      ..quadraticBezierTo(36, 42, 48, 38) // cotovelo interno
      ..quadraticBezierTo(62, 32, 72, 28) // bíceps → ombro
      ..quadraticBezierTo(80, 24, 78, 36)
      ..quadraticBezierTo(70, 48, 58, 52) // volta do bíceps
      ..quadraticBezierTo(48, 58, 46, 70)
      ..quadraticBezierTo(44, 82, 36, 88);
    _path(c, arm);
    // Pico do bíceps.
    final peak = Path()
      ..moveTo(55, 30)
      ..quadraticBezierTo(68, 18, 74, 30);
    _path(c, peak);
  }

  // ---- TRÍCEPS (prévia: braço flex outro ângulo) ----
  void _triceps(Canvas c) {
    final arm = Path()
      ..moveTo(30, 30)
      ..quadraticBezierTo(38, 22, 52, 28)
      ..quadraticBezierTo(68, 36, 72, 52)
      ..quadraticBezierTo(74, 68, 62, 80)
      ..quadraticBezierTo(50, 88, 42, 78)
      ..quadraticBezierTo(36, 66, 42, 54)
      ..quadraticBezierTo(48, 44, 42, 34)
      ..quadraticBezierTo(34, 28, 30, 30);
    _path(c, arm);
    _line(c, 48, 40, 58, 62);
  }

  // ---- ABDÔMEN (prévia: six-pack) ----
  void _abdomen(Canvas c) {
    final torso = Path()
      ..moveTo(32, 12)
      ..lineTo(68, 12)
      ..lineTo(74, 40)
      ..lineTo(70, 88)
      ..lineTo(30, 88)
      ..lineTo(26, 40)
      ..close();
    _path(c, torso);
    _line(c, 50, 14, 50, 86);
    _line(c, 30, 34, 70, 34);
    _line(c, 28, 52, 72, 52);
    _line(c, 30, 70, 70, 70);
  }

  // ---- GLÚTEOS (prévia: posterior glúteo) ----
  void _gluteos(Canvas c) {
    final shape = Path()
      ..moveTo(30, 10)
      ..lineTo(36, 10)
      ..quadraticBezierTo(42, 28, 46, 42)
      ..lineTo(54, 42)
      ..quadraticBezierTo(58, 28, 64, 10)
      ..lineTo(70, 10)
      ..lineTo(74, 40)
      ..quadraticBezierTo(76, 70, 68, 90)
      ..lineTo(56, 90)
      ..lineTo(50, 55)
      ..lineTo(44, 90)
      ..lineTo(32, 90)
      ..quadraticBezierTo(24, 70, 26, 40)
      ..close();
    _path(c, shape);
    _line(c, 50, 42, 50, 88);
  }

  // ---- POSTERIOR (prévia: perna lateral flexionada) ----
  void _posterior(Canvas c) {
    final leg = Path()
      ..moveTo(38, 12)
      ..lineTo(48, 40)
      ..lineTo(40, 52)
      ..quadraticBezierTo(32, 62, 42, 88)
      ..lineTo(58, 86)
      ..quadraticBezierTo(68, 70, 62, 55)
      ..lineTo(58, 40)
      ..quadraticBezierTo(55, 22, 48, 12);
    _path(c, leg);
    // Hamstring curve.
    final ham = Path()
      ..moveTo(48, 28)
      ..quadraticBezierTo(62, 38, 56, 52);
    _path(c, ham);
  }

  // ---- PANTURRILHA (prévia: canela + panturrilha) ----
  void _panturrilha(Canvas c) {
    final leg = Path()
      ..moveTo(44, 8)
      ..lineTo(42, 36)
      ..quadraticBezierTo(34, 48, 40, 62)
      ..quadraticBezierTo(42, 72, 38, 90)
      ..lineTo(58, 90)
      ..quadraticBezierTo(62, 72, 58, 60)
      ..quadraticBezierTo(68, 48, 56, 34)
      ..lineTo(54, 8);
    _path(c, leg);
    final calf = Path()
      ..moveTo(42, 42)
      ..quadraticBezierTo(55, 48, 52, 62);
    _path(c, calf);
  }

  // ---- LOMBAR ----
  void _lombar(Canvas c) {
    _line(c, 50, 10, 50, 90);
    for (final y in [22.0, 38.0, 54.0, 70.0]) {
      _circle(c, 50, y, 5);
    }
    _line(c, 28, 60, 72, 60);
  }

  // ---- ANTEBRAÇO ----
  void _antebraco(Canvas c) {
    final arm = Path()
      ..moveTo(28, 18)
      ..lineTo(40, 58)
      ..lineTo(60, 58)
      ..lineTo(72, 18);
    _path(c, arm);
    final hand = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 58, 24, 24),
          const Radius.circular(6),
        ),
      );
    _path(c, hand);
  }

  // ---- TRAPÉZIO ----
  void _trapezio(Canvas c) {
    _circle(c, 50, 16, 8);
    _line(c, 50, 24, 50, 48);
    _line(c, 18, 48, 82, 48);
    _line(c, 24, 48, 50, 26);
    _line(c, 76, 48, 50, 26);
    _line(c, 32, 48, 32, 88);
    _line(c, 68, 48, 68, 88);
  }

  // ---- PESCOÇO ----
  void _pescoco(Canvas c) {
    _circle(c, 50, 22, 12);
    _line(c, 50, 34, 50, 82);
    _line(c, 36, 50, 64, 50);
    _line(c, 38, 64, 62, 64);
  }

  // ---- CARDIO (prévia: coração + ECG) ----
  void _cardio(Canvas c) {
    final heart = Path()
      ..moveTo(50, 82)
      ..cubicTo(18, 58, 16, 32, 34, 22)
      ..cubicTo(42, 16, 48, 22, 50, 30)
      ..cubicTo(52, 22, 58, 16, 66, 22)
      ..cubicTo(84, 32, 82, 58, 50, 82)
      ..close();
    _path(c, heart);
    final pulse = Path()
      ..moveTo(10, 50)
      ..lineTo(28, 50)
      ..lineTo(34, 36)
      ..lineTo(42, 64)
      ..lineTo(50, 44)
      ..lineTo(56, 50)
      ..lineTo(90, 50);
    _path(c, pulse);
  }

  // ---- FULL BODY / OUTROS (prévia: barra) ----
  void _barbell(Canvas c) {
    // Anilha esq externa.
    _path(
      c,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 30, 14, 40),
            const Radius.circular(4),
          ),
        ),
    );
    // Anilha esq interna.
    _path(
      c,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 36, 10, 28),
            const Radius.circular(3),
          ),
        ),
    );
    // Barra.
    _line(c, 30, 50, 70, 50);
    // Anilha dir interna.
    _path(
      c,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(70, 36, 10, 28),
            const Radius.circular(3),
          ),
        ),
    );
    // Anilha dir externa.
    _path(
      c,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(78, 30, 14, 40),
            const Radius.circular(4),
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _MusclePainter old) =>
      old.group != group || old.color != color;
}
