import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone vetorial de grupo muscular — linguagem visual unificada.
///
/// Silhuetas/lineares minimalistas, legíveis em ~18–24 px, desenhadas
/// com [CustomPainter] (sem dependência extra). O mapeamento usa
/// [MuscleGroup], não o texto do card.
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
    final c = color ?? (active ? C.accentSecondary : C.textDim);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MuscleSilhouettePainter(group: group, color: c),
      ),
    );
  }
}

/// Badge circular com ícone de grupo muscular (cards da home / picker).
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
        color: active ? C.accentSoft : C.surface2,
        border: Border.all(
          color: active ? C.accent.withValues(alpha: 0.45) : C.stroke,
          width: 1.2,
        ),
      ),
      child: Center(
        child: MuscleIcon(
          group: group,
          size: size * 0.52,
          active: active,
        ),
      ),
    );
  }
}

/// Alias reutilizável para o mesmo sistema de ícones.
typedef WorkoutIcon = MuscleIcon;

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _MuscleSilhouettePainter extends CustomPainter {
  _MuscleSilhouettePainter({required this.group, required this.color});

  final MuscleGroup group;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.width * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.shortestSide;
    // Normaliza o desenho em um canvas 0–24 e escala.
    canvas.save();
    canvas.scale(s / 24, s / 24);

    switch (group) {
      case MuscleGroup.peito:
        _paintChest(canvas, stroke, fill);
      case MuscleGroup.costas:
        _paintBack(canvas, stroke, fill);
      case MuscleGroup.ombros:
        _paintShoulders(canvas, stroke, fill);
      case MuscleGroup.biceps:
        _paintBiceps(canvas, stroke, fill);
      case MuscleGroup.triceps:
        _paintTriceps(canvas, stroke, fill);
      case MuscleGroup.quadriceps:
      case MuscleGroup.pernas:
        _paintLegs(canvas, stroke, fill);
      case MuscleGroup.posteriorCoxa:
        _paintHamstrings(canvas, stroke, fill);
      case MuscleGroup.gluteos:
        _paintGlutes(canvas, stroke, fill);
      case MuscleGroup.panturrilhas:
        _paintCalves(canvas, stroke, fill);
      case MuscleGroup.abdomen:
        _paintAbs(canvas, stroke, fill);
      case MuscleGroup.lombar:
        _paintLowerBack(canvas, stroke, fill);
      case MuscleGroup.antebraco:
        _paintForearm(canvas, stroke, fill);
      case MuscleGroup.trapezio:
        _paintTraps(canvas, stroke, fill);
      case MuscleGroup.pescoco:
        _paintNeck(canvas, stroke, fill);
      case MuscleGroup.cardio:
        _paintCardio(canvas, stroke, fill);
      case MuscleGroup.outros:
        _paintFullBody(canvas, stroke, fill);
    }

    canvas.restore();
  }

  /// Peito — peitoral em “W” / dois arcos simétricos.
  void _paintChest(Canvas c, Paint s, Paint f) {
    final p = Path()
      ..moveTo(4, 9)
      ..cubicTo(6, 5.5, 10, 5.5, 12, 8.5)
      ..cubicTo(14, 5.5, 18, 5.5, 20, 9)
      ..cubicTo(20.5, 12, 17.5, 16, 12, 18)
      ..cubicTo(6.5, 16, 3.5, 12, 4, 9)
      ..close();
    c.drawPath(p, s);
    // Linha central do peitoral.
    c.drawLine(const Offset(12, 8.5), const Offset(12, 17.2), s);
  }

  /// Costas — tronco + “V” dorsal (lâminas).
  void _paintBack(Canvas c, Paint s, Paint f) {
    // Contorno ombros → cintura.
    final outline = Path()
      ..moveTo(5, 6.5)
      ..lineTo(19, 6.5)
      ..lineTo(15.5, 19)
      ..lineTo(8.5, 19)
      ..close();
    c.drawPath(outline, s);
    // Coluna.
    c.drawLine(const Offset(12, 7), const Offset(12, 18.5), s);
    // Lâminas (V).
    c.drawLine(const Offset(7, 9), const Offset(12, 14), s);
    c.drawLine(const Offset(17, 9), const Offset(12, 14), s);
  }

  /// Ombros — deltóides arredondados nos dois lados.
  void _paintShoulders(Canvas c, Paint s, Paint f) {
    // Cabeça / pescoço simples (âncora).
    c.drawCircle(const Offset(12, 6.5), 2.2, s);
    c.drawLine(const Offset(12, 8.7), const Offset(12, 12), s);
    // Deltóides.
    c.drawArc(
      const Rect.fromLTWH(3.5, 8.5, 7, 7),
      -0.2,
      math.pi * 1.1,
      false,
      s,
    );
    c.drawArc(
      const Rect.fromLTWH(13.5, 8.5, 7, 7),
      math.pi - 0.9,
      math.pi * 1.1,
      false,
      s,
    );
    // Braços curtos.
    c.drawLine(const Offset(5.5, 14.5), const Offset(4, 19), s);
    c.drawLine(const Offset(18.5, 14.5), const Offset(20, 19), s);
  }

  /// Bíceps — braço flexionado com pico do bíceps.
  void _paintBiceps(Canvas c, Paint s, Paint f) {
    // Antebraço.
    final arm = Path()
      ..moveTo(6, 18)
      ..quadraticBezierTo(7, 14, 10, 12)
      ..quadraticBezierTo(14, 9.5, 17, 7);
    c.drawPath(arm, s);
    // Bíceps (arco superior).
    c.drawArc(
      const Rect.fromLTWH(8.5, 7.5, 7, 6.5),
      math.pi * 0.95,
      math.pi * 1.15,
      false,
      s,
    );
    // Ombro.
    c.drawCircle(const Offset(17.5, 6.5), 2.0, s);
  }

  /// Tríceps — braço estendido com volume posterior.
  void _paintTriceps(Canvas c, Paint s, Paint f) {
    // Braço vertical.
    c.drawLine(const Offset(12, 5), const Offset(12, 14), s);
    // Antebraço para o lado.
    c.drawLine(const Offset(12, 14), const Offset(18, 19), s);
    // Volume do tríceps (lado).
    final p = Path()
      ..moveTo(12, 7)
      ..quadraticBezierTo(16.5, 9, 14.5, 13.5)
      ..quadraticBezierTo(12.5, 12, 12, 11);
    c.drawPath(p, s);
    c.drawCircle(const Offset(12, 5), 1.8, s);
  }

  /// Pernas / quadríceps — duas pernas estilizadas.
  void _paintLegs(Canvas c, Paint s, Paint f) {
    // Cintura.
    c.drawLine(const Offset(8, 5), const Offset(16, 5), s);
    // Coxa + panturrilha esquerdas.
    final left = Path()
      ..moveTo(9.5, 5)
      ..lineTo(8, 13)
      ..lineTo(9, 19)
      ..moveTo(8, 13)
      ..lineTo(10.5, 12.5);
    c.drawPath(left, s);
    // Direita.
    final right = Path()
      ..moveTo(14.5, 5)
      ..lineTo(16, 13)
      ..lineTo(15, 19)
      ..moveTo(16, 13)
      ..lineTo(13.5, 12.5);
    c.drawPath(right, s);
    // Joelho (marca do quadríceps).
    c.drawCircle(const Offset(8.3, 12.8), 1.1, s);
    c.drawCircle(const Offset(15.7, 12.8), 1.1, s);
  }

  /// Posterior de coxa — perna de perfil com ênfase no posterior.
  void _paintHamstrings(Canvas c, Paint s, Paint f) {
    final leg = Path()
      ..moveTo(11, 4.5)
      ..lineTo(10, 12)
      ..quadraticBezierTo(8, 14.5, 10.5, 19)
      ..moveTo(10, 12)
      ..quadraticBezierTo(14.5, 13, 13, 18.5);
    c.drawPath(leg, s);
    // Arco do posterior.
    c.drawArc(
      const Rect.fromLTWH(7.5, 8, 6, 7),
      -0.3,
      math.pi * 0.9,
      false,
      s,
    );
  }

  /// Glúteos — dois arcos simétricos.
  void _paintGlutes(Canvas c, Paint s, Paint f) {
    c.drawArc(
      const Rect.fromLTWH(4, 7, 8.5, 11),
      math.pi * 1.05,
      math.pi * 1.1,
      false,
      s,
    );
    c.drawArc(
      const Rect.fromLTWH(11.5, 7, 8.5, 11),
      math.pi * 0.85,
      math.pi * 1.1,
      false,
      s,
    );
    c.drawLine(const Offset(12, 8), const Offset(12, 17), s);
  }

  /// Panturrilhas — canela + diamante do gastrocnêmio.
  void _paintCalves(Canvas c, Paint s, Paint f) {
    c.drawLine(const Offset(12, 4), const Offset(12, 11), s);
    final diamond = Path()
      ..moveTo(12, 10)
      ..lineTo(16, 14)
      ..lineTo(12, 19.5)
      ..lineTo(8, 14)
      ..close();
    c.drawPath(diamond, s);
  }

  /// Abdômen — grid 2×3 (six-pack simplificado).
  void _paintAbs(Canvas c, Paint s, Paint f) {
    final r = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6.5, 4.5, 11, 15),
      const Radius.circular(2.5),
    );
    c.drawRRect(r, s);
    c.drawLine(const Offset(12, 4.5), const Offset(12, 19.5), s);
    c.drawLine(const Offset(6.5, 9.5), const Offset(17.5, 9.5), s);
    c.drawLine(const Offset(6.5, 14.5), const Offset(17.5, 14.5), s);
  }

  /// Lombar — coluna inferior + suporte.
  void _paintLowerBack(Canvas c, Paint s, Paint f) {
    c.drawLine(const Offset(12, 5), const Offset(12, 18), s);
    // Vértebras.
    for (final y in [7.0, 10.0, 13.0, 16.0]) {
      c.drawCircle(Offset(12, y), 1.3, s);
    }
    // Suporte lateral.
    c.drawLine(const Offset(7, 14), const Offset(17, 14), s);
    c.drawLine(const Offset(8, 17), const Offset(16, 17), s);
  }

  /// Antebraço — antebraço + punho.
  void _paintForearm(Canvas c, Paint s, Paint f) {
    final arm = Path()
      ..moveTo(7, 6)
      ..lineTo(10, 14)
      ..lineTo(14, 14)
      ..lineTo(17, 6);
    c.drawPath(arm, s);
    // Punho / mão.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9.2, 14, 5.6, 5),
        const Radius.circular(1.5),
      ),
      s,
    );
  }

  /// Trapézio — ombros elevados + trapézio em T.
  void _paintTraps(Canvas c, Paint s, Paint f) {
    c.drawLine(const Offset(5, 10), const Offset(19, 10), s);
    c.drawLine(const Offset(12, 6), const Offset(12, 18), s);
    c.drawLine(const Offset(7, 10), const Offset(12, 6), s);
    c.drawLine(const Offset(17, 10), const Offset(12, 6), s);
    c.drawCircle(const Offset(12, 5.2), 1.6, s);
  }

  /// Pescoço — coluna cervical.
  void _paintNeck(Canvas c, Paint s, Paint f) {
    c.drawCircle(const Offset(12, 6), 3.2, s);
    c.drawLine(const Offset(12, 9.2), const Offset(12, 17), s);
    c.drawLine(const Offset(9, 12), const Offset(15, 12), s);
    c.drawLine(const Offset(9.5, 15), const Offset(14.5, 15), s);
  }

  /// Cardio — coração linear.
  void _paintCardio(Canvas c, Paint s, Paint f) {
    final heart = Path()
      ..moveTo(12, 19)
      ..cubicTo(5, 14, 3.5, 9, 7.5, 6.5)
      ..cubicTo(9.5, 5.2, 11.2, 6.2, 12, 8)
      ..cubicTo(12.8, 6.2, 14.5, 5.2, 16.5, 6.5)
      ..cubicTo(20.5, 9, 19, 14, 12, 19)
      ..close();
    c.drawPath(heart, s);
  }

  /// Full body / outros — figura geométrica simples (halter).
  void _paintFullBody(Canvas c, Paint s, Paint f) {
    // Halter minimalista (identidade fitness genérica).
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 9, 4.5, 6),
        const Radius.circular(1.2),
      ),
      s,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16.5, 9, 4.5, 6),
        const Radius.circular(1.2),
      ),
      s,
    );
    c.drawLine(const Offset(7.5, 12), const Offset(16.5, 12), s);
  }

  @override
  bool shouldRepaint(covariant _MuscleSilhouettePainter oldDelegate) =>
      oldDelegate.group != group || oldDelegate.color != color;
}
