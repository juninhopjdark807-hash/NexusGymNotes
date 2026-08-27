import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_repository.dart';
import '../data/template_repository.dart';
import '../domain/models/cardio_record.dart';
import '../domain/models/workout_template.dart';

/// Estado do treino em andamento.
///
/// `page`: 0..items.length-1 são os exercícios;
/// `page == items.length` é a etapa de cardio.
class ActiveWorkout {
  const ActiveWorkout({
    required this.sessionId,
    required this.templateName,
    required this.startedAt,
    required this.items,
    required this.page,
  });

  final String sessionId;
  final String templateName;
  final DateTime startedAt;

  /// Exercícios do treino, na ordem.
  final List<WorkoutExercise> items;

  final int page;

  bool get atCardio => page >= items.length;

  bool get isLastExercise => page == items.length - 1;

  WorkoutExercise? get currentExercise =>
      (page >= 0 && page < items.length) ? items[page] : null;

  ActiveWorkout copyWithPage(int page) {
    return ActiveWorkout(
      sessionId: sessionId,
      templateName: templateName,
      startedAt: startedAt,
      items: items,
      page: page,
    );
  }
}

/// Controla o treino em andamento: iniciar, retomar, navegar
/// entre exercícios/cardio e encerrar.
///
/// As séries em si ficam no banco (fonte da verdade); este estado
/// guarda apenas a identidade da sessão e a posição de navegação.
class ActiveWorkoutNotifier extends Notifier<ActiveWorkout?> {
  @override
  ActiveWorkout? build() => null;

  SessionRepository get _sessions => ref.read(sessionRepositoryProvider);
  TemplateRepository get _templates => ref.read(templateRepositoryProvider);

  /// Inicia uma nova sessão a partir do treino planejado.
  Future<bool> start(WorkoutTemplate template) async {
    final session = await _sessions.startSession(template);
    state = ActiveWorkout(
      sessionId: session.id,
      templateName: session.templateName,
      startedAt: session.startedAt,
      items: template.exercises,
      page: 0,
    );
    return true;
  }

  /// Retoma uma sessão em andamento (ex.: app foi fechado durante o treino).
  /// Retorna `false` se a sessão não existir ou já tiver sido encerrada.
  Future<bool> resume(String sessionId) async {
    final session = await _sessions.getById(sessionId);
    if (session == null || session.isCompleted) return false;
    final items = session.templateId != null
        ? (await _templates.getById(session.templateId!))?.exercises ?? const <WorkoutExercise>[]
        : const <WorkoutExercise>[];
    state = ActiveWorkout(
      sessionId: session.id,
      templateName: session.templateName,
      startedAt: session.startedAt,
      items: items,
      page: 0,
    );
    return true;
  }

  void goToPage(int page) {
    final s = state;
    if (s == null) return;
    final p = page.clamp(0, s.items.length);
    if (p == s.page) return;
    state = s.copyWithPage(p);
  }

  void next() {
    final s = state;
    if (s != null) goToPage(s.page + 1);
  }

  void previous() {
    final s = state;
    if (s != null) goToPage(s.page - 1);
  }

  /// Encerra o treino, salvando o cardio (quando informado).
  Future<void> finish({CardioRecord? cardio}) async {
    final s = state;
    if (s == null) return;
    await _sessions.finishSession(s.sessionId, cardio: cardio);
    state = null;
  }
}
