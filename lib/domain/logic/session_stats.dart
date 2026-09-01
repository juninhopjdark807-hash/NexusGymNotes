import '../models/exercise.dart';
import '../models/set_record.dart';
import '../models/workout_session.dart';

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
    this.highestVolumeExerciseName,
    this.highestVolumeKg,
  });

  final SessionPr? newPr;

  /// Exercício com maior volume nesta sessão (não inventado).
  final String? highestVolumeExerciseName;
  final double? highestVolumeKg;
}

/// Resumo consolidado da sessão (treino + métricas derivadas).
class SessionSummaryStats {
  const SessionSummaryStats({
    required this.templateName,
    required this.duration,
    required this.exerciseCount,
    required this.totalSets,
    required this.volumeKg,
    required this.avgRest,
    required this.highlights,
  });

  final String templateName;
  final Duration duration;
  final int exerciseCount;
  final int totalSets;

  /// Volume = Σ (carga × reps) de todas as séries registradas.
  final double volumeKg;

  /// Média dos intervalos entre séries (null se < 2 séries).
  final Duration? avgRest;

  final SessionHighlights highlights;
}

class SessionStats {
  SessionStats._();

  /// Volume = Σ (peso × reps) de **todas** as séries registradas.
  static SessionVolume volume(
    List<SetRecord> sets, {
    Map<String, Exercise> exerciseById = const {},
  }) {
    final byEx = <String, double>{};
    final byGroup = <MuscleGroup, double>{};
    var total = 0.0;
    for (final s in sets) {
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

  /// Volume apenas de séries de **trabalho** (para PR/destaques de carga).
  static SessionVolume workVolume(
    List<SetRecord> sets, {
    Map<String, Exercise> exerciseById = const {},
  }) {
    return volume(
      sets.where((s) => s.stage == SetStage.trabalho).toList(),
      exerciseById: exerciseById,
    );
  }

  /// Descanso médio: média dos intervalos entre séries consecutivas
  /// (ordem cronológica). A 1ª série não entra.
  static Duration? averageRest(List<SetRecord> sets) {
    if (sets.length < 2) return null;
    final ordered = List<SetRecord>.of(sets)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    var totalMs = 0;
    var count = 0;
    for (var i = 1; i < ordered.length; i++) {
      final d = ordered[i].createdAt.difference(ordered[i - 1].createdAt);
      if (d.isNegative || d.inSeconds <= 0) continue;
      // Ignora gaps absurdos (> 30 min) — provavelmente troca de exercício longa.
      if (d.inMinutes > 30) continue;
      totalMs += d.inMilliseconds;
      count++;
    }
    if (count == 0) return null;
    return Duration(milliseconds: (totalMs / count).round());
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
    String? topExName;
    double? topKg;
    vol.byExercise.forEach((id, kg) {
      if (topKg == null || kg > topKg!) {
        topKg = kg;
        topExName = exerciseById[id]?.name ?? 'Exercício';
      }
    });
    if (topKg != null && topKg! < 1) {
      topExName = null;
      topKg = null;
    }
    return SessionHighlights(
      newPr: findNewPr(
        sessionSets: sessionSets,
        previousMaxByExercise: previousMaxByExercise,
        exerciseById: exerciseById,
      ),
      highestVolumeExerciseName: topExName,
      highestVolumeKg: topKg,
    );
  }

  /// Monta o resumo completo a partir da sessão + séries.
  static SessionSummaryStats build({
    required WorkoutSession session,
    required List<SetRecord> sets,
    required Map<String, double> previousMaxByExercise,
    required Map<String, Exercise> exerciseById,
  }) {
    final end = session.endedAt ?? DateTime.now();
    var duration = end.difference(session.startedAt);
    if (duration.isNegative) duration = Duration.zero;

    final exerciseIds = <String>{};
    for (final s in sets) {
      exerciseIds.add(s.exerciseId);
    }

    final vol = volume(sets, exerciseById: exerciseById);

    return SessionSummaryStats(
      templateName: session.templateName,
      duration: duration,
      exerciseCount: exerciseIds.isNotEmpty
          ? exerciseIds.length
          : session.exerciseCount,
      totalSets: sets.length,
      volumeKg: vol.totalKg,
      avgRest: averageRest(sets),
      highlights: highlights(
        sessionSets: sets,
        previousMaxByExercise: previousMaxByExercise,
        exerciseById: exerciseById,
      ),
    );
  }
}
