import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/models/workout_template.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
import '../widgets/muscle_icon.dart';
import '../widgets/nexus_card.dart';
import 'template_editor_screen.dart';
import 'template_screen.dart';
import 'workout_screen.dart';

/// Tela inicial: treinos criados + treino em andamento (retomada).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static void pushNewTemplate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AppFrame(child: TemplateEditorScreen()),
      ),
    );
  }

  static void pushTemplate(BuildContext context, String templateId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppFrame(child: TemplateScreen(templateId: templateId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates =
        ref.watch(templatesProvider).valueOrNull ?? const <WorkoutTemplate>[];
    final summaries =
        ref.watch(sessionsProvider).valueOrNull ?? const <SessionSummary>[];
    final active = ref.watch(activeSessionProvider).valueOrNull;
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};

    final lastRunByTemplate = <String, DateTime>{};
    for (final s in summaries) {
      final tid = s.session.templateId;
      if (tid == null) continue;
      final existing = lastRunByTemplate[tid];
      if (existing == null || s.session.startedAt.isAfter(existing)) {
        lastRunByTemplate[tid] = s.session.startedAt;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Row(
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'NEXUS',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: ' GYM',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: C.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: C.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C.strokeSoft),
                    ),
                    child: Text(
                      formatDayLabel(DateTime.now()),
                      style: AppText.bodyFaint,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Text('TREINOS', style: AppText.displayM),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 4, bottom: 110),
                children: [
                  if (active != null) _ActiveWorkoutCard(session: active),
                  if (templates.isEmpty)
                    _EmptyState(onCreate: () => pushNewTemplate(context))
                  else
                    for (final t in templates)
                      _TemplateCard(
                        template: t,
                        lastRun: lastRunByTemplate[t.id],
                        exerciseById: exerciseById,
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

class _ActiveWorkoutCard extends ConsumerWidget {
  const _ActiveWorkoutCard({required this.session});

  final WorkoutSession session;

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(activeWorkoutProvider.notifier).resume(session.id);
    if (ok && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AppFrame(child: WorkoutScreen()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexusCard(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      accentTop: true,
      selected: true,
      onTap: () => _resume(context, ref),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TREINO EM ANDAMENTO', style: AppText.labelAccent),
                const SizedBox(height: 6),
                Text(
                  session.templateName.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'iniciado às ${formatTime(session.startedAt)}',
                  style: AppText.bodyFaint,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.accent,
              boxShadow: [
                BoxShadow(
                  color: C.accent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: C.accentInk,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.exerciseById,
    this.lastRun,
  });

  final WorkoutTemplate template;
  final Map<String, Exercise> exerciseById;
  final DateTime? lastRun;

  List<MuscleGroup> _topGroups() {
    final counts = <MuscleGroup, int>{};
    for (final item in template.exercises) {
      final g = exerciseById[item.exerciseId]?.muscleGroup;
      if (g == null) continue;
      counts[g] = (counts[g] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _topGroups();
    final groupLabel = groups.isEmpty
        ? 'adicione exercícios'
        : groups.map((g) => g.label).join(' · ');
    final countLabel = template.exercises.isEmpty
        ? null
        : '${template.exercises.length} exercícios'
            '${lastRun != null ? ' · último ${formatDateShort(lastRun!)}' : ''}';

    return NexusCard(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      onTap: () => HomeScreen.pushTemplate(context, template.id),
      child: Row(
        children: [
          if (groups.isNotEmpty)
            MuscleBadge(group: groups.first, size: 42, active: true)
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: C.surface2,
                border: Border.all(color: C.stroke),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: C.textFaint,
                size: 18,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(groupLabel, style: AppText.bodyDim),
                if (countLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(countLabel, style: AppText.bodyFaint),
                ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: NexusCard(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: C.accentSoft,
                border: Border.all(color: C.accent.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: C.accentSecondary,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum treino ainda',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie seu primeiro treino e adicione os exercícios da biblioteca.',
              style: AppText.bodyDim,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Criar primeiro treino', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
