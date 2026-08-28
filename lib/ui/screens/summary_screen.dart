import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';

/// Tela de confirmação após o encerramento do treino.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId)).valueOrNull;
    final sets = ref.watch(sessionSetsProvider(sessionId)).valueOrNull ?? const [];
    final cardio = ref.watch(sessionCardioProvider(sessionId)).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
          child: Column(
            children: [
              const SizedBox(height: 26),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: C.accentSoft,
                ),
                child: const Icon(Icons.check_rounded, color: C.accentSecondary, size: 44),
              ),
              const SizedBox(height: 24),
              const Text(
                'TREINO CONCLUÍDO',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              if (session != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${session.templateName.toUpperCase()} · ${formatDuration(session.durationMinutes)}',
                  style: AppText.bodyDim,
                ),
              ],
              const SizedBox(height: 30),
              Row(
                children: [
                  _Stat(value: '${session?.durationMinutes ?? 0}', label: 'MINUTOS'),
                  _Stat(value: '${session?.exerciseCount ?? 0}', label: 'EXERCÍCIOS'),
                  _Stat(value: '${sets.length}', label: 'SÉRIES'),
                ],
              ),
              if (cardio != null) ...[
                const SizedBox(height: 20),
                Text(
                  '${cardio.type.label} · ${cardio.durationMinutes} min'
                  '${cardio.distanceKm != null ? ' · ${formatKg(cardio.distanceKm!)} km' : ''}',
                  style: AppText.bodyDim,
                ),
              ],
              const Spacer(),
              AppButton(
                label: 'Início',
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Ver histórico',
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  ref.read(tabProvider.notifier).state = 1;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }
}
