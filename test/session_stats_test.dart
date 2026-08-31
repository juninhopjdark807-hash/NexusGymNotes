import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/session_stats.dart';
import 'package:nexus_gym_notes/domain/models/exercise.dart';
import 'package:nexus_gym_notes/domain/models/set_record.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  SetRecord set({
    required String id,
    required String exerciseId,
    required double kg,
    required int reps,
    SetStage stage = SetStage.trabalho,
  }) {
    return SetRecord(
      id: id,
      sessionId: 's1',
      exerciseId: exerciseId,
      stage: stage,
      weightKg: kg,
      reps: reps,
      order: 0,
      createdAt: now,
    );
  }

  group('SessionStats.volume', () {
    test('soma só séries de trabalho', () {
      final vol = SessionStats.volume([
        set(id: '1', exerciseId: 'a', kg: 100, reps: 10),
        set(
          id: '2',
          exerciseId: 'a',
          kg: 40,
          reps: 10,
          stage: SetStage.aquecimento,
        ),
      ]);
      expect(vol.totalKg, 1000);
    });
  });

  group('SessionStats.findNewPr', () {
    test('detecta PR real', () {
      final pr = SessionStats.findNewPr(
        sessionSets: [
          set(id: '1', exerciseId: 'ex1', kg: 110, reps: 8),
        ],
        previousMaxByExercise: {'ex1': 100},
        exerciseById: {
          'ex1': Exercise(
            id: 'ex1',
            name: 'Supino reto',
            muscleGroup: MuscleGroup.peito,
            createdAt: now,
          ),
        },
      );
      expect(pr, isNotNull);
      expect(pr!.weightKg, 110);
      expect(pr.exerciseName, 'Supino reto');
    });

    test('não inventa PR se carga menor ou igual', () {
      final pr = SessionStats.findNewPr(
        sessionSets: [
          set(id: '1', exerciseId: 'ex1', kg: 100, reps: 8),
        ],
        previousMaxByExercise: {'ex1': 100},
        exerciseById: const {},
      );
      expect(pr, isNull);
    });
  });
}
