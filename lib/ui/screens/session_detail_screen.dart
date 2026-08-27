import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/cardio_record.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_record.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
import 'exercise_history_screen.dart';

/// Detalhe de um treino executado (histórico).
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId)).valueOrNull;
    final sets =
        ref.watch(sessionSetsProvider(sessionId)).valueOrNull ?? const <SetRecord>[];
    final cardio = ref.watch(sessionCardioProvider(sessionId)).valueOrNull;
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: C.textFaint)),
      );
    }

    // Agrupa as séries por exercício, preservando a ordem de aparição.
    final byExercise = <String, List<SetRecord>>{};
    final exOrder = <String>[];
    for (final s in sets) {
      final list = byExercise.putIfAbsent(s.exerciseId, () => []);
      list.add(s);
      if (!exOrder.contains(s.exerciseId)) exOrder.add(s.exerciseId);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text(
                    formatDate(session.startedAt).toUpperCase(),
                    style: AppText.bodyFaint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  Text(
                    session.templateName.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatDuration(session.durationMinutes)} · ${session.totalSets} séries',
                    style: AppText.bodyDim,
                  ),
                  const SizedBox(height: 22),
                  if (exOrder.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Sem séries registradas', style: AppText.bodyFaint),
                    ),
                  for (final exId in exOrder)
                    _ExerciseBlock(
                      exercise: exerciseById[exId],
                      sets: (byExercise[exId]!..sort((a, b) => a.order.compareTo(b.order))),
                      onOpenHistory: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AppFrame(child: ExerciseHistoryScreen(exerciseId: exId)),
                        ),
                      ),
                    ),
                  if (cardio != null) _CardioBlock(cardio: cardio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({
    required this.exercise,
    required this.sets,
    required this.onOpenHistory,
  });

  final Exercise? exercise;
  final List<SetRecord> sets;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final workWeights =
        sets.where((s) => s.stage == SetStage.trabalho).map((s) => s.weightKg).toList();
    final double? maxWork =
        workWeights.isEmpty ? null : workWeights.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenHistory,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise?.name ?? 'Exercício',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.history_rounded, color: C.textFaint, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final s in sets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatKg(s.weightKg),
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: ' × ${s.reps}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: C.textDim,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (s.stage != SetStage.trabalho)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.stage.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: C.textFaint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (maxWork != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'MÁX ${formatKg(maxWork)} kg',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: C.accent,
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CARDIO', style: AppText.label),
          const SizedBox(height: 8),
          Text(
            '${cardio.type.label} · ${cardio.durationMinutes} min'
            '${cardio.distanceKm != null ? ' · ${formatKg(cardio.distanceKm!)} km' : ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (cardio.note != null && cardio.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(cardio.note!, style: AppText.bodyFaint),
          ],
        ],
      ),
    );
  }
}
