import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../state/providers.dart';
import '../widgets/nexus_card.dart';

/// Visão de progressão: volume recente, PRs e últimos treinos.
/// Dados reais do histórico — sem mock.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        ref.watch(sessionsProvider).valueOrNull ?? const <SessionSummary>[];
    final recent = summaries.take(8).toList(growable: false);

    var totalSets = 0;
    var totalMinutes = 0;
    for (final s in summaries) {
      totalSets += s.session.totalSets;
      totalMinutes += s.session.durationMinutes;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 26, 24, 6),
              child: Text('PROGRESSÃO', style: AppText.displayM),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text(
                'Visão simples do que você já registrou',
                style: AppText.bodyDim,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'TREINOS',
                          value: '${summaries.length}',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'SÉRIES',
                          value: '$totalSets',
                          icon: Icons.replay_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'MIN',
                          value: '$totalMinutes',
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('VOLUME RECENTE', style: AppText.label),
                  const SizedBox(height: 12),
                  NexusCard(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    child: _VolumeBars(summaries: recent),
                  ),
                  const SizedBox(height: 22),
                  const Text('ÚLTIMOS TREINOS', style: AppText.label),
                  const SizedBox(height: 12),
                  if (summaries.isEmpty)
                    const NexusCard(
                      child: Text(
                        'Complete um treino para ver a progressão.',
                        style: AppText.bodyDim,
                      ),
                    )
                  else
                    for (final s in recent.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NexusCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: C.accentSoft,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: C.accentSecondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.session.templateName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatDateShort(s.session.startedAt)} · '
                                      '${formatDuration(s.session.durationMinutes)} · '
                                      '${s.session.totalSets} séries',
                                      style: AppText.bodyFaint,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: C.accentSecondary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }
}

class _VolumeBars extends StatelessWidget {
  const _VolumeBars({required this.summaries});

  final List<SessionSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: Text('Sem dados ainda', style: AppText.bodyFaint),
        ),
      );
    }
    // Barras por total_sets (proxy simples de volume).
    final values = summaries.map((s) => s.session.totalSets.toDouble()).toList();
    final maxV = values.fold<double>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = values.length - 1; i >= 0; i--) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: (values[i] / maxV).clamp(0.08, 1.0),
                      widthFactor: 1,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              C.accent,
                              C.accentSecondary.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summaries[i].session.startedAt.day}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: C.textFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
