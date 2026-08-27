/// Etapa da série dentro da execução de um exercício.
enum SetStage {
  aquecimento('Aquecimento'),
  preparatoria('Preparatória'),
  trabalho('Trabalho');

  const SetStage(this.label);

  final String label;

  static SetStage fromName(String? name) =>
      SetStage.values.firstWhere(
        (s) => s.name == name,
        orElse: () => SetStage.trabalho,
      );
}

/// Uma série registrada durante a execução de um exercício.
///
/// Somente séries com [SetStage.trabalho] participam do cálculo da
/// progressão (referência do próximo treino).
class SetRecord {
  const SetRecord({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.stage,
    required this.weightKg,
    required this.reps,
    required this.order,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final SetStage stage;

  /// Carga em quilogramas.
  final double weightKg;

  /// Repetições realizadas.
  final int reps;

  /// Ordem de registro dentro do exercício (por etapa).
  final int order;

  final DateTime createdAt;

  SetRecord copyWith({double? weightKg, int? reps, SetStage? stage}) {
    return SetRecord(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      stage: stage ?? this.stage,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      order: order,
      createdAt: createdAt,
    );
  }
}
