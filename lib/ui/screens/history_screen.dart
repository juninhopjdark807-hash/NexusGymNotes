import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../app_frame.dart';
import 'session_detail_screen.dart';

/// Histórico completo de treinos realizados, agrupado por data.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        ref.watch(sessionsProvider).valueOrNull ?? const <SessionSummary>[];

    // Agrupa por dia, preservando a ordem (mais recente primeiro).
    final groups = <String, List<SessionSummary>>{};
    final groupOrder = <String>[];
    for (final s in summaries) {
      final key = dateKey(s.session.startedAt);
      final list = groups.putIfAbsent(key, () => []);
      list.add(s);
      if (!groupOrder.contains(key)) groupOrder.add(key);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
              child: const Text(
                'HISTÓRICO',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
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
                          for (final s in groups[key]!) _SessionCard(summary: s),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppFrame(child: SessionDetailScreen(sessionId: s.id)),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.templateName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(meta, style: AppText.bodyFaint),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: C.textFaint, size: 22),
          ],
        ),
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
