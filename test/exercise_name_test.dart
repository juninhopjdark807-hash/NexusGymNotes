import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/exercise_name.dart';

void main() {
  group('ExerciseName.normalize', () {
    test('remove acentos e normaliza caixa', () {
      expect(ExerciseName.normalize('Supino Reto'), 'supino reto');
      expect(ExerciseName.normalize('  elevação lateral  '), 'elevacao lateral');
      expect(ExerciseName.normalize('Tríceps francês'), 'triceps frances');
    });

    test('colapsa espaços', () {
      expect(ExerciseName.normalize('Rosca   direta'), 'rosca direta');
    });
  });

  group('ExerciseName.isSame', () {
    test('detecta duplicata ignorando acento e caixa', () {
      expect(ExerciseName.isSame('Supino Reto', 'supino reto'), isTrue);
      expect(ExerciseName.isSame('Elevação lateral', 'elevacao lateral'), isTrue);
      expect(ExerciseName.isSame('Supino reto', 'Supino inclinado'), isFalse);
    });
  });

  group('ExerciseName.matches', () {
    test('substring case-insensitive', () {
      expect(ExerciseName.matches('Supino reto', 'supino'), isTrue);
      expect(ExerciseName.matches('Supino inclinado', 'SUPINO'), isTrue);
      expect(ExerciseName.matches('Supino declinado', 'sup'), isTrue);
      expect(ExerciseName.matches('Crucifixo', 'supino'), isFalse);
    });

    test('palavras individuais', () {
      expect(ExerciseName.matches('Levantamento terra romeno', 'terra'), isTrue);
      expect(
        ExerciseName.matches('Levantamento terra romeno', 'terra romeno'),
        isTrue,
      );
      expect(
        ExerciseName.matches('Levantamento terra romeno', 'romeno terra'),
        isTrue,
      );
    });

    test('query vazia casa com tudo', () {
      expect(ExerciseName.matches('Qualquer', ''), isTrue);
      expect(ExerciseName.matches('Qualquer', '   '), isTrue);
    });
  });
}
