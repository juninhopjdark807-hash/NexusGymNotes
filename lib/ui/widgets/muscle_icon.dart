import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone geométrico / fitness por grupo muscular.
///
/// Sem silhuetas humanas (bonequinhos). Usa símbolos lineares de
/// academia e formas geométricas estáveis no Material Icons.
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

  static IconData iconFor(MuscleGroup group) {
    return switch (group) {
      // Peito — escudo / peitoral
      MuscleGroup.peito => Icons.shield_outlined,
      // Costas — camadas / dorsal
      MuscleGroup.costas => Icons.layers_outlined,
      // Ombros — triângulo / deltóide
      MuscleGroup.ombros => Icons.change_history_outlined,
      // Bíceps — barra / peso
      MuscleGroup.biceps => Icons.fitness_center_rounded,
      // Tríceps — peso com estilo outline
      MuscleGroup.triceps => Icons.fitness_center_outlined,
      // Quadríceps / pernas — setas de extensão
      MuscleGroup.quadriceps => Icons.expand_outlined,
      MuscleGroup.pernas => Icons.expand_outlined,
      // Posterior de coxa — flexão vertical
      MuscleGroup.posteriorCoxa => Icons.unfold_more_outlined,
      // Glúteos — hexágono
      MuscleGroup.gluteos => Icons.hexagon_outlined,
      // Panturrilhas — setas verticais
      MuscleGroup.panturrilhas => Icons.swap_vert_rounded,
      // Abdômen — grade / core
      MuscleGroup.abdomen => Icons.grid_view_rounded,
      // Lombar — suporte horizontal
      MuscleGroup.lombar => Icons.horizontal_rule_rounded,
      // Antebraço — mão geométrica
      MuscleGroup.antebraco => Icons.front_hand_outlined,
      // Trapézio — elevação
      MuscleGroup.trapezio => Icons.keyboard_double_arrow_up_rounded,
      // Pescoço — anel
      MuscleGroup.pescoco => Icons.radio_button_unchecked,
      // Cardio — coração
      MuscleGroup.cardio => Icons.favorite_border_rounded,
      // Outros
      MuscleGroup.outros => Icons.circle_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? C.accentSecondary : C.textDim);
    return Icon(iconFor(group), size: size, color: c);
  }
}

/// Badge circular com ícone de grupo muscular.
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
          color: active ? C.accent.withValues(alpha: 0.5) : C.stroke,
        ),
      ),
      child: Center(
        child: MuscleIcon(
          group: group,
          size: size * 0.45,
          active: active,
        ),
      ),
    );
  }
}
