import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/nexus_card.dart';
import 'session_detail_screen.dart';

/// Histórico completo de treinos realizados, agrupado por data.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        ref.watch(sessionsProvider).valueOrNull ?? const <SessionSummary>[];

    final groups = <String, List<SessionSummary>>{};
    final groupOrder = <String>[];
    for (final s in summaries) {
      final key = dateKey(s.session.startedAt);
      final list = groups.putIfAbsent(key, () => []);
      list.add(s);
      if (!groupOrder.contains(key)) groupOrder.add(key);
    }

    // Destaques do histórico (volume / maior carga proxy).
    var totalSets = 0;
    var totalMin = 0;
    for (final s in summaries) {
      totalSets += s.session.totalSets;
      totalMin += s.session.durationMinutes;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 26, 24, 6),
              child: Text('HISTÓRICO', style: AppText.displayM),
            ),
            if (summaries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'VOLUME',
                        value: '$totalSets séries',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'TEMPO',
                        value: formatDuration(totalMin),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: summaries.isEmpty
                  ? const _HistoryEmpty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 110),
                      children: [
                        for (final key in groupOrder) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 10),
                            child: Text(
                              formatDate(parseDateKey(key)).toUpperCase(),
                              style: AppText.label,
                            ),
                          ),
                          for (final s in groups[key]!)
                            _SessionCard(summary: s),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.session;
    final cardio = summary.cardio;
    final meta =
        '${formatDuration(s.durationMinutes)} · ${s.exerciseCount} exercícios'
        '${cardio != null ? ' · ${cardio.type.label} ${cardio.durationMinutes} min' : ''}';
    return NexusCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AppFrame(child: SessionDetailScreen(sessionId: s.id)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: C.accentSoft,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: C.accentSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.templateName.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(meta, style: AppText.bodyFaint),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: C.textFaint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 34, color: C.textFaint),
          SizedBox(height: 14),
          Text('Nenhum treino realizado ainda', style: AppText.bodyDim),
        ],
      ),
    );
  }
}
