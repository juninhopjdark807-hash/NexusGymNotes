/// Treino planejado (template) — a "receita" que o usuário executa.
///
/// A distinção entre **treino planejado** [WorkoutTemplate] e
/// **treino executado** (package domain/models/workout_session.dart)
/// é preservada: importante para as futuras funcionalidades de
/// personal trainer e sincronização.
class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.assignedBy,
  });

  final String id;

  /// Nome do treino (ex.: "TREINO A").
  final String name;

  /// Exercícios na ordem de execução.
  final List<WorkoutExercise> exercises;

  /// Futuro: profissional/personal trainer que enviou o treino.
  /// Campo reservado — não implementado na Fase 1.
  final String? assignedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutTemplate copyWith({
    String? name,
    List<WorkoutExercise>? exercises,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedBy: assignedBy,
    );
  }
}

/// Entrada de exercício dentro de um treino (ordem + ajustes por exercício).
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    this.position = 0,
    this.warmupEnabled = true,
    this.prepEnabled = true,
  });

  /// Identificador da entrada (estável para reordenação/sincronização).
  final String id;

  /// Exercício referenciado.
  final String exerciseId;

  /// Posição na sequência do treino.
  final int position;

  /// Etapa de aquecimento ativada para este exercício.
  final bool warmupEnabled;

  /// Etapa preparatória ativada para este exercício.
  final bool prepEnabled;

  WorkoutExercise copyWith({
    int? position,
    bool? warmupEnabled,
    bool? prepEnabled,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      position: position ?? this.position,
      warmupEnabled: warmupEnabled ?? this.warmupEnabled,
      prepEnabled: prepEnabled ?? this.prepEnabled,
    );
  }
}
