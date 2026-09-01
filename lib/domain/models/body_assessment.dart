/// Avaliação corporal datada (peso + medidas opcionais + métricas calculadas).
///
/// Avaliações anteriores **não** são apagadas ao criar uma nova.
class BodyAssessment {
  const BodyAssessment({
    required this.id,
    required this.date,
    required this.weightKg,
    this.neckCm,
    this.waistCm,
    this.hipCm,
    this.bmi,
    this.bodyFatPercent,
    this.fatMassKg,
    this.leanMassKg,
    this.bmrKcal,
    this.bodyFatMethod,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final double? neckCm;
  final double? waistCm;
  final double? hipCm;

  /// Métricas calculadas no momento da avaliação (snapshot).
  final double? bmi;
  final double? bodyFatPercent;
  final double? fatMassKg;
  final double? leanMassKg;
  final double? bmrKcal;

  /// Ex.: `us_navy`, `bmi_estimate`, `none`.
  final String? bodyFatMethod;

  final DateTime createdAt;
}
