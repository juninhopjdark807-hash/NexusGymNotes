import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
import 'template_editor_screen.dart';
import 'workout_screen.dart';

/// Visão do treino planejado: resume a sequência e oferece
/// a ação principal do app — **iniciar o treino**.
class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key, required this.templateId});

  final String templateId;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final template = ref.read(templateProvider(templateId)).valueOrNull;
    if (template == null) return;
    final started = await ref.read(activeWorkoutProvider.notifier).start(template);
    if (started && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AppFrame(child: WorkoutScreen())),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = ref.watch(templateProvider(templateId)).valueOrNull;
    if (template == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: C.textFaint)),
      );
    }
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'TREINO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: C.textFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Text(
                    template.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.exercises.isEmpty
                        ? 'nenhum exercício ainda'
                        : '${template.exercises.length} exercícios',
                    style: AppText.bodyDim,
                  ),
                  const SizedBox(height: 24),
                  if (template.exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Adicione exercícios para iniciar o treino.',
                        style: AppText.bodyFaint,
                      ),
                    )
                  else
                    for (var i = 0; i < template.exercises.length; i++)
                      _SequenceRow(
                        number: i + 1,
                        name:
                            exerciseById[template.exercises[i].exerciseId]?.name ?? 'Exercício',
                        muscle: exerciseById[template.exercises[i].exerciseId]
                                    ?.muscleGroup
                                    .label ??
                                '',
                        warmup: template.exercises[i].warmupEnabled,
                        prep: template.exercises[i].prepEnabled,
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  AppButton(
                    label: 'Iniciar treino',
                    icon: Icons.play_arrow_rounded,
                    onPressed:
                        template.exercises.isEmpty ? null : () => _start(context, ref),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Editar treino',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AppFrame(child: TemplateEditorScreen(templateId: templateId)),
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

class _SequenceRow extends StatelessWidget {
  const _SequenceRow({
    required this.number,
    required this.name,
    required this.muscle,
    required this.warmup,
    required this.prep,
  });

  final int number;
  final String name;
  final String muscle;
  final bool warmup;
  final bool prep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: C.textFaint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          muscle.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            color: C.textFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (warmup)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.accentSoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'AQ',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: C.accent,
                        ),
                      ),
                    ),
                  if (prep)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: C.accentSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'PR',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: C.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
