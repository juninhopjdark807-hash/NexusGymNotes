import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone vetorial monoline de grupo muscular (identidade NexusGym).
///
/// Silhuetas fitness minimalistas, legíveis em ~20–24 px, desenhadas
/// com [CustomPainter]. Mapeamento por [MuscleGroup].
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

/// Badge circular roxo com ícone (cards da home / picker).
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
          color: active ? C.accent.withValues(alpha: 0.55) : C.stroke,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: C.accent.withValues(alpha: 0.22),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Center(
        child: MuscleIcon(
          group: group,
          // Proporção similar às prévias (~52% do círculo).
          size: size * 0.55,
          active: active,
        ),
      ),
    );
  }
}

/// Alias reutilizável.
typedef WorkoutIcon = MuscleIcon;

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
      ..strokeWidth = math.max(1.5, size.width * 0.085)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.shortestSide;
    canvas.save();
    // Canvas lógico 0–24.
    canvas.scale(s / 24, s / 24);

    switch (group) {
      case MuscleGroup.peito:
        _peito(canvas, stroke);
      case MuscleGroup.costas:
        _costas(canvas, stroke);
      case MuscleGroup.ombros:
        _ombros(canvas, stroke);
      case MuscleGroup.biceps:
        _biceps(canvas, stroke);
      case MuscleGroup.triceps:
        _triceps(canvas, stroke);
      case MuscleGroup.quadriceps:
      case MuscleGroup.pernas:
        _pernas(canvas, stroke);
      case MuscleGroup.posteriorCoxa:
        _posterior(canvas, stroke);
      case MuscleGroup.gluteos:
        _gluteos(canvas, stroke);
      case MuscleGroup.panturrilhas:
        _panturrilha(canvas, stroke);
      case MuscleGroup.abdomen:
        _abdomen(canvas, stroke);
      case MuscleGroup.lombar:
        _lombar(canvas, stroke);
      case MuscleGroup.antebraco:
        _antebraco(canvas, stroke);
      case MuscleGroup.trapezio:
        _trapezio(canvas, stroke);
      case MuscleGroup.pescoco:
        _pescoco(canvas, stroke);
      case MuscleGroup.cardio:
        _cardio(canvas, stroke);
      case MuscleGroup.outros:
        _fullBody(canvas, stroke);
    }

    canvas.restore();
  }

  /// Peito — peitoral frontal monoline (como a prévia).
  void _peito(Canvas c, Paint s) {
    // Contorno ombros + peito + tronco.
    final body = Path()
      ..moveTo(5.5, 8)
      ..cubicTo(5.5, 5.5, 8, 4, 10.2, 4.8)
      ..lineTo(11.2, 7.2)
      ..lineTo(12.8, 7.2)
      ..lineTo(13.8, 4.8)
      ..cubicTo(16, 4, 18.5, 5.5, 18.5, 8)
      // braço dir
      ..lineTo(19.5, 11)
      ..lineTo(18.2, 18)
      // base peito
      ..cubicTo(16.5, 20.5, 13.5, 21.5, 12, 21.5)
      ..cubicTo(10.5, 21.5, 7.5, 20.5, 5.8, 18)
      ..lineTo(4.5, 11)
      ..close();
    c.drawPath(body, s);

    // Linha central peitoral.
    c.drawLine(const Offset(12, 9.5), const Offset(12, 17.5), s);

    // Curvas internas peitorais (como a prévia).
    final leftPec = Path()
      ..moveTo(7.2, 10.5)
      ..quadraticBezierTo(9.5, 12.5, 11.5, 14.5);
    c.drawPath(leftPec, s);
    final rightPec = Path()
      ..moveTo(16.8, 10.5)
      ..quadraticBezierTo(14.5, 12.5, 12.5, 14.5);
    c.drawPath(rightPec, s);

    // Marcas peitorais (pontos suaves via mini arcos).
    c.drawArc(
      Rect.fromCenter(center: const Offset(9.2, 12.8), width: 2.2, height: 2.2),
      0.4,
      math.pi * 1.2,
      false,
      s,
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(14.8, 12.8), width: 2.2, height: 2.2),
      0.4,
      math.pi * 1.2,
      false,
      s,
    );
  }

  /// Costas — vista posterior com trapézio, lâminas e coluna.
  void _costas(Canvas c, Paint s) {
    // Contorno ombros → cintura (V-taper).
    final outline = Path()
      ..moveTo(5, 6.5)
      ..lineTo(7.5, 5)
      ..lineTo(10.5, 5.5)
      ..lineTo(12, 6.5)
      ..lineTo(13.5, 5.5)
      ..lineTo(16.5, 5)
      ..lineTo(19, 6.5)
      ..lineTo(17.5, 12)
      ..lineTo(15.2, 19.5)
      ..lineTo(8.8, 19.5)
      ..lineTo(6.5, 12)
      ..close();
    c.drawPath(outline, s);

    // Coluna.
    c.drawLine(const Offset(12, 7), const Offset(12, 18.8), s);

    // Lâminas / dorsais (arcos internos).
    c.drawArc(
      const Rect.fromLTWH(6.5, 8, 5, 7),
      -0.3,
      math.pi * 0.95,
      false,
      s,
    );
    c.drawArc(
      const Rect.fromLTWH(12.5, 8, 5, 7),
      math.pi * 0.35,
      math.pi * 0.95,
      false,
      s,
    );

    // Braços.
    c.drawLine(const Offset(5.5, 8), const Offset(4.5, 16), s);
    c.drawLine(const Offset(18.5, 8), const Offset(19.5, 16), s);
  }

  /// Pernas — coxas/quads de frente (prévia).
  void _pernas(Canvas c, Paint s) {
    // Contorno das duas pernas.
    final legs = Path()
      ..moveTo(7.5, 4)
      ..lineTo(6, 12)
      ..quadraticBezierTo(5.5, 15, 7, 20)
      ..lineTo(9.5, 20)
      ..quadraticBezierTo(10.5, 15, 10.2, 12)
      ..lineTo(11.2, 8)
      ..lineTo(12.8, 8)
      ..lineTo(13.8, 12)
      ..quadraticBezierTo(13.5, 15, 14.5, 20)
      ..lineTo(17, 20)
      ..quadraticBezierTo(18.5, 15, 18, 12)
      ..lineTo(16.5, 4)
      ..close();
    c.drawPath(legs, s);

    // Linha central / adutores.
    c.drawLine(const Offset(12, 8), const Offset(12, 18), s);

    // Contorno interno das coxas (como a prévia).
    c.drawArc(
      const Rect.fromLTWH(7.5, 10, 4, 6),
      0.2,
      math.pi * 0.8,
      false,
      s,
    );
    c.drawArc(
      const Rect.fromLTWH(12.5, 10, 4, 6),
      math.pi * 0.2,
      math.pi * 0.8,
      false,
      s,
    );
  }

  /// Ombros — deltóides de frente.
  void _ombros(Canvas c, Paint s) {
    // Pescoço.
    c.drawLine(const Offset(12, 5), const Offset(12, 9), s);
    // Ombros / deltóides arredondados.
    final left = Path()
      ..moveTo(12, 8)
      ..cubicTo(9, 7, 5.5, 8.5, 5, 11.5)
      ..cubicTo(4.5, 14, 6, 16, 8, 17)
      ..lineTo(9.5, 14)
      ..cubicTo(9, 12, 10, 10, 12, 9.5);
    c.drawPath(left, s);
    final right = Path()
      ..moveTo(12, 8)
      ..cubicTo(15, 7, 18.5, 8.5, 19, 11.5)
      ..cubicTo(19.5, 14, 18, 16, 16, 17)
      ..lineTo(14.5, 14)
      ..cubicTo(15, 12, 14, 10, 12, 9.5);
    c.drawPath(right, s);
    // Tronco curto.
    c.drawLine(const Offset(9.5, 14), const Offset(9.5, 19.5), s);
    c.drawLine(const Offset(14.5, 14), const Offset(14.5, 19.5), s);
  }

  /// Bíceps — braço flexionado clássico monoline.
  void _biceps(Canvas c, Paint s) {
    // Ombro → bíceps → antebraço → punho.
    final arm = Path()
      ..moveTo(7, 18.5)
      ..quadraticBezierTo(6.5, 15, 8, 12.5)
      ..quadraticBezierTo(9.5, 9.5, 13, 8)
      ..quadraticBezierTo(16.5, 6.5, 18, 8.5)
      ..quadraticBezierTo(19, 10.5, 17, 12)
      ..quadraticBezierTo(14.5, 13.5, 13, 12)
      ..quadraticBezierTo(11.5, 14, 12, 17)
      ..quadraticBezierTo(12.2, 19, 10.5, 19.5);
    c.drawPath(arm, s);
    // Pico do bíceps.
    c.drawArc(
      const Rect.fromLTWH(12.5, 6.5, 5.5, 5),
      math.pi * 0.9,
      math.pi * 1.2,
      false,
      s,
    );
  }

  /// Tríceps — braço visto de trás / extensão.
  void _triceps(Canvas c, Paint s) {
    final arm = Path()
      ..moveTo(8, 6)
      ..quadraticBezierTo(10, 7, 11.5, 10)
      ..quadraticBezierTo(13, 13.5, 12.5, 16)
      ..quadraticBezierTo(12, 18.5, 14, 20)
      ..quadraticBezierTo(16.5, 19, 17.5, 16.5)
      ..quadraticBezierTo(18.5, 13, 16, 10)
      ..quadraticBezierTo(13.5, 7, 11, 5.5)
      ..close();
    c.drawPath(arm, s);
    // Linha do tríceps.
    c.drawLine(const Offset(13, 9), const Offset(14.5, 15), s);
  }

  /// Abdômen — torso com six-pack monoline.
  void _abdomen(Canvas c, Paint s) {
    // Contorno torso.
    final torso = Path()
      ..moveTo(8, 4.5)
      ..lineTo(16, 4.5)
      ..lineTo(17.5, 10)
      ..lineTo(16.5, 19.5)
      ..lineTo(7.5, 19.5)
      ..lineTo(6.5, 10)
      ..close();
    c.drawPath(torso, s);
    // Linha alba.
    c.drawLine(const Offset(12, 5.5), const Offset(12, 18.5), s);
    // Faixas horizontais.
    c.drawLine(const Offset(8.2, 9), const Offset(15.8, 9), s);
    c.drawLine(const Offset(7.8, 13), const Offset(16.2, 13), s);
    c.drawLine(const Offset(7.8, 16.5), const Offset(16.2, 16.5), s);
  }

  /// Glúteos — vista posterior monoline (prévia).
  void _gluteos(Canvas c, Paint s) {
    final shape = Path()
      ..moveTo(7, 5)
      ..lineTo(8.5, 5)
      ..quadraticBezierTo(10, 8, 11.5, 11)
      ..lineTo(12.5, 11)
      ..quadraticBezierTo(14, 8, 15.5, 5)
      ..lineTo(17, 5)
      ..lineTo(18, 12)
      ..quadraticBezierTo(17.5, 18, 15.5, 20)
      ..lineTo(13.2, 20)
      ..lineTo(12, 14)
      ..lineTo(10.8, 20)
      ..lineTo(8.5, 20)
      ..quadraticBezierTo(6.5, 18, 6, 12)
      ..close();
    c.drawPath(shape, s);
    // Divisão central.
    c.drawLine(const Offset(12, 11), const Offset(12, 19.5), s);
  }

  /// Posterior de coxa — perna de perfil flexionada.
  void _posterior(Canvas c, Paint s) {
    final leg = Path()
      ..moveTo(8, 5)
      ..lineTo(10.5, 11)
      ..lineTo(9, 14)
      ..quadraticBezierTo(8, 16.5, 10, 19.5)
      ..lineTo(14, 19)
      ..quadraticBezierTo(16, 16, 15, 13)
      ..lineTo(14, 10)
      ..quadraticBezierTo(13, 6, 11, 4.5);
    c.drawPath(leg, s);
    // Ênfase no posterior.
    c.drawArc(
      const Rect.fromLTWH(9.5, 7, 5, 6),
      -0.4,
      math.pi * 0.9,
      false,
      s,
    );
  }

  /// Panturrilha — perna de perfil com volume da panturrilha.
  void _panturrilha(Canvas c, Paint s) {
    final leg = Path()
      ..moveTo(11, 3.5)
      ..lineTo(10.5, 10)
      ..quadraticBezierTo(8.5, 13, 10, 16.5)
      ..quadraticBezierTo(11, 18.5, 10.5, 20.5)
      ..lineTo(14.5, 20.5)
      ..quadraticBezierTo(15.5, 17, 14.5, 14)
      ..quadraticBezierTo(16.5, 11, 14, 8)
      ..lineTo(13.5, 3.5)
      ..close();
    c.drawPath(leg, s);
    // Volume da panturrilha.
    c.drawArc(
      const Rect.fromLTWH(9.5, 11, 5.5, 6),
      -0.2,
      math.pi * 1.1,
      false,
      s,
    );
  }

  /// Lombar — coluna inferior.
  void _lombar(Canvas c, Paint s) {
    c.drawLine(const Offset(12, 4.5), const Offset(12, 19.5), s);
    for (final y in [7.0, 10.5, 14.0, 17.5]) {
      c.drawCircle(Offset(12, y), 1.4, s);
    }
    c.drawLine(const Offset(7.5, 15), const Offset(16.5, 15), s);
  }

  /// Antebraço.
  void _antebraco(Canvas c, Paint s) {
    final arm = Path()
      ..moveTo(6.5, 5.5)
      ..lineTo(9.5, 14)
      ..lineTo(14.5, 14)
      ..lineTo(17.5, 5.5);
    c.drawPath(arm, s);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 14, 6, 5.5),
        const Radius.circular(1.5),
      ),
      s,
    );
  }

  /// Trapézio.
  void _trapezio(Canvas c, Paint s) {
    c.drawCircle(const Offset(12, 5.5), 2.0, s);
    c.drawLine(const Offset(12, 7.5), const Offset(12, 12), s);
    c.drawLine(const Offset(5, 11), const Offset(19, 11), s);
    c.drawLine(const Offset(6.5, 11), const Offset(12, 7.5), s);
    c.drawLine(const Offset(17.5, 11), const Offset(12, 7.5), s);
    c.drawLine(const Offset(8, 11), const Offset(8, 18.5), s);
    c.drawLine(const Offset(16, 11), const Offset(16, 18.5), s);
  }

  /// Pescoço.
  void _pescoco(Canvas c, Paint s) {
    c.drawCircle(const Offset(12, 6.5), 3.0, s);
    c.drawLine(const Offset(12, 9.5), const Offset(12, 18), s);
    c.drawLine(const Offset(9, 12.5), const Offset(15, 12.5), s);
    c.drawLine(const Offset(9.5, 15.5), const Offset(14.5, 15.5), s);
  }

  /// Cardio — coração + pulso (prévia).
  void _cardio(Canvas c, Paint s) {
    final heart = Path()
      ..moveTo(12, 19)
      ..cubicTo(4.5, 13.5, 4, 8.5, 8, 6.2)
      ..cubicTo(9.8, 5.2, 11.3, 6.2, 12, 7.8)
      ..cubicTo(12.7, 6.2, 14.2, 5.2, 16, 6.2)
      ..cubicTo(20, 8.5, 19.5, 13.5, 12, 19)
      ..close();
    c.drawPath(heart, s);
    // Linha de pulso.
    final pulse = Path()
      ..moveTo(3.5, 12)
      ..lineTo(7, 12)
      ..lineTo(8.5, 9.5)
      ..lineTo(10.5, 14.5)
      ..lineTo(12, 11)
      ..lineTo(13.5, 12)
      ..lineTo(20.5, 12);
    c.drawPath(pulse, s);
  }

  /// Full body / outros — barra monoline (prévia).
  void _fullBody(Canvas c, Paint s) {
    // Anilhas esquerdas.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2.5, 8, 3.2, 8),
        const Radius.circular(1),
      ),
      s,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.2, 9.5, 2.2, 5),
        const Radius.circular(0.8),
      ),
      s,
    );
    // Barra.
    c.drawLine(const Offset(7.4, 12), const Offset(16.6, 12), s);
    // Anilhas direitas.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16.6, 9.5, 2.2, 5),
        const Radius.circular(0.8),
      ),
      s,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18.3, 8, 3.2, 8),
        const Radius.circular(1),
      ),
      s,
    );
  }

  @override
  bool shouldRepaint(covariant _MuscleSilhouettePainter oldDelegate) =>
      oldDelegate.group != group || oldDelegate.color != color;
}
