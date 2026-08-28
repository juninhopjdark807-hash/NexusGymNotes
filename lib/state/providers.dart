import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../data/session_repository.dart';
import '../data/template_repository.dart';
import '../domain/logic/progression.dart';
import '../domain/models/cardio_record.dart';
import '../domain/models/exercise.dart';
import '../domain/models/set_record.dart';
import '../domain/models/workout_session.dart';
import '../domain/models/workout_template.dart';
import 'active_workout.dart';

// ------------------------------------------------------------------ serviços

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository.shared,
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository.shared,
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository.shared,
);

/// Aba ativa da navegação inferior (0 = Treinos, 1 = Histórico).
final tabProvider = StateProvider<int>((ref) => 0);

// -------------------------------------------------------------------- treino

/// Treino em andamento (null quando nenhum).
final activeWorkoutProvider = NotifierProvider<ActiveWorkoutNotifier, ActiveWorkout?>(
  ActiveWorkoutNotifier.new,
);

/// Séries da sessão ativa.
///
/// Não usa `ref.watch` em outro [StreamProvider] (retorna AsyncValue, não
/// Stream). Em vez disso, reage às mudanças do repositório e à sessão ativa.
final activeSessionSetsProvider = StreamProvider<List<SetRecord>>((ref) {
  final workout = ref.watch(activeWorkoutProvider);
  if (workout == null) {
    return Stream.value(const <SetRecord>[]);
  }
  final sessionId = workout.sessionId;
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.changes
      .asyncMap((_) => repo.setsForSession(sessionId))
      .handleError((Object e) => const <SetRecord>[]);
});

/// Referência do exercício: maior carga de trabalho da execução anterior
/// (excluindo a sessão atual). `null` quando ainda não há histórico.
final referenceProvider = FutureProvider.family<double?, String>((ref, exerciseId) {
  final workout = ref.watch(activeWorkoutProvider);
  final repo = ref.watch(sessionRepositoryProvider);
  return repo
      .previousWorkSets(exerciseId, excludeSessionId: workout?.sessionId)
      .then((sets) =>
          Progression.referenceFromWorkSets(sets.map((s) => s.weightKg)));
});

// ------------------------------------------------------------------- dados

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.changes
      .asyncMap((_) => repo.getAll())
      .handleError((Object e) => const <Exercise>[]);
});

final templatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.changes
      .asyncMap((_) => repo.getAll())
      .handleError((Object e) => const <WorkoutTemplate>[]);
});

final templateProvider = StreamProvider.family<WorkoutTemplate?, String>(
  (ref, id) {
    final repo = ref.watch(templateRepositoryProvider);
    return repo.changes
        .asyncMap((_) => repo.getById(id))
        .handleError((Object e) => null);
  },
);

/// Sessões concluídas (histórico), da mais recente para a mais antiga.
final sessionsProvider = StreamProvider<List<SessionSummary>>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.changes
      .asyncMap((_) => repo.getCompletedSummaries())
      .handleError((Object e) => const <SessionSummary>[]);
});

/// Sessão em andamento (null quando não há).
final activeSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.changes
      .asyncMap((_) => repo.getActiveSession())
      .handleError((Object e) => null);
});

final sessionProvider = StreamProvider.family<WorkoutSession?, String>(
  (ref, id) {
    final repo = ref.watch(sessionRepositoryProvider);
    return repo.changes
        .asyncMap((_) => repo.getById(id))
        .handleError((Object e) => null);
  },
);

final sessionSetsProvider = StreamProvider.family<List<SetRecord>, String>(
  (ref, sessionId) {
    final repo = ref.watch(sessionRepositoryProvider);
    return repo.changes
        .asyncMap((_) => repo.setsForSession(sessionId))
        .handleError((Object e) => const <SetRecord>[]);
  },
);

final sessionCardioProvider = StreamProvider.family<CardioRecord?, String>(
  (ref, sessionId) {
    final repo = ref.watch(sessionRepositoryProvider);
    return repo.changes
        .asyncMap((_) => repo.cardioForSession(sessionId))
        .handleError((Object e) => null);
  },
);

/// Séries de um exercício em todas as sessões (histórico do exercício).
final exerciseSetsProvider = StreamProvider.family<List<SetRecord>, String>(
  (ref, exerciseId) {
    final repo = ref.watch(sessionRepositoryProvider);
    return repo.changes
        .asyncMap((_) => repo.setsForExercise(exerciseId))
        .handleError((Object e) => const <SetRecord>[]);
  },
);

/// Sessões que contêm o exercício (histórico do exercício).
final exerciseSessionsProvider =
    StreamProvider.family<List<ExerciseSessionInfo>, String>(
      (ref, exerciseId) {
        final repo = ref.watch(sessionRepositoryProvider);
        return repo.changes
            .asyncMap((_) => repo.sessionsForExercise(exerciseId))
            .handleError((Object e) => const <ExerciseSessionInfo>[]);
      },
    );
