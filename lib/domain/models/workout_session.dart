/// Treino executado (sessão).
///
/// Guarda um *snapshot* do nome do template para que o histórico
/// continue fazendo sentido mesmo se o treino planejado for
/// renomeado ou excluído.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.startedAt,
    this.endedAt,
    this.assignedBy,
    this.exerciseCount = 0,
    this.totalSets = 0,
    this.currentPage = 0,
  });

  final String id;

  /// Treino planejado de origem (pode ter sido excluído depois).
  final String? templateId;

  /// Snapshot do nome do treino no momento do início.
  final String templateName;

  /// Futuro: profissional/personal trainer. Reservado — Fase 1 não usa.
  final String? assignedBy;

  final DateTime startedAt;

  /// `null` enquanto o treino está em andamento.
  final DateTime? endedAt;

  /// Quantidade de exercícios com pelo menos uma série registrada.
  final int exerciseCount;

  /// Total de séries registradas (todas as etapas).
  final int totalSets;

  /// Página atual na execução (0..n-1 exercícios, n = cardio).
  /// Persistido para "Voltar ao treino" retomar o ponto certo.
  final int currentPage;

  bool get isCompleted => endedAt != null;

  /// Duração em minutos (0 se ainda em andamento).
  int get durationMinutes {
    final end = endedAt;
    if (end == null) return 0;
    final seconds =
        ((end.millisecondsSinceEpoch - startedAt.millisecondsSinceEpoch) / 1000)
            .round();
    final minutes = seconds ~/ 60;
    return minutes < 1 ? 1 : minutes;
  }
}
