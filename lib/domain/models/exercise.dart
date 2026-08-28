/// Grupo muscular do exercício.
enum MuscleGroup {
  peito('Peito'),
  costas('Costas'),
  ombros('Ombros'),
  biceps('Bíceps'),
  triceps('Tríceps'),
  pernas('Pernas'),
  gluteos('Glúteos'),
  abdomen('Abdômen'),
  trapezio('Trapézio'),
  pescoco('Pescoço'),
  outros('Outros');

  const MuscleGroup(this.label);

  /// Rótulo em português para exibição.
  final String label;

  static MuscleGroup fromName(String? name) {
    // Compatibilidade com o identificador antigo (não-ASCII).
    if (name == 'pescoço') return MuscleGroup.pescoco;
    return MuscleGroup.values.firstWhere(
      (g) => g.name == name,
      orElse: () => MuscleGroup.outros,
    );
  }
}

/// Exercício cadastrado manualmente pelo usuário.
///
/// Pode ser reutilizado em diferentes treinos. Não existe banco online
/// de exercícios na Fase 1.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.createdAt,
  });

  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final DateTime createdAt;

  @override
  String toString() => 'Exercise($name)';
}
