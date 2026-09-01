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
///
/// Modo de seleção opcional (botão "Selecionar" no topo) para excluir
/// um ou mais treinos — sem checkboxes permanentes nos cards.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _selecting = false;
  final Set<String> _selected = <String>{};
  bool _deleting = false;

  void _enterSelect() => setState(() {
        _selecting = true;
        _selected.clear();
      });

  void _exitSelect() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<SessionSummary> summaries) {
    setState(() {
      final allIds = summaries.map((s) => s.session.id).toSet();
      final allSelected =
          allIds.isNotEmpty && allIds.every(_selected.contains);
      if (allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || _deleting) return;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(
          count == 1 ? 'Excluir treino?' : 'Excluir $count treinos?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita. Séries, cardio e observações '
          'dessas sessões serão removidos.',
          style: TextStyle(fontSize: 14, color: C.textDim, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'EXCLUIR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: C.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(sessionRepositoryProvider)
          .deleteSessions(List<String>.of(_selected));
      if (!mounted) return;
      _exitSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1
                ? 'Treino excluído do histórico'
                : '$count treinos excluídos do histórico',
          ),
          backgroundColor: C.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaries =
        ref.watch(sessionsProvider).valueOrNull ?? const <SessionSummary>[];

    // Se a lista mudou e o modo seleção ficou sem itens, sai do modo.
    if (_selecting && summaries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selecting) _exitSelect();
      });
    }

    final groups = <String, List<SessionSummary>>{};
    final groupOrder = <String>[];
    for (final s in summaries) {
      final key = dateKey(s.session.startedAt);
      final list = groups.putIfAbsent(key, () => []);
      list.add(s);
      if (!groupOrder.contains(key)) groupOrder.add(key);
    }

    var totalSets = 0;
    var totalMin = 0;
    for (final s in summaries) {
      totalSets += s.session.totalSets;
      totalMin += s.session.durationMinutes;
    }

    final allIds = summaries.map((s) => s.session.id).toSet();
    final allSelected =
        allIds.isNotEmpty && allIds.every(_selected.contains);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selecting
                          ? (_selected.isEmpty
                              ? 'SELECIONAR'
                              : '${_selected.length} SEL.')
                          : 'HISTÓRICO',
                      style: AppText.displayM,
                    ),
                  ),
                  if (summaries.isNotEmpty && !_selecting)
                    TextButton(
                      onPressed: _enterSelect,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Selecionar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.textDim,
                        ),
                      ),
                    ),
                  if (_selecting)
                    TextButton(
                      onPressed: _deleting ? null : _exitSelect,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.textDim,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_selecting && summaries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed:
                          _deleting ? null : () => _selectAll(summaries),
                      child: Text(
                        allSelected ? 'Deselecionar tudo' : 'Selecionar tudo',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.accentSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _selected.isEmpty || _deleting
                          ? null
                          : _deleteSelected,
                      child: Text(
                        _deleting
                            ? 'Excluindo…'
                            : (_selected.isEmpty
                                ? 'Excluir'
                                : 'Excluir (${_selected.length})'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _selected.isEmpty || _deleting
                              ? C.textFaint
                              : C.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (summaries.isNotEmpty)
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
                            _SessionCard(
                              summary: s,
                              selecting: _selecting,
                              selected: _selected.contains(s.session.id),
                              onToggle: () => _toggle(s.session.id),
                            ),
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
  const _SessionCard({
    required this.summary,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });

  final SessionSummary summary;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = summary.session;
    final cardio = summary.cardio;
    final meta =
        '${formatDuration(s.durationMinutes)} · ${s.exerciseCount} exercícios'
        '${cardio != null ? ' · ${cardio.type.label} ${cardio.durationMinutes} min' : ''}';

    return NexusCard(
      margin: const EdgeInsets.only(bottom: 10),
      selected: selecting && selected,
      onTap: selecting
          ? onToggle
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AppFrame(child: SessionDetailScreen(sessionId: s.id)),
                ),
              ),
      child: Row(
        children: [
          // Checkbox só aparece no modo seleção (não ocupa espaço no modo normal).
          if (selecting) ...[
            _SelectMark(selected: selected),
            const SizedBox(width: 12),
          ] else
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
          if (!selecting) const SizedBox(width: 14),
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
          if (!selecting)
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

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? C.accent : Colors.transparent,
        border: Border.all(
          color: selected ? C.accent : C.stroke,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: C.accentInk)
          : null,
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
