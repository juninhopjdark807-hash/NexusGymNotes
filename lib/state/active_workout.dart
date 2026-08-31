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

  ActiveWorkout copyWithItems(List<WorkoutExercise> items) {
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
///
/// Usa os singletons dos repositórios (mesma instância dos providers)
/// para evitar import circular com `providers.dart`.
class ActiveWorkoutNotifier extends Notifier<ActiveWorkout?> {
  @override
  ActiveWorkout? build() => null;

  SessionRepository get _sessions => SessionRepository.shared;
  TemplateRepository get _templates => TemplateRepository.shared;

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
        ? (await _templates.getById(session.templateId!))?.exercises ??
            const <WorkoutExercise>[]
        : const <WorkoutExercise>[];
    final maxPage = items.length; // cardio
    final page = session.currentPage.clamp(0, maxPage);
    state = ActiveWorkout(
      sessionId: session.id,
      templateName: session.templateName,
      startedAt: session.startedAt,
      items: items,
      page: page,
    );
    return true;
  }

  void goToPage(int page) {
    final s = state;
    if (s == null) return;
    // clamp retorna num em alguns SDKs — força int para a página do cardio
    // (índice == items.length) ser aceita corretamente.
    final max = s.items.length; // página do cardio
    final p = page < 0 ? 0 : (page > max ? max : page);
    if (p == s.page) return;
    state = s.copyWithPage(p);
    // Persiste página para "Voltar ao treino" (fire-and-forget).
    _sessions.updateCurrentPage(s.sessionId, p);
  }

  void next() {
    final s = state;
    if (s == null || s.atCardio) return;
    goToPage(s.page + 1);
  }

  void previous() {
    final s = state;
    if (s == null || s.page <= 0) return;
    goToPage(s.page - 1);
  }

  /// Liga/desliga aquecimento ou preparatória do exercício [itemId]
  /// apenas nesta sessão (não altera o template salvo).
  void setItemStages(
    String itemId, {
    bool? warmupEnabled,
    bool? prepEnabled,
  }) {
    final s = state;
    if (s == null) return;
    final index = s.items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final current = s.items[index];
    final next = current.copyWith(
      warmupEnabled: warmupEnabled ?? current.warmupEnabled,
      prepEnabled: prepEnabled ?? current.prepEnabled,
    );
    if (next.warmupEnabled == current.warmupEnabled &&
        next.prepEnabled == current.prepEnabled) {
      return;
    }
    final items = List<WorkoutExercise>.of(s.items);
    items[index] = next;
    state = s.copyWithItems(items);
  }

  /// Encerra o treino, salvando o cardio (quando informado).
  Future<void> finish({CardioRecord? cardio}) async {
    final s = state;
    if (s == null) return;
    await _sessions.finishSession(s.sessionId, cardio: cardio);
    state = null;
  }
}
