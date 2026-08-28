import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/data/exercise_catalog.dart';
import 'package:nexus_gym_notes/domain/logic/exercise_name.dart';
import 'package:nexus_gym_notes/domain/models/exercise.dart';

void main() {
  group('ExerciseCatalog', () {
    test('ids estáveis e únicos', () {
      final ids = ExerciseCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(id.startsWith('lib_'), isTrue);
      }
    });

    test('sem nomes duplicados (normalizados)', () {
      final norms = ExerciseCatalog.all.map((e) => ExerciseName.normalize(e.name));
      expect(norms.toSet().length, norms.length);
    });

    test('contém exercícios-chave da Fase 2', () {
      final names = ExerciseCatalog.all.map((e) => e.name).toSet();
      expect(names, containsAll([
        'Supino reto',
        'Barra fixa',
        'Desenvolvimento',
        'Rosca direta',
        'Tríceps na polia',
        'Agachamento',
        'Stiff',
        'Elevação pélvica',
        'Panturrilha em pé',
        'Abdominal',
        'Extensão lombar',
        'Rosca inversa',
        'Esteira',
      ]));
    });

    test('cardio da biblioteca marcado como tipo cardio', () {
      final cardio = ExerciseCatalog.all
          .where((e) => e.muscleGroup == MuscleGroup.cardio)
          .toList();
      expect(cardio.length, 5);
      expect(cardio.every((e) => e.type == ExerciseType.cardio), isTrue);
    });

    test('rosca inversa aparece uma única vez', () {
      final count = ExerciseCatalog.all
          .where((e) => ExerciseName.isSame(e.name, 'Rosca inversa'))
          .length;
      expect(count, 1);
    });

    test('quantidade razoável (sem explosão por equipamento)', () {
      expect(ExerciseCatalog.all.length, greaterThanOrEqualTo(70));
      expect(ExerciseCatalog.all.length, lessThan(100));
    });
  });
}
