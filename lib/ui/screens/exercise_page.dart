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
/// Fluxo com mínimo de cliques:
/// referência -> aquecimento -> preparatória -> séries de trabalho.
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

  /// Pré-preenche os campos com as sugestões calculadas a partir da
  /// referência (somente campos ainda vazios — nunca sobrescreve).
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
    final sets = ref.read(activeSessionSetsProvider).valueOrNull ?? const <SetRecord>[];
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
      onSave: (w, r) =>
          ref.read(sessionRepositoryProvider).updateSet(set.copyWith(weightKg: w, reps: r)),
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
    final sets = ref.watch(activeSessionSetsProvider).valueOrNull ?? const <SetRecord>[];
    final exerciseId = widget.exercise.id;
    final mine = sets.where((s) => s.exerciseId == exerciseId).toList(growable: false);

    final warmupSet = _firstOf(mine, SetStage.aquecimento);
    final prepSet = _firstOf(mine, SetStage.preparatoria);
    final workSets = mine.where((s) => s.stage == SetStage.trabalho).toList()
      ..sort((a, b) => b.order.compareTo(a.order));

    // Séries do exercício em ordem cronológica (para intervalo).
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
    // Prefill quando a referência carregar. Riverpod 2.x não tem
    // fireImmediately em ref.listen — aplica no valor já resolvido
    // e escuta atualizações posteriores.
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do exercício + grupo muscular
          Text(
            widget.exercise.name,
            style: AppText.displayL,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            widget.exercise.muscleGroup.label.toUpperCase(),
            style: AppText.label,
          ),
          const SizedBox(height: 18),
          // Última referência (maior carga de trabalho anterior)
          _ReferenceRow(referenceKg: referenceKg),
          const SizedBox(height: 18),
          // Liga/desliga AQ e PR nesta sessão (sem alterar o template).
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
          const SizedBox(height: 22),
          // Aquecimento
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
            const SizedBox(height: 18),
          ],
          // Preparatória
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
            const SizedBox(height: 26),
          ],
          // Séries de trabalho
          const Text('SÉRIES DE TRABALHO', style: AppText.label),
          const SizedBox(height: 10),
          SetInputRow(
            weightController: _workWeight,
            repsController: _workReps,
            onRegister: () =>
                _register(SetStage.trabalho, _workWeight, _workReps),
          ),
          const SizedBox(height: 10),
          if (workSets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Nenhuma série registrada',
                style: AppText.bodyFaint,
              ),
            )
          else
            ...() {
              // Numeração pela ordem de registro (mais antiga = 1).
              final ascending = List<SetRecord>.of(workSets)
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              final numberById = <String, int>{
                for (var i = 0; i < ascending.length; i++)
                  ascending[i].id: i + 1,
              };
              return workSets.map(
                (s) => SetRow(
                  set: s,
                  setNumber: numberById[s.id],
                  onEdit: () => _editSet(s),
                  onDelete: () => _deleteSet(s),
                  intervalLabel: intervalById[s.id],
                ),
              );
            }(),
        ],
      ),
    );
  }
}

/// Chips para ligar/desligar AQ e PR durante a execução do treino.
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
        const SizedBox(width: 10),
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
        borderRadius: BorderRadius.circular(14),
        splashColor: C.accentSoft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: on ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(14),
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
                size: 18,
                color: on ? C.accentSecondary : C.textFaint,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
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

/// Etapa de aquecimento/preparatória: rótulo + sugestão + input (ou série registrada).
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: C.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${formatKg(suggestionKg!)} kg',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: C.accentSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// "Última referência" — maior carga de trabalho da execução anterior.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.referenceKg});

  final double? referenceKg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ÚLTIMA REFERÊNCIA', style: AppText.label),
            const SizedBox(height: 2),
            if (referenceKg != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatKg(referenceKg!),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: C.accentSecondary,
                      ),
                    ),
                    const TextSpan(
                      text: ' kg',
                      style: TextStyle(fontSize: 13, color: C.textFaint),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'sem histórico — informe a carga',
                style: AppText.bodyFaint,
              ),
          ],
        ),
      ],
    );
  }
}
