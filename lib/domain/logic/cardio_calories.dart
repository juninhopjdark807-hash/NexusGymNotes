import '../models/cardio_record.dart';
import '../models/user_profile.dart';

/// Estimativa de gasto energético no cardio (kcal).
///
/// Baseado em MET × peso × tempo. Não é valor clínico exato.
class CardioCalories {
  CardioCalories._();

  /// Retorna kcal estimadas (arredondadas) ou null se dados insuficientes.
  static double? estimate({
    required CardioType type,
    required int durationMinutes,
    double? weightKg,
    int? ageYears,
    Sex? sex,
    double? distanceKm,
    double? speedKmh,
    double? inclinePercent,
    int? floors,
  }) {
    if (durationMinutes <= 0) return null;
    final weight = weightKg ?? 70.0;
    if (weight <= 0) return null;

    final hours = durationMinutes / 60.0;
    var met = _baseMet(type);

    // Ajustes por velocidade / inclinação / andares.
    final speed = speedKmh ??
        (distanceKm != null && durationMinutes > 0
            ? distanceKm / hours
            : null);

    switch (type) {
      case CardioType.esteira:
      case CardioType.corrida:
      case CardioType.caminhada:
        if (speed != null) {
          if (speed < 4) {
            met = 2.5;
          } else if (speed < 5.5) {
            met = 3.5;
          } else if (speed < 7) {
            met = 6.0;
          } else if (speed < 9) {
            met = 8.3;
          } else if (speed < 11) {
            met = 10.5;
          } else {
            met = 12.3;
          }
        }
        final incline = inclinePercent ?? 0;
        if (incline > 0) {
          met += incline * 0.15;
        }
      case CardioType.bicicleta:
      case CardioType.bicicletaErgometrica:
        if (speed != null) {
          if (speed < 16) {
            met = 4.0;
          } else if (speed < 20) {
            met = 6.8;
          } else if (speed < 25) {
            met = 8.0;
          } else {
            met = 10.0;
          }
        }
      case CardioType.eliptico:
        met = 5.0;
        if (speed != null && speed > 8) met = 7.0;
      case CardioType.escada:
        met = 8.0;
        if (floors != null && floors > 0) {
          // ~0.15 kcal extra por andar × peso/70 (aprox).
          final floorBonus = floors * 0.15 * (weight / 70.0);
          final base = met * weight * hours;
          return ((base + floorBonus) * 10).roundToDouble() / 10;
        }
      case CardioType.remo:
        met = 7.0;
      case CardioType.corda:
        met = 11.0;
      case CardioType.outro:
        met = 5.0;
    }

    // Ajuste leve por sexo/idade (opcional, conservador).
    if (sex == Sex.feminino) met *= 0.97;
    if (ageYears != null && ageYears >= 50) met *= 0.97;

    final kcal = met * weight * hours;
    if (kcal.isNaN || kcal.isInfinite || kcal < 0) return null;
    return (kcal * 10).roundToDouble() / 10;
  }

  static double _baseMet(CardioType type) => switch (type) {
        CardioType.esteira => 6.0,
        CardioType.corrida => 8.0,
        CardioType.caminhada => 3.5,
        CardioType.bicicleta => 6.8,
        CardioType.bicicletaErgometrica => 5.5,
        CardioType.eliptico => 5.0,
        CardioType.escada => 8.0,
        CardioType.remo => 7.0,
        CardioType.corda => 11.0,
        CardioType.outro => 5.0,
      };
}
