import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/logic/progression.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_record.dart';
import '../../domain/models/workout_template.dart';
import '../../state/providers.dart';
import '../widgets/edit_set_sheet.dart';
import '../widgets/set_row.dart';
import '../widgets/weight_reps_input.dart';

final _uuid = const Uuid();

/// Página de um único exercício durante a execução do treino.
///
/// Layout mobile-first:
/// - cabeçalho compacto fixo (nome, referência, AQ/PR);
/// - área central expansível com as séries (scroll só se o conteúdo crescer);
/// - rodapé (observações / próximo) fica fora, no [WorkoutScreen].
class ExercisePage extends ConsumerStatefulWidget {
  const ExercisePage({
    super.key,
    required this.item,
    required this.exercise,
  });

  final WorkoutExercise item;
  final Exercise exercise;

  @override
  ConsumerState<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends ConsumerState<ExercisePage> {
  late final TextEditingController _warmupWeight;
  late final TextEditingController _warmupReps;
  late final TextEditingController _prepWeight;
  late final TextEditingController _prepReps;
  late final TextEditingController _workWeight;
  late final TextEditingController _workReps;
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    _warmupWeight = TextEditingController();
    _warmupReps = TextEditingController(text: '10');
    _prepWeight = TextEditingController();
    _prepReps = TextEditingController(text: '10');
    _workWeight = TextEditingController();
    _workReps = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _warmupWeight.dispose();
    _warmupReps.dispose();
    _prepWeight.dispose();
    _prepReps.dispose();
    _workWeight.dispose();
    _workReps.dispose();
    super.dispose();
  }

  void _prefill(double? referenceKg) {
    if (referenceKg == null || _didPrefill) return;
    _didPrefill = true;
    if (widget.item.warmupEnabled && _warmupWeight.text.trim().isEmpty) {
      _warmupWeight.text = formatKg(Progression.warmupSuggestion(referenceKg));
    }
    if (widget.item.prepEnabled && _prepWeight.text.trim().isEmpty) {
      _prepWeight.text = formatKg(Progression.prepSuggestion(referenceKg));
    }
    if (_workWeight.text.trim().isEmpty) {
      _workWeight.text = formatKg(referenceKg);
    }
  }

  SetRecord? _firstOf(List<SetRecord> list, SetStage stage) {
    for (final s in list) {
      if (s.stage == stage) return s;
    }
    return null;
  }

  Future<void> _register(
    SetStage stage,
    TextEditingController weightController,
    TextEditingController repsController,
  ) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    final weight = parseKg(weightController.text);
    final reps = int.tryParse(repsController.text.trim());
    if (weight == null || reps == null || reps <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe peso e repetições'),
            backgroundColor: C.surface2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final sets =
        ref.read(activeSessionSetsProvider).valueOrNull ?? const <SetRecord>[];
    final order = sets
        .where((s) => s.exerciseId == widget.exercise.id && s.stage == stage)
        .length;
    await ref.read(sessionRepositoryProvider).saveSet(
          SetRecord(
            id: _uuid.v4(),
            sessionId: workout.sessionId,
            exerciseId: widget.exercise.id,
            stage: stage,
            weightKg: weight,
            reps: reps,
            order: order,
            createdAt: DateTime.now(),
          ),
        );
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _editSet(SetRecord set) async {
    await showEditSetSheet(
      context,
      set: set,
      onSave: (w, r) => ref
          .read(sessionRepositoryProvider)
          .updateSet(set.copyWith(weightKg: w, reps: r)),
      onDelete: () => _deleteSet(set),
    );
  }

  Future<void> _deleteSet(SetRecord set) async {
    final repo = ref.read(sessionRepositoryProvider);
    await repo.deleteSet(set.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Expanded(
              child: Text(
                'Série excluída',
                style: TextStyle(fontSize: 13, color: C.textDim),
              ),
            ),
            TextButton(
              onPressed: () => repo.saveSet(set),
              child: const Text(
                'DESFAZER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: C.accent,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.surface2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sets =
        ref.watch(activeSessionSetsProvider).valueOrNull ?? const <SetRecord>[];
    final exerciseId = widget.exercise.id;
    final mine =
        sets.where((s) => s.exerciseId == exerciseId).toList(growable: false);

    final warmupSet = _firstOf(mine, SetStage.aquecimento);
    final prepSet = _firstOf(mine, SetStage.preparatoria);
    final workSets = mine.where((s) => s.stage == SetStage.trabalho).toList()
      ..sort((a, b) => b.order.compareTo(a.order));

    final chronological = List<SetRecord>.of(mine)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final intervalById = <String, String>{};
    for (var i = 0; i < chronological.length; i++) {
      if (i == 0) {
        intervalById[chronological[i].id] = '—';
      } else {
        final delta = chronological[i]
            .createdAt
            .difference(chronological[i - 1].createdAt);
        intervalById[chronological[i].id] = formatInterval(delta);
      }
    }

    final reference = ref.watch(referenceProvider(exerciseId));
    final referenceKg = reference.valueOrNull;
    if (!_didPrefill && reference.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefill(referenceKg);
      });
    }
    ref.listen<AsyncValue<double?>>(
      referenceProvider(exerciseId),
      (previous, next) {
        next.whenData(_prefill);
      },
    );

    final warmupOn = widget.item.warmupEnabled;
    final prepOn = widget.item.prepEnabled;

    // Numeração das séries de trabalho (ordem de registro).
    final workAscending = List<SetRecord>.of(workSets)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final workNumberById = <String, int>{
      for (var i = 0; i < workAscending.length; i++) workAscending[i].id: i + 1,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ——— Cabeçalho compacto (não rola) ———
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exercise.name,
                style: AppText.displayM,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    widget.exercise.muscleGroup.label.toUpperCase(),
                    style: AppText.label,
                  ),
                  const Spacer(),
                  _CompactReference(referenceKg: referenceKg),
                ],
              ),
              const SizedBox(height: 10),
              _SessionStageToggles(
                warmupOn: warmupOn,
                prepOn: prepOn,
                onToggleWarmup: () => ref
                    .read(activeWorkoutProvider.notifier)
                    .setItemStages(
                      widget.item.id,
                      warmupEnabled: !warmupOn,
                    ),
                onTogglePrep: () => ref
                    .read(activeWorkoutProvider.notifier)
                    .setItemStages(
                      widget.item.id,
                      prepEnabled: !prepOn,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ——— Corpo: cresce e só rola se passar da viewport ———
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            // Não força bounce/scroll quando o conteúdo cabe.
            physics: const ClampingScrollPhysics(),
            children: [
              if (warmupOn) ...[
                _StageSection(
                  title: 'AQUECIMENTO',
                  suggestionKg: referenceKg == null
                      ? null
                      : Progression.warmupSuggestion(referenceKg),
                  child: warmupSet == null
                      ? SetInputRow(
                          weightController: _warmupWeight,
                          repsController: _warmupReps,
                          onRegister: () => _register(
                            SetStage.aquecimento,
                            _warmupWeight,
                            _warmupReps,
                          ),
                        )
                      : SetRow(
                          set: warmupSet,
                          onEdit: () => _editSet(warmupSet),
                          onDelete: () => _deleteSet(warmupSet),
                          intervalLabel: intervalById[warmupSet.id],
                        ),
                ),
                const SizedBox(height: 12),
              ],
              if (prepOn) ...[
                _StageSection(
                  title: 'PREPARATÓRIA',
                  suggestionKg: referenceKg == null
                      ? null
                      : Progression.prepSuggestion(referenceKg),
                  child: prepSet == null
                      ? SetInputRow(
                          weightController: _prepWeight,
                          repsController: _prepReps,
                          onRegister: () => _register(
                            SetStage.preparatoria,
                            _prepWeight,
                            _prepReps,
                          ),
                        )
                      : SetRow(
                          set: prepSet,
                          onEdit: () => _editSet(prepSet),
                          onDelete: () => _deleteSet(prepSet),
                          intervalLabel: intervalById[prepSet.id],
                        ),
                ),
                const SizedBox(height: 12),
              ],
              const Text('SÉRIES DE TRABALHO', style: AppText.label),
              const SizedBox(height: 8),
              SetInputRow(
                weightController: _workWeight,
                repsController: _workReps,
                onRegister: () =>
                    _register(SetStage.trabalho, _workWeight, _workReps),
              ),
              const SizedBox(height: 8),
              if (workSets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Nenhuma série registrada',
                    style: AppText.bodyFaint,
                  ),
                )
              else
                for (final s in workSets)
                  SetRow(
                    set: s,
                    setNumber: workNumberById[s.id],
                    onEdit: () => _editSet(s),
                    onDelete: () => _deleteSet(s),
                    intervalLabel: intervalById[s.id],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Referência compacta em uma linha (economiza altura vertical).
class _CompactReference extends StatelessWidget {
  const _CompactReference({required this.referenceKg});

  final double? referenceKg;

  @override
  Widget build(BuildContext context) {
    if (referenceKg == null) {
      return const Text(
        'sem ref.',
        style: AppText.bodyFaint,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'REF ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: C.textFaint,
            ),
          ),
          TextSpan(
            text: formatKg(referenceKg!),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: C.accentSecondary,
            ),
          ),
          const TextSpan(
            text: ' kg',
            style: TextStyle(fontSize: 11, color: C.textFaint),
          ),
        ],
      ),
    );
  }
}

class _SessionStageToggles extends StatelessWidget {
  const _SessionStageToggles({
    required this.warmupOn,
    required this.prepOn,
    required this.onToggleWarmup,
    required this.onTogglePrep,
  });

  final bool warmupOn;
  final bool prepOn;
  final VoidCallback onToggleWarmup;
  final VoidCallback onTogglePrep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SessionStageChip(
            label: 'Aquecimento',
            on: warmupOn,
            onTap: onToggleWarmup,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SessionStageChip(
            label: 'Preparatória',
            on: prepOn,
            onTap: onTogglePrep,
          ),
        ),
      ],
    );
  }
}

class _SessionStageChip extends StatelessWidget {
  const _SessionStageChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: C.accentSoft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: on ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on ? C.accent.withValues(alpha: 0.55) : C.stroke,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                on
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 16,
                color: on ? C.accentSecondary : C.textFaint,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: on ? C.accentSecondary : C.textDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  const _StageSection({
    required this.title,
    required this.suggestionKg,
    required this.child,
  });

  final String title;
  final double? suggestionKg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppText.label),
            const Spacer(),
            if (suggestionKg != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: C.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${formatKg(suggestionKg!)} kg',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.accentSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
