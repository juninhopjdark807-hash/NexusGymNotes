import 'dart:math' as math;

import '../models/user_profile.dart';

/// Resultado de estimativas corporais (não é medição clínica).
class BodyMetrics {
  const BodyMetrics({
    required this.ageYears,
    required this.bmi,
    this.bodyFatPercent,
    this.fatMassKg,
    this.leanMassKg,
    required this.bmrKcal,
    required this.bodyFatMethod,
    required this.bodyFatLabel,
  });

  final int ageYears;
  final double bmi;

  /// Percentual de gordura estimado (null se não calculável).
  final double? bodyFatPercent;
  final double? fatMassKg;
  final double? leanMassKg;
  final double bmrKcal;

  /// `us_navy` | `bmi_estimate` | `none`
  final String bodyFatMethod;

  /// Texto para UI: "BF estimado" / "Estimativa de gordura corporal".
  final String bodyFatLabel;
}

/// Cálculos de composição corporal e metabolismo.
///
/// Isolados da UI para permitir ajuste futuro sem mexer nas telas.
class BodyComposition {
  BodyComposition._();

  static double bmi({required double weightKg, required double heightCm}) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  /// TMB — Mifflin–St Jeor (kcal/dia).
  static double bmrMifflin({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
    return sex == Sex.masculino ? base + 5 : base - 161;
  }

  /// BF via US Navy (circunferências em cm).
  ///
  /// Homem: precisa cintura + pescoço.
  /// Mulher: precisa cintura + pescoço + quadril.
  static double? bodyFatUsNavy({
    required Sex sex,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipCm,
  }) {
    if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) return null;
    if (sex == Sex.masculino) {
      final denom = waistCm - neckCm;
      if (denom <= 0) return null;
      // Fórmula US Navy (cm).
      final bf = 495 /
              (1.0324 -
                  0.19077 * _log10(denom) +
                  0.15456 * _log10(heightCm)) -
          450;
      return _clampBf(bf);
    }
    if (hipCm == null || hipCm <= 0) return null;
    final denom = waistCm + hipCm - neckCm;
    if (denom <= 0) return null;
    final bf = 495 /
            (1.29579 -
                0.35004 * _log10(denom) +
                0.22100 * _log10(heightCm)) -
        450;
    return _clampBf(bf);
  }

  /// Estimativa grosseira de BF a partir do IMC (quando não há medidas).
  /// Deurenberg et al. (aproximação).
  static double bodyFatFromBmi({
    required double bmiValue,
    required int ageYears,
    required Sex sex,
  }) {
    final sexFactor = sex == Sex.masculino ? 1.0 : 0.0;
    final bf = (1.20 * bmiValue) + (0.23 * ageYears) - (10.8 * sexFactor) - 5.4;
    return _clampBf(bf) ?? 15.0;
  }

  static BodyMetrics compute({
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    double? neckCm,
    double? waistCm,
    double? hipCm,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age -= 1;
    if (age < 0) age = 0;

    final bmiValue = bmi(weightKg: weightKg, heightCm: heightCm);
    final bmr = bmrMifflin(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: age,
    );

    double? bf;
    var method = 'none';
    var label = 'Estimativa de gordura corporal';

    final hasNeck = neckCm != null && neckCm > 0;
    final hasWaist = waistCm != null && waistCm > 0;
    if (hasNeck && hasWaist) {
      bf = bodyFatUsNavy(
        sex: sex,
        heightCm: heightCm,
        neckCm: neckCm!,
        waistCm: waistCm!,
        hipCm: hipCm,
      );
      if (bf != null) {
        method = 'us_navy';
        label = 'BF estimado';
      }
    }

    if (bf == null && weightKg > 0 && heightCm > 0) {
      bf = bodyFatFromBmi(bmiValue: bmiValue, ageYears: age, sex: sex);
      method = 'bmi_estimate';
      label = 'Estimativa de gordura corporal';
    }

    double? fatMass;
    double? leanMass;
    if (bf != null && weightKg > 0) {
      fatMass = weightKg * (bf / 100.0);
      leanMass = weightKg - fatMass;
    }

    return BodyMetrics(
      ageYears: age,
      bmi: bmiValue,
      bodyFatPercent: bf,
      fatMassKg: fatMass,
      leanMassKg: leanMass,
      bmrKcal: bmr,
      bodyFatMethod: method,
      bodyFatLabel: label,
    );
  }

  static double _log10(double x) => math.log(x) / math.ln10;

  static double? _clampBf(double bf) {
    if (bf.isNaN || bf.isInfinite) return null;
    if (bf < 3) return 3;
    if (bf > 60) return 60;
    return bf;
  }
}
