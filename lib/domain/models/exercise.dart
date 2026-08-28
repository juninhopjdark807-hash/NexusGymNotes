/// Tipo do exercício (musculação vs cardio da biblioteca).
enum ExerciseType {
  musculacao('Musculação'),
  cardio('Cardio');

  const ExerciseType(this.label);

  final String label;

  static ExerciseType fromName(String? name) =>
      ExerciseType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => ExerciseType.musculacao,
      );
}

/// Grupo muscular / categoria do exercício.
///
/// Inclui grupos da Fase 1 (compatibilidade) e os da biblioteca Fase 2.
enum MuscleGroup {
  peito('Peito'),
  costas('Costas'),
  ombros('Ombros'),
  biceps('Bíceps'),
  triceps('Tríceps'),
  quadriceps('Quadríceps'),
  posteriorCoxa('Posterior de coxa'),
  gluteos('Glúteos'),
  panturrilhas('Panturrilhas'),
  abdomen('Abdômen'),
  lombar('Lombar'),
  antebraco('Antebraço'),
  // Compatibilidade Fase 1 / dados legados
  pernas('Pernas'),
  trapezio('Trapézio'),
  pescoco('Pescoço'),
  cardio('Cardio'),
  outros('Outros');

  const MuscleGroup(this.label);

  /// Rótulo em português para exibição.
  final String label;

  /// Ordem de exibição na biblioteca (Fase 2).
  static const List<MuscleGroup> libraryOrder = [
    MuscleGroup.peito,
    MuscleGroup.costas,
    MuscleGroup.ombros,
    MuscleGroup.biceps,
    MuscleGroup.triceps,
    MuscleGroup.quadriceps,
    MuscleGroup.posteriorCoxa,
    MuscleGroup.gluteos,
    MuscleGroup.panturrilhas,
    MuscleGroup.abdomen,
    MuscleGroup.lombar,
    MuscleGroup.antebraco,
    MuscleGroup.cardio,
    MuscleGroup.pernas,
    MuscleGroup.trapezio,
    MuscleGroup.pescoco,
    MuscleGroup.outros,
  ];

  static MuscleGroup fromName(String? name) {
    // Compatibilidade com o identificador antigo (não-ASCII).
    if (name == 'pescoço') return MuscleGroup.pescoco;
    return MuscleGroup.values.firstWhere(
      (g) => g.name == name,
      orElse: () => MuscleGroup.outros,
    );
  }
}

/// Exercício do catálogo ou criado pelo usuário.
///
/// - Catálogo: [isCustom] = false, ids estáveis (`lib_…`).
/// - Personalizado: [isCustom] = true.
/// - [active] = false desativa sem apagar (histórico preservado).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.createdAt,
    this.type = ExerciseType.musculacao,
    this.isCustom = true,
    this.active = true,
  });

  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final DateTime createdAt;
  final ExerciseType type;
  final bool isCustom;
  final bool active;

  @override
  String toString() => 'Exercise($name)';
}
