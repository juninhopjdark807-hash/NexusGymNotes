import '../models/exercise.dart';
import '../models/set_record.dart';

/// Estatísticas e destaques de uma sessão (dados reais apenas).
class SessionVolume {
  const SessionVolume({
    required this.totalKg,
    required this.byExercise,
    required this.byMuscleGroup,
  });

  final double totalKg;
  final Map<String, double> byExercise;
  final Map<MuscleGroup, double> byMuscleGroup;
}

class SessionPr {
  const SessionPr({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
  });

  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final double reps;
}

class SessionHighlights {
  const SessionHighlights({
    this.newPr,
    this.highestVolumeGroup,
    this.highestVolumeKg,
  });

  final SessionPr? newPr;
  final MuscleGroup? highestVolumeGroup;
  final double? highestVolumeKg;
}

class SessionStats {
  SessionStats._();

  /// Volume = Σ (peso × reps) apenas em séries de trabalho.
  static SessionVolume volume(
    List<SetRecord> sets, {
    Map<String, Exercise> exerciseById = const {},
  }) {
    final byEx = <String, double>{};
    final byGroup = <MuscleGroup, double>{};
    var total = 0.0;
    for (final s in sets) {
      if (s.stage != SetStage.trabalho) continue;
      final v = s.weightKg * s.reps;
      total += v;
      byEx[s.exerciseId] = (byEx[s.exerciseId] ?? 0) + v;
      final g = exerciseById[s.exerciseId]?.muscleGroup ?? MuscleGroup.outros;
      byGroup[g] = (byGroup[g] ?? 0) + v;
    }
    return SessionVolume(
      totalKg: total,
      byExercise: byEx,
      byMuscleGroup: byGroup,
    );
  }

  /// PR = maior carga de trabalho nesta sessão que supera o histórico anterior.
  static SessionPr? findNewPr({
    required List<SetRecord> sessionSets,
    required Map<String, double> previousMaxByExercise,
    required Map<String, Exercise> exerciseById,
  }) {
    SessionPr? best;
    final sessionMax = <String, SetRecord>{};
    for (final s in sessionSets) {
      if (s.stage != SetStage.trabalho) continue;
      final cur = sessionMax[s.exerciseId];
      if (cur == null || s.weightKg > cur.weightKg) {
        sessionMax[s.exerciseId] = s;
      }
    }
    for (final entry in sessionMax.entries) {
      final prev = previousMaxByExercise[entry.key] ?? 0;
      final w = entry.value.weightKg;
      if (w > prev && w > 0) {
        final name = exerciseById[entry.key]?.name ?? 'Exercício';
        final candidate = SessionPr(
          exerciseId: entry.key,
          exerciseName: name,
          weightKg: w,
          reps: entry.value.reps.toDouble(),
        );
        if (best == null || candidate.weightKg > best.weightKg) {
          best = candidate;
        }
      }
    }
    return best;
  }

  static SessionHighlights highlights({
    required List<SetRecord> sessionSets,
    required Map<String, double> previousMaxByExercise,
    required Map<String, Exercise> exerciseById,
  }) {
    final vol = volume(sessionSets, exerciseById: exerciseById);
    MuscleGroup? topGroup;
    double? topKg;
    vol.byMuscleGroup.forEach((g, kg) {
      if (topKg == null || kg > topKg!) {
        topKg = kg;
        topGroup = g;
      }
    });
    // Só destaca volume se houver volume relevante.
    if (topKg != null && topKg! < 1) {
      topGroup = null;
      topKg = null;
    }
    return SessionHighlights(
      newPr: findNewPr(
        sessionSets: sessionSets,
        previousMaxByExercise: previousMaxByExercise,
        exerciseById: exerciseById,
      ),
      highestVolumeGroup: topGroup,
      highestVolumeKg: topKg,
    );
  }
}
