import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/session_stats.dart';
import 'package:nexus_gym_notes/domain/models/exercise.dart';
import 'package:nexus_gym_notes/domain/models/set_record.dart';
import 'package:nexus_gym_notes/domain/models/workout_session.dart';

void main() {
  final now = DateTime(2026, 1, 1, 10, 0, 0);

  SetRecord set({
    required String id,
    required String exerciseId,
    required double kg,
    required int reps,
    SetStage stage = SetStage.trabalho,
    DateTime? at,
  }) {
    return SetRecord(
      id: id,
      sessionId: 's1',
      exerciseId: exerciseId,
      stage: stage,
      weightKg: kg,
      reps: reps,
      order: 0,
      createdAt: at ?? now,
    );
  }

  group('SessionStats.volume', () {
    test('soma todas as séries registradas', () {
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
      expect(vol.totalKg, 1400);
    });
  });

  group('SessionStats.averageRest', () {
    test('null com uma série', () {
      expect(
        SessionStats.averageRest([
          set(id: '1', exerciseId: 'a', kg: 100, reps: 10),
        ]),
        isNull,
      );
    });

    test('média dos intervalos válidos', () {
      final avg = SessionStats.averageRest([
        set(id: '1', exerciseId: 'a', kg: 100, reps: 10, at: now),
        set(
          id: '2',
          exerciseId: 'a',
          kg: 100,
          reps: 9,
          at: now.add(const Duration(seconds: 100)),
        ),
        set(
          id: '3',
          exerciseId: 'a',
          kg: 100,
          reps: 8,
          at: now.add(const Duration(seconds: 220)),
        ),
      ]);
      expect(avg, isNotNull);
      // (100 + 120) / 2 = 110s
      expect(avg!.inSeconds, 110);
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

  group('SessionStats.build', () {
    test('consolida métricas da sessão', () {
      final session = WorkoutSession(
        id: 's1',
        templateId: 't1',
        templateName: 'Peito + Tríceps',
        startedAt: now,
        endedAt: now.add(const Duration(hours: 1, minutes: 4, seconds: 32)),
      );
      final stats = SessionStats.build(
        session: session,
        sets: [
          set(id: '1', exerciseId: 'a', kg: 100, reps: 10, at: now),
          set(
            id: '2',
            exerciseId: 'a',
            kg: 100,
            reps: 8,
            at: now.add(const Duration(minutes: 2)),
          ),
        ],
        previousMaxByExercise: const {},
        exerciseById: {
          'a': Exercise(
            id: 'a',
            name: 'Supino',
            muscleGroup: MuscleGroup.peito,
            createdAt: now,
          ),
        },
      );
      expect(stats.templateName, 'Peito + Tríceps');
      expect(stats.totalSets, 2);
      expect(stats.exerciseCount, 1);
      expect(stats.volumeKg, 1800);
      expect(stats.avgRest, isNotNull);
      expect(stats.duration.inSeconds, 1 * 3600 + 4 * 60 + 32);
    });
  });
}
