import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/logic/session_stats.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_record.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import '../widgets/nexus_card.dart';

/// Resumo ao finalizar o treino (Fase 3.10–3.11).
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId)).valueOrNull;
    final sets =
        ref.watch(sessionSetsProvider(sessionId)).valueOrNull ?? const <SetRecord>[];
    final cardio = ref.watch(sessionCardioProvider(sessionId)).valueOrNull;
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};

    final vol = SessionStats.volume(sets, exerciseById: exerciseById);

    // PR vs histórico (async via FutureBuilder simples).
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, double>>(
          future: ref
              .read(sessionRepositoryProvider)
              .maxWorkWeightByExercise(excludeSessionId: sessionId),
          builder: (context, snap) {
            final prevMax = snap.data ?? const <String, double>{};
            final highlights = SessionStats.highlights(
              sessionSets: sets,
              previousMaxByExercise: prevMax,
              exerciseById: exerciseById,
            );

            final duration = session == null
                ? '—'
                : _formatLongDuration(session.durationMinutes);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: C.accentSoft,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: C.accentSecondary,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TREINO CONCLUÍDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (session != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    session.templateName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppText.bodyDim,
                  ),
                ],
                const SizedBox(height: 24),
                NexusCard(
                  child: Column(
                    children: [
                      _RowStat(label: 'Duração', value: duration),
                      _RowStat(
                        label: 'Exercícios',
                        value: '${session?.exerciseCount ?? 0}',
                      ),
                      _RowStat(label: 'Séries', value: '${sets.length}'),
                      _RowStat(
                        label: 'Volume total',
                        value: '${formatKg(vol.totalKg)} kg',
                      ),
                    ],
                  ),
                ),
                if (cardio != null) ...[
                  const SizedBox(height: 16),
                  const Text('CARDIO', style: AppText.label),
                  const SizedBox(height: 10),
                  NexusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardio.type.label,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${cardio.durationMinutes} min'
                          '${cardio.distanceKm != null ? ' · ${formatKg(cardio.distanceKm!)} km' : ''}'
                          '${cardio.speedKmh != null ? ' · ${formatKg(cardio.speedKmh!)} km/h' : ''}'
                          '${cardio.inclinePercent != null ? ' · incl. ${formatKg(cardio.inclinePercent!)}%' : ''}'
                          '${cardio.floors != null ? ' · ${cardio.floors} andares' : ''}',
                          style: AppText.bodyDim,
                        ),
                        if (cardio.caloriesKcal != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'CALORIAS ESTIMADAS',
                            style: AppText.labelAccent,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cardio.caloriesKcal!.round()} kcal',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: C.accentSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (highlights.newPr != null ||
                    highlights.highestVolumeGroup != null) ...[
                  const SizedBox(height: 16),
                  const Text('DESTAQUES', style: AppText.label),
                  const SizedBox(height: 10),
                  if (highlights.newPr != null)
                    NexusCard(
                      selected: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NOVO RECORDE', style: AppText.labelAccent),
                          const SizedBox(height: 8),
                          Text(
                            highlights.newPr!.exerciseName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatKg(highlights.newPr!.weightKg)} kg × ${highlights.newPr!.reps.toInt()}',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: C.accentSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (highlights.highestVolumeGroup != null &&
                      highlights.highestVolumeKg != null) ...[
                    if (highlights.newPr != null) const SizedBox(height: 10),
                    NexusCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MAIOR VOLUME', style: AppText.label),
                          const SizedBox(height: 8),
                          Text(
                            highlights.highestVolumeGroup!.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatKg(highlights.highestVolumeKg!)} kg',
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 28),
                AppButton(
                  label: 'Início',
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Ver histórico',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {
                    ref.read(tabProvider.notifier).state = 1;
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatLongDuration(int minutes) {
    if (minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h <= 0) return '${m.toString().padLeft(2, '0')}:00';
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }
}

class _RowStat extends StatelessWidget {
  const _RowStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.bodyDim)),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
