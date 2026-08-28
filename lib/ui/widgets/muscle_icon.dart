import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';

/// Ícone linear monocromático por grupo muscular.
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
      MuscleGroup.peito => Icons.accessibility_new_rounded,
      MuscleGroup.costas => Icons.airline_seat_recline_normal_rounded,
      MuscleGroup.ombros => Icons.architecture_rounded,
      MuscleGroup.biceps => Icons.fitness_center_rounded,
      MuscleGroup.triceps => Icons.sports_gymnastics_rounded,
      MuscleGroup.quadriceps => Icons.directions_run_rounded,
      MuscleGroup.posteriorCoxa => Icons.directions_walk_rounded,
      MuscleGroup.gluteos => Icons.emoji_people_rounded,
      MuscleGroup.panturrilhas => Icons.hiking_rounded,
      MuscleGroup.abdomen => Icons.self_improvement_rounded,
      MuscleGroup.lombar => Icons.airline_seat_flat_angled_rounded,
      MuscleGroup.antebraco => Icons.back_hand_outlined,
      MuscleGroup.pernas => Icons.directions_run_rounded,
      MuscleGroup.trapezio => Icons.expand_rounded,
      MuscleGroup.pescoco => Icons.face_retouching_natural_rounded,
      MuscleGroup.cardio => Icons.monitor_heart_outlined,
      MuscleGroup.outros => Icons.sports_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? C.accent : C.textDim);
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
