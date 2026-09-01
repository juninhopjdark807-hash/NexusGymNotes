import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_record.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';

/// Histórico de evolução de um exercício: uma linha por sessão,
/// com as cargas de trabalho e a carga máxima.
class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    Exercise? exercise;
    for (final e in exercises) {
      if (e.id == exerciseId) {
        exercise = e;
        break;
      }
    }
    final sessions =
        ref.watch(exerciseSessionsProvider(exerciseId)).valueOrNull ??
        const <ExerciseSessionInfo>[];
    final sets =
        ref.watch(exerciseSetsProvider(exerciseId)).valueOrNull ?? const <SetRecord>[];

    final setsBySession = <String, List<SetRecord>>{};
    for (final s in sets) {
      setsBySession.putIfAbsent(s.sessionId, () => []).add(s);
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise?.name ?? 'Exercício',
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (exercise != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              exercise.muscleGroup.label.toUpperCase(),
                              style: AppText.label,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: sessions.isEmpty
                  ? const _NoHistory()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      children: [
                        for (final info in sessions)
                          _ExerciseHistoryCard(
                            info: info,
                            sets: (setsBySession[info.sessionId] ?? const <SetRecord>[])
                                .toList()
                              ..sort((a, b) => a.order.compareTo(b.order)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({required this.info, required this.sets});

  final ExerciseSessionInfo info;
  final List<SetRecord> sets;

  @override
  Widget build(BuildContext context) {
    final work = sets.where((s) => s.stage == SetStage.trabalho).toList();
    final double? maxWork = work.isEmpty
        ? null
        : work.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
    final workSummary = work.map((s) => '${formatKg(s.weightKg)}×${s.reps}').join(' · ');
    final extras = <String>[];
    for (final s in sets.where((s) => s.stage == SetStage.aquecimento)) {
      extras.add('AQ ${formatKg(s.weightKg)}×${s.reps}');
    }
    for (final s in sets.where((s) => s.stage == SetStage.preparatoria)) {
      extras.add('PR ${formatKg(s.weightKg)}×${s.reps}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(info.startedAt).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: C.textDim,
                  ),
                ),
              ),
              if (maxWork != null)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'MÁX ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: C.textFaint,
                        ),
                      ),
                      TextSpan(
                        text: '${formatKg(maxWork)} kg',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: C.accentSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (workSummary.isNotEmpty)
            Text(
              workSummary,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(extras.join(' · '), style: AppText.bodyFaint),
          ],
          const SizedBox(height: 6),
          Text(
            info.templateName.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: C.textFaint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, size: 32, color: C.textFaint),
          SizedBox(height: 14),
          Text('Sem treinos registrados ainda', style: AppText.bodyDim),
        ],
      ),
    );
  }
}
