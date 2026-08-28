import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/cardio_record.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import 'summary_screen.dart';
import '../app_frame.dart';

final _uuid = const Uuid();

/// Etapa de cardio ao final do treino.
///
/// Registro simples: tipo, duração, distância (opcional) e
/// observação (opcional). "Pular cardio" também encerra o treino.
class CardioPage extends ConsumerStatefulWidget {
  const CardioPage({super.key});

  @override
  ConsumerState<CardioPage> createState() => _CardioPageState();
}

class _CardioPageState extends ConsumerState<CardioPage> {
  CardioType? _type;
  int _duration = 20;
  late final TextEditingController _distance;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _distance = TextEditingController();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _distance.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool withCardio}) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    CardioRecord? cardio;
    if (withCardio && _type != null) {
      final note = _note.text.trim();
      cardio = CardioRecord(
        id: _uuid.v4(),
        sessionId: workout.sessionId,
        type: _type!,
        durationMinutes: _duration,
        distanceKm: parseKm(_distance.text),
        note: note.isEmpty ? null : note,
      );
    }
    final sessionId = workout.sessionId;
    await ref.read(activeWorkoutProvider.notifier).finish(cardio: cardio);
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppFrame(child: SummaryScreen(sessionId: sessionId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CARDIO', style: AppText.displayL),
          const SizedBox(height: 4),
          const Text(
            'Finalização — registre o cardio ou pule',
            style: AppText.bodyDim,
          ),
          const SizedBox(height: 26),
          const Text('TIPO', style: AppText.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in CardioType.values)
                _TypeChip(
                  label: t.label,
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 26),
          const Text('DURAÇÃO', style: AppText.label),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundStep(
                icon: Icons.remove,
                onTap: () =>
                    setState(() => _duration = _duration > 1 ? _duration - 1 : 1),
              ),
              const SizedBox(width: 18),
              Text(
                '$_duration',
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              const Text('min', style: AppText.bodyDim),
              const SizedBox(width: 18),
              _RoundStep(icon: Icons.add, onTap: () => setState(() => _duration += 1)),
            ],
          ),
          const SizedBox(height: 26),
          const Text('DISTÂNCIA (OPCIONAL)', style: AppText.label),
          const SizedBox(height: 10),
          TextField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: '0,0',
              suffixText: 'km',
              suffixStyle: TextStyle(color: C.textFaint, fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          const Text('OBSERVAÇÃO (OPCIONAL)', style: AppText.label),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            style: const TextStyle(fontSize: 14.5),
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Ex.: ritmo forte, fadiga 6/10',
              counterText: '',
            ),
          ),
          const SizedBox(height: 34),
          AppButton(
            label: 'Finalizar treino',
            icon: Icons.flag_rounded,
            // Sem tipo selecionado, o registro de cardio é ignorado.
            onPressed: () => _finish(withCardio: true),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Pular cardio',
            variant: AppButtonVariant.ghost,
            onPressed: () => _finish(withCardio: false),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? C.accent : C.surface2,
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: C.stroke),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? C.accentInk : C.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surface2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: C.textDim),
        ),
      ),
    );
  }
}
