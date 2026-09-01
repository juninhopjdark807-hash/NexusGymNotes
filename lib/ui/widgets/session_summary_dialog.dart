import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/exercise_repository.dart';
import '../../data/session_repository.dart';
import '../../domain/logic/session_stats.dart';
import '../../domain/models/cardio_record.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_record.dart';
import '../../domain/models/workout_session.dart';
import 'app_button.dart';

/// Exibe o resumo completo da sessão em um único modal.
///
/// A sessão já deve estar **concluída** no banco antes da chamada.
/// Usa o root navigator e repositórios singleton (não depende de
/// [WidgetRef] nem do context da tela de treino, que pode ter sido
/// desmontada no finish).
Future<void> showSessionSummaryDialog(
  BuildContext context, {
  required String sessionId,
}) async {
  final sessions = SessionRepository.shared;
  final exercisesRepo = ExerciseRepository.shared;

  WorkoutSession? session;
  List<SetRecord> sets = const [];
  CardioRecord? cardio;
  Map<String, Exercise> exerciseById = const {};
  Map<String, double> prevMax = const {};

  try {
    session = await sessions.getById(sessionId);
    if (session == null) return;
    sets = await sessions.setsForSession(sessionId);
    cardio = await sessions.cardioForSession(sessionId);
    final exercises = await exercisesRepo.getAll();
    exerciseById = {for (final e in exercises) e.id: e};
    prevMax =
        await sessions.maxWorkWeightByExercise(excludeSessionId: sessionId);
  } catch (_) {
    // Se falhar a carga, ainda tenta não travar o app.
    return;
  }

  // Garante um context válido do root navigator (overlay do app).
  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  final dialogContext = navigator?.context ?? context;
  if (!dialogContext.mounted) return;

  await showDialog<void>(
    context: dialogContext,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => _SessionSummaryDialog(
      session: session!,
      sets: sets,
      cardio: cardio,
      exerciseById: exerciseById,
      previousMaxByExercise: prevMax,
      onClose: () {
        // Fecha só o dialog; a rota de treino já deve ter sido removida.
        Navigator.of(ctx).pop();
      },
    ),
  );
}

/// Finaliza a navegação do treino e mostra o resumo com segurança.
///
/// Ordem crítica:
/// 1. captura o root navigator
/// 2. remove a rota do treino
/// 3. abre o dialog no root (não depende da tela desmontada)
Future<void> finishWorkoutAndShowSummary(
  BuildContext context, {
  required Future<void> Function() finishSession,
  required String sessionId,
}) async {
  final rootNav = Navigator.of(context, rootNavigator: true);

  // Encerra no banco / limpa estado ativo.
  await finishSession();

  // Remove a tela de treino (e qualquer rota acima dela no mesmo stack).
  // popUntil home — a home fica sob o dialog depois.
  if (rootNav.canPop()) {
    rootNav.popUntil((route) => route.isFirst);
  }

  // Próximo frame: overlay está estável na home.
  await Future<void>.delayed(Duration.zero);

  final overlayContext = rootNav.context;
  if (!overlayContext.mounted) return;

  await showSessionSummaryDialog(overlayContext, sessionId: sessionId);
}

class _SessionSummaryDialog extends StatelessWidget {
  const _SessionSummaryDialog({
    required this.session,
    required this.sets,
    required this.cardio,
    required this.exerciseById,
    required this.previousMaxByExercise,
    required this.onClose,
  });

  final WorkoutSession session;
  final List<SetRecord> sets;
  final CardioRecord? cardio;
  final Map<String, Exercise> exerciseById;
  final Map<String, double> previousMaxByExercise;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final stats = SessionStats.build(
      session: session,
      sets: sets,
      previousMaxByExercise: previousMaxByExercise,
      exerciseById: exerciseById,
    );

    final durationLabel =
        formatSessionDuration(session.startedAt, session.endedAt);
    final volumeLabel =
        stats.volumeKg > 0 ? '${formatKg(stats.volumeKg)} kg' : '—';
    final restLabel =
        stats.avgRest != null ? formatInterval(stats.avgRest!) : '—';

    final h = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: C.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.88, maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: C.accentSoft,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: C.accentSecondary,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'TREINO CONCLUÍDO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stats.templateName,
                      textAlign: TextAlign.center,
                      style: AppText.bodyDim,
                    ),
                    const SizedBox(height: 18),
                    _StatBlock(
                      rows: [
                        ('Tempo total', durationLabel),
                        ('Exercícios', '${stats.exerciseCount}'),
                        ('Total de séries', '${stats.totalSets}'),
                        ('Volume total', volumeLabel),
                        ('Descanso médio', restLabel),
                      ],
                    ),
                    if (cardio != null) ...[
                      const SizedBox(height: 16),
                      const Text('CARDIO', style: AppText.label),
                      const SizedBox(height: 8),
                      _CardioBlock(cardio: cardio!),
                    ],
                    if (_hasHighlights(stats.highlights)) ...[
                      const SizedBox(height: 16),
                      const Text('DESTAQUES', style: AppText.label),
                      const SizedBox(height: 8),
                      if (stats.highlights.newPr != null)
                        _HighlightCard(
                          title: 'NOVO RECORDE',
                          accent: true,
                          body: stats.highlights.newPr!.exerciseName,
                          detail:
                              '${formatKg(stats.highlights.newPr!.weightKg)} kg × ${stats.highlights.newPr!.reps.toInt()}',
                        ),
                      if (stats.highlights.highestVolumeExerciseName != null &&
                          stats.highlights.highestVolumeKg != null) ...[
                        if (stats.highlights.newPr != null)
                          const SizedBox(height: 8),
                        _HighlightCard(
                          title: 'MAIOR VOLUME',
                          accent: false,
                          body: stats.highlights.highestVolumeExerciseName!,
                          detail:
                              '${formatKg(stats.highlights.highestVolumeKg!)} kg',
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: AppButton(
                label: 'Concluir',
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasHighlights(SessionHighlights h) =>
      h.newPr != null ||
      (h.highestVolumeExerciseName != null && h.highestVolumeKg != null);
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(r.$1, style: AppText.bodyDim)),
                  Text(
                    r.$2,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardioBlock extends StatelessWidget {
  const _CardioBlock({required this.cardio});

  final CardioRecord cardio;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Tempo', '${cardio.durationMinutes} min'),
    ];
    if (cardio.distanceKm != null) {
      rows.add(('Distância', '${formatKg(cardio.distanceKm!)} km'));
    }
    if (cardio.speedKmh != null) {
      rows.add(('Velocidade', '${formatKg(cardio.speedKmh!)} km/h'));
    }
    if (cardio.inclinePercent != null) {
      rows.add(('Inclinação', '${formatKg(cardio.inclinePercent!)}%'));
    }
    if (cardio.floors != null) {
      rows.add(('Andares', '${cardio.floors}'));
    }
    if (cardio.caloriesKcal != null) {
      rows.add((
        'Calorias estimadas',
        '≈ ${cardio.caloriesKcal!.round()} kcal',
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardio.type.label,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(r.$1, style: AppText.bodyDim)),
                  Text(
                    r.$2,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: r.$1.startsWith('Calorias')
                          ? C.accentSecondary
                          : C.text,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.body,
    required this.detail,
    required this.accent,
  });

  final String title;
  final String body;
  final String detail;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? C.accentSoft : C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent ? C.accent.withValues(alpha: 0.4) : C.strokeSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: accent ? AppText.labelAccent : AppText.label,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent ? C.accentSecondary : C.text,
            ),
          ),
        ],
      ),
    );
  }
}
