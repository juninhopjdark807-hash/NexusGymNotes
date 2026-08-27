/// Tipo de cardio registrado ao final do treino.
enum CardioType {
  esteira('Esteira'),
  bicicleta('Bicicleta'),
  eliptico('Elíptico'),
  escada('Escada'),
  remo('Remo'),
  corda('Pular corda'),
  outro('Outro');

  const CardioType(this.label);

  final String label;

  static CardioType fromName(String? name) =>
      CardioType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => CardioType.outro,
      );
}

/// Registro de cardio ao final de uma sessão.
class CardioRecord {
  const CardioRecord({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.durationMinutes,
    this.distanceKm,
    this.note,
  });

  final String id;
  final String sessionId;
  final CardioType type;

  /// Duração em minutos.
  final int durationMinutes;

  /// Distância em km (quando aplicável).
  final double? distanceKm;

  /// Observação opcional.
  final String? note;
}
