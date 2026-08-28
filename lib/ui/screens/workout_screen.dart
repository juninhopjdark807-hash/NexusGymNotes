import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/exercise.dart';
import '../../state/active_workout.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
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

  @override
  void initState() {
    super.initState();
    _pages = PageController();
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
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
    await ref.read(activeWorkoutProvider.notifier).finish();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) {
      // Encerrado por fora: volta à tela anterior.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    // Anima a troca de página quando a navegação vem do estado
    // (botões) e não do próprio swipe.
    ref.listen<ActiveWorkout?>(activeWorkoutProvider, (previous, next) {
      if (next == null) return;
      final prevPage = previous?.page;
      if (prevPage == null || prevPage == next.page) return;
      _pages.animateToPage(
        next.page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });

    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};
    final total = workout.items.length;
    final elapsed = _tick.isAfter(workout.startedAt)
        ? _tick.difference(workout.startedAt)
        : Duration.zero;

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
              // Barra de progresso do treino
              _ProgressBar(
                value: total == 0 ? 1 : (workout.page + 1) / (total + 1),
              ),
              _WorkoutHeader(
                name: workout.templateName,
                pageLabel: total == 0 ? '' : '${workout.page.clamp(0, total) + 1}/$total',
                atCardio: workout.atCardio,
                elapsed: elapsed,
                canGoBack: workout.page > 0,
                onBack: () => ref.read(activeWorkoutProvider.notifier).previous(),
                onEnd: _confirmEnd,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const PageScrollPhysics(),
                  onPageChanged: (i) =>
                      ref.read(activeWorkoutProvider.notifier).goToPage(i),
                  children: [
                    ...workout.items.map(
                      (item) => ExercisePage(
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
                    ),
                    const CardioPage(),
                  ],
                ),
              ),
              if (!workout.atCardio)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: AppButton(
                    label: workout.isLastExercise ? 'Ir para cardio' : 'Próximo exercício',
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => ref.read(activeWorkoutProvider.notifier).next(),
                  ),
                ),
            ],
          ),
        ),
      ),
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
      color: C.surface,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0).toDouble(),
          child: Container(color: C.accent),
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
      padding: const EdgeInsets.fromLTRB(24, 10, 12, 8),
      child: Row(
        children: [
          if (canGoBack)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.chevron_left_rounded, color: C.textDim, size: 28),
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
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: C.textFaint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  atCardio ? 'CARDIO' : 'EXERCÍCIO $pageLabel',
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
          Text(
            formatElapsed(elapsed),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: C.textDim,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEnd,
            child: const Text(
              'ENCERRAR',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: C.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
