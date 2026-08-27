import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/models/workout_template.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
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
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
              child: Row(
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'NEXUS',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: '  ●',
                          style: TextStyle(fontSize: 11, color: C.accent),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(formatDayLabel(DateTime.now()), style: AppText.bodyFaint),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pushNewTemplate(context),
        backgroundColor: C.accent,
        foregroundColor: C.accentInk,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

/// Cartão de retomada do treino em andamento.
class _ActiveWorkoutCard extends ConsumerWidget {
  const _ActiveWorkoutCard({required this.session});

  final WorkoutSession session;

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(activeWorkoutProvider.notifier).resume(session.id);
    if (ok && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AppFrame(child: WorkoutScreen())),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _resume(context, ref),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(top: const BorderSide(color: C.accent, width: 2)),
        ),
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
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3),
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
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: C.accent,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: C.accentInk, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, this.lastRun});

  final WorkoutTemplate template;
  final DateTime? lastRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = template.exercises.isEmpty
        ? 'adicione exercícios'
        : '${template.exercises.length} exercícios'
            '${lastRun != null ? ' · último ${formatDateShort(lastRun!)}' : ''}';
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => HomeScreen.pushTemplate(context, template.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
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
                    template.name.toUpperCase(),
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: C.surface2,
              ),
              child: const Icon(Icons.fitness_center, color: C.textFaint, size: 30),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum treino ainda',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Crie seu primeiro treino e adicione os exercícios.',
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
