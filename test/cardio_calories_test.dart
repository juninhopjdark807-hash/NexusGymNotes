import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/cardio_calories.dart';
import 'package:nexus_gym_notes/domain/models/cardio_record.dart';
import 'package:nexus_gym_notes/domain/models/user_profile.dart';

void main() {
  group('CardioCalories.estimate', () {
    test('retorna null sem duração', () {
      expect(
        CardioCalories.estimate(type: CardioType.esteira, durationMinutes: 0),
        isNull,
      );
    });

    test('estima calorias com peso', () {
      final kcal = CardioCalories.estimate(
        type: CardioType.esteira,
        durationMinutes: 30,
        weightKg: 80,
        speedKmh: 8,
      );
      expect(kcal, isNotNull);
      expect(kcal!, greaterThan(100));
      expect(kcal, lessThan(800));
    });

    test('corrida gasta mais que caminhada (mesmos inputs)', () {
      final walk = CardioCalories.estimate(
        type: CardioType.caminhada,
        durationMinutes: 30,
        weightKg: 75,
        speedKmh: 5,
      )!;
      final run = CardioCalories.estimate(
        type: CardioType.corrida,
        durationMinutes: 30,
        weightKg: 75,
        speedKmh: 10,
      )!;
      expect(run, greaterThan(walk));
    });

    test('respeita sexo opcional', () {
      final m = CardioCalories.estimate(
        type: CardioType.bicicleta,
        durationMinutes: 40,
        weightKg: 70,
        sex: Sex.masculino,
      )!;
      final f = CardioCalories.estimate(
        type: CardioType.bicicleta,
        durationMinutes: 40,
        weightKg: 70,
        sex: Sex.feminino,
      )!;
      expect(f, lessThanOrEqualTo(m));
    });
  });
}
