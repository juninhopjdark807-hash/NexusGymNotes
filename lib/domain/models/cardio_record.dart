/// Tipo de cardio registrado ao final do treino.
enum CardioType {
  esteira('Esteira'),
  corrida('Corrida'),
  caminhada('Caminhada'),
  bicicleta('Bicicleta'),
  bicicletaErgometrica('Bicicleta ergométrica'),
  eliptico('Elíptico'),
  escada('Escada'),
  // Legado (sessões antigas) — mantidos para compatibilidade.
  remo('Remo'),
  corda('Pular corda'),
  outro('Outro');

  const CardioType(this.label);

  final String label;

  /// Modalidades exibidas no seletor (sem legados ocultos).
  static const List<CardioType> selectable = [
    CardioType.esteira,
    CardioType.corrida,
    CardioType.caminhada,
    CardioType.bicicleta,
    CardioType.bicicletaErgometrica,
    CardioType.eliptico,
    CardioType.escada,
    CardioType.outro,
  ];

  static CardioType fromName(String? name) =>
      CardioType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => CardioType.outro,
      );

  bool get showsDistance => switch (this) {
        CardioType.escada => false,
        CardioType.corda => false,
        _ => true,
      };

  bool get showsSpeed => switch (this) {
        CardioType.esteira ||
        CardioType.corrida ||
        CardioType.caminhada ||
        CardioType.bicicleta ||
        CardioType.bicicletaErgometrica =>
          true,
        _ => false,
      };

  bool get showsIncline => this == CardioType.esteira;

  bool get showsFloors => this == CardioType.escada;
}

/// Registro de cardio ao final de uma sessão.
class CardioRecord {
  const CardioRecord({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.durationMinutes,
    this.distanceKm,
    this.speedKmh,
    this.inclinePercent,
    this.floors,
    this.caloriesKcal,
    this.note,
  });

  final String id;
  final String sessionId;
  final CardioType type;

  /// Duração em minutos.
  final int durationMinutes;

  /// Distância em km (quando aplicável).
  final double? distanceKm;

  /// Velocidade em km/h (quando aplicável).
  final double? speedKmh;

  /// Inclinação % (esteira).
  final double? inclinePercent;

  /// Andares (escada).
  final int? floors;

  /// Calorias estimadas (snapshot no momento do registro).
  final double? caloriesKcal;

  /// Observação opcional.
  final String? note;
}
