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
            const _HomeHeader(),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    // Telas menores: reduz espaçamento/tamanhos antes de qualquer outra coisa.
    final h = MediaQuery.sizeOf(context).height;
    final compact = h < 700;
    // Header enxuto: menos altura, sem vãos grandes.
    final padV = compact ? 12.0 : 16.0;
    final logoSize = compact ? 24.0 : 27.0;
    final taglineSize = compact ? 11.5 : 12.5;
    // Marca ("iconeinicial"): presença equivalente (ou um pouco acima) do
    // conjunto NEXUS GYM — quadrado de marca, não botão, sem moldura.
    final markSize = compact ? 40.0 : 48.0;
    final markGap = compact ? 8.0 : 10.0;

    return ClipRect(
      child: Stack(
        children: [
          // ---- Elemento abstrato: glow radial roxo discreto (ext. sup. dir.)
          Positioned(
            top: compact ? -70 : -50,
            right: compact ? -90 : -60,
            child: IgnorePointer(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      C.accent.withValues(alpha: 0.12),
                      C.accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // ---- Elemento abstrato: glow sutil atrás da marca (identidade
          // do "iconeinicial": dark + roxo + glow discreto) ----
          Positioned(
            left: compact ? -62 : -54,
            top: compact ? -66 : -58,
            child: IgnorePointer(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      C.accent.withValues(alpha: 0.11),
                      C.accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // ---- Elemento abstrato: anel/linha sutil (ext. inf. esq.)
          Positioned(
            bottom: -120,
            left: compact ? -70 : -50,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: C.accent.withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // ---- Conteúdo do header ----
          Padding(
            padding: EdgeInsets.fromLTRB(24, padV, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ---- Marca: asset "iconeinicial" + NEXUS GYM ----
                    // O ícone é elemento visual (parte da marca), NÃO botão:
                    // sem círculo, moldura ou fundo adicionais. Ocupa a própria
                    // área, alinhado verticalmente com a linha "NEXUS GYM".
                    Image.asset(
                      'iconeinicio.png',
                      width: markSize,
                      height: markSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                    SizedBox(width: markGap),
                    // Bloco de texto: começa APÓS a área do ícone. A tagline
                    // está na MESMA coluna do "NEXUS", portanto herda o
                    // alinhamento esquerdo do "N" — sem deslocamentos, sem
                    // coordenadas absolutas.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Linha do título com a MESMA altura do ícone:
                          // o "NEXUS GYM" fica verticalmente centralizado com
                          // a marca (como na referência visual).
                          SizedBox(
                            height: markSize,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                // Telas estreitas: o texto reduz para caber
                                // em uma linha (ícone mantém o tamanho).
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'NEXUS',
                                        style: TextStyle(
                                          fontFamily: AppFonts.display,
                                          fontSize: logoSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                          height: 1.0,
                                          color: C.text,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' GYM',
                                        style: TextStyle(
                                          fontFamily: AppFonts.display,
                                          fontSize: logoSize,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.0,
                                          height: 1.0,
                                          color: C.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 4 : 6),
                          // Alinhada com o "N" de NEXUS (mesma origem X do
                          // título) — nunca abaixo do ícone; escala em telas
                          // estreitas para nunca quebrar/transbordar.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Seu treino. Seu progresso.',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: taglineSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                height: 1.2,
                                color: C.textDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const _DateBadge(),
                  ],
                ),

                SizedBox(height: compact ? 11 : 16),

                // ---- Separação elegante: linha com gradiente sutil ----
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        C.stroke.withValues(alpha: 0.0),
                        C.stroke.withValues(alpha: 0.75),
                        C.stroke.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                SizedBox(height: compact ? 8 : 11),

                // ---- Seção de treinos ----
                Row(
                  children: [
                    const Text('TREINOS', style: AppText.displayM),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              C.accent.withValues(alpha: 0.55),
                              C.accent.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 6 : 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de data: [ícone calendário] TER · 1 SET — compacto, com borda.
class _DateBadge extends StatelessWidget {
  const _DateBadge();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 14,
            color: C.accentSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            formatDayLabel(DateTime.now()),
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: C.textDim,
            ),
          ),
        ],
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
