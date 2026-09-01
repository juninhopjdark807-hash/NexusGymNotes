import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/exercise.dart';
import '../../state/active_workout.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import '../widgets/session_summary_dialog.dart';
import 'cardio_page.dart';
import 'exercise_page.dart';

/// Tela de execução do treino — a interface mais importante do app.
///
/// Um exercício por vez; navegação por botão grande ou swipe horizontal.
/// Ao terminar o último exercício, a página de cardio abre diretamente.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  late final PageController _pages;
  Timer? _ticker;
  DateTime _tick = DateTime.now();

  /// Evita loop: onPageChanged ↔ atualização de estado.
  bool _ignorePageCallback = false;

  @override
  void initState() {
    super.initState();
    // Restaura a página salva (Voltar ao treino).
    final initial =
        ref.read(activeWorkoutProvider)?.page ?? 0;
    _pages = PageController(initialPage: initial);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pages.dispose();
    super.dispose();
  }

  int _maxPage(ActiveWorkout workout) => workout.items.length; // cardio

  Future<void> _animateTo(int page) async {
    if (!_pages.hasClients) return;
    _ignorePageCallback = true;
    try {
      await _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } finally {
      // Libera após o frame da animação.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ignorePageCallback = false;
        });
      } else {
        _ignorePageCallback = false;
      }
    }
  }

  /// Navega para a página [page] atualizando estado + PageView juntos.
  Future<void> _goTo(int page) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    final target = page.clamp(0, _maxPage(workout));
    if (target == workout.page &&
        _pages.hasClients &&
        (_pages.page?.round() ?? workout.page) == target) {
      return;
    }
    ref.read(activeWorkoutProvider.notifier).goToPage(target);
    await _animateTo(target);
  }

  Future<void> _goNext() async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    await _goTo(workout.page + 1);
  }

  Future<void> _goPrevious() async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    await _goTo(workout.page - 1);
  }

  void _onPageChanged(int index) {
    if (_ignorePageCallback) return;
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    if (index == workout.page) return;
    ref.read(activeWorkoutProvider.notifier).goToPage(index);
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Encerrar treino?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'As séries já registradas serão salvas no histórico.',
          style: TextStyle(fontSize: 14, color: C.textDim, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'ENCERRAR',
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
    final sessionId = ref.read(activeWorkoutProvider)?.sessionId;
    if (sessionId == null) return;
    // Evita tela preta: finish + pop + dialog no root navigator.
    await finishWorkoutAndShowSummary(
      context,
      sessionId: sessionId,
      finishSession: () => ref.read(activeWorkoutProvider.notifier).finish(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) {
      // Estado limpo após finish — a navegação/resumo é feita pelo
      // fluxo de finalização (finishWorkoutAndShowSummary). Não dar
      // pop automático aqui (causava tela preta + dialog perdido).
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: C.textFaint),
        ),
      );
    }

    // Garante sincronia PageView ↔ estado (ex.: após rebuild).
    ref.listen<ActiveWorkout?>(activeWorkoutProvider, (previous, next) {
      if (next == null) return;
      if (previous?.page == next.page) return;
      if (!_pages.hasClients) return;
      final current = _pages.page?.round() ?? previous?.page ?? 0;
      if (current != next.page) {
        _animateTo(next.page);
      }
    });

    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};
    final total = workout.items.length;
    final elapsed = _tick.isAfter(workout.startedAt)
        ? _tick.difference(workout.startedAt)
        : Duration.zero;

    // Páginas: exercícios (0..n-1) + cardio (n).
    final pageChildren = <Widget>[
      for (final item in workout.items)
        ExercisePage(
          key: ValueKey('exercise-${item.id}'),
          item: item,
          exercise: exerciseById[item.exerciseId] ??
              Exercise(
                id: item.exerciseId,
                name: 'Exercício',
                muscleGroup: MuscleGroup.outros,
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
        ),
      const CardioPage(key: ValueKey('cardio')),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ProgressBar(
                value: total == 0 ? 1.0 : (workout.page + 1) / (total + 1),
              ),
              _WorkoutHeader(
                name: workout.templateName,
                pageLabel: total == 0
                    ? ''
                    : '${workout.page.clamp(0, total - 1 < 0 ? 0 : total - 1) + 1}/$total',
                atCardio: workout.atCardio,
                elapsed: elapsed,
                canGoBack: workout.page > 0,
                onBack: _goPrevious,
                onEnd: _confirmEnd,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  // Permite swipe entre exercícios e cardio.
                  physics: const BouncingScrollPhysics(
                    parent: PageScrollPhysics(),
                  ),
                  onPageChanged: _onPageChanged,
                  children: pageChildren,
                ),
              ),
              if (!workout.atCardio)
                SafeArea(
                  top: false,
                  child: Padding(
                    // Rodapé fixo e compacto — sempre visível fora do scroll.
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: _WorkoutFooter(
                      workout: workout,
                      exerciseById: exerciseById,
                      onNext: _goNext,
                      onFinish: () => _goTo(workout.items.length),
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

/// Rodapé: observação + próximo exercício / finalizar.
class _WorkoutFooter extends ConsumerWidget {
  const _WorkoutFooter({
    required this.workout,
    required this.exerciseById,
    required this.onNext,
    required this.onFinish,
  });

  final ActiveWorkout workout;
  final Map<String, Exercise> exerciseById;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  Future<void> _openNote(BuildContext context, WidgetRef ref) async {
    final item = workout.currentExercise;
    if (item == null) return;
    final exercise = exerciseById[item.exerciseId];
    final existing = await ref
        .read(sessionRepositoryProvider)
        .noteForExercise(workout.sessionId, item.exerciseId);
    if (!context.mounted) return;
    final controller = TextEditingController(text: existing ?? '');
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: C.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'OBSERVAÇÃO',
                style: AppText.label,
              ),
              const SizedBox(height: 4),
              Text(
                exercise?.name ?? 'Exercício',
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nota desta execução — não altera o exercício no catálogo.',
                style: AppText.bodyFaint,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                maxLength: 280,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Aumentar carga na próxima sessão',
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Salvar',
                onPressed: () => Navigator.of(ctx).pop(controller.text),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: const Text(
                  'LIMPAR OBSERVAÇÃO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: C.textDim,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (saved == null) return;
    await ref.read(sessionRepositoryProvider).saveExerciseNote(
          sessionId: workout.sessionId,
          exerciseId: item.exerciseId,
          note: saved,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = workout.currentExercise;
    final noteKey = item == null
        ? ''
        : '${workout.sessionId}|${item.exerciseId}';
    final hasNote = noteKey.isEmpty
        ? false
        : (ref.watch(exerciseNoteProvider(noteKey)).valueOrNull != null);

    String nextLabel;
    VoidCallback onPressed;
    if (workout.isLastExercise) {
      nextLabel = 'Finalizar treino';
      onPressed = onFinish;
    } else {
      final nextItem = workout.items[workout.page + 1];
      final nextName =
          exerciseById[nextItem.exerciseId]?.name ?? 'Exercício';
      nextLabel = 'Próximo: $nextName';
      onPressed = onNext;
    }

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item == null ? null : () => _openNote(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 52,
              height: 56,
              decoration: BoxDecoration(
                color: C.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasNote
                      ? C.accent.withValues(alpha: 0.5)
                      : C.stroke,
                ),
              ),
              child: Icon(
                hasNote
                    ? Icons.sticky_note_2_rounded
                    : Icons.sticky_note_2_outlined,
                color: hasNote ? C.accentSecondary : C.textDim,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: nextLabel,
            icon: Icons.chevron_right_rounded,
            iconAtEnd: true,
            height: 56,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      color: C.surface2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [C.accent, C.accentSecondary],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({
    required this.name,
    required this.pageLabel,
    required this.atCardio,
    required this.elapsed,
    required this.canGoBack,
    required this.onBack,
    required this.onEnd,
  });

  final String name;
  final String pageLabel;
  final bool atCardio;
  final Duration elapsed;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 4),
      child: Row(
        children: [
          if (canGoBack)
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: C.textDim,
                    size: 28,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: C.textFaint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  atCardio ? 'CARDIO' : 'EXERCÍCIO $pageLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: C.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatElapsed(elapsed),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: C.textDim,
            ),
          ),
          TextButton(
            onPressed: onEnd,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'ENCERRAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: C.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
