import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/body_composition.dart';
import 'package:nexus_gym_notes/domain/models/user_profile.dart';

void main() {
  group('BodyComposition.bmi', () {
    test('calcula IMC', () {
      final v = BodyComposition.bmi(weightKg: 80, heightCm: 180);
      expect(v, closeTo(24.69, 0.05));
    });
  });

  group('BodyComposition.bmrMifflin', () {
    test('homem', () {
      final bmr = BodyComposition.bmrMifflin(
        sex: Sex.masculino,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
      );
      expect(bmr, closeTo(1780, 1));
    });
  });

  group('BodyComposition.compute', () {
    test('com medidas usa us_navy quando possível', () {
      final m = BodyComposition.compute(
        sex: Sex.masculino,
        birthDate: DateTime(1990, 1, 1),
        heightCm: 178,
        weightKg: 85,
        neckCm: 40,
        waistCm: 90,
      );
      expect(m.bodyFatMethod, 'us_navy');
      expect(m.bodyFatPercent, isNotNull);
      expect(m.bodyFatLabel, 'BF estimado');
      expect(m.fatMassKg, isNotNull);
      expect(m.leanMassKg, isNotNull);
    });

    test('sem medidas usa estimativa por IMC', () {
      final m = BodyComposition.compute(
        sex: Sex.masculino,
        birthDate: DateTime(1990, 1, 1),
        heightCm: 178,
        weightKg: 85,
      );
      expect(m.bodyFatMethod, 'bmi_estimate');
      expect(m.bodyFatLabel, 'Estimativa de gordura corporal');
      expect(m.bodyFatPercent, isNotNull);
    });
  });
}
