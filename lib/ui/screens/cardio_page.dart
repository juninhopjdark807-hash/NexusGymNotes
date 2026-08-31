import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/logic/cardio_calories.dart';
import '../../domain/models/cardio_record.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
import 'summary_screen.dart';

final _uuid = const Uuid();

/// Etapa de cardio ao final do treino (Fase 3.6–3.9).
///
/// Dropdown de modalidade + campos dinâmicos + calorias estimadas.
class CardioPage extends ConsumerStatefulWidget {
  const CardioPage({super.key});

  @override
  ConsumerState<CardioPage> createState() => _CardioPageState();
}

class _CardioPageState extends ConsumerState<CardioPage> {
  CardioType _type = CardioType.esteira;
  int _duration = 20;
  late final TextEditingController _distance;
  late final TextEditingController _speed;
  late final TextEditingController _incline;
  late final TextEditingController _floors;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _distance = TextEditingController();
    _speed = TextEditingController();
    _incline = TextEditingController();
    _floors = TextEditingController();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _distance.dispose();
    _speed.dispose();
    _incline.dispose();
    _floors.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _estimatedKcal {
    final profile = ref.read(userProfileProvider).valueOrNull;
    return CardioCalories.estimate(
      type: _type,
      durationMinutes: _duration,
      weightKg: profile?.currentWeightKg,
      ageYears: profile?.ageYears,
      sex: profile?.sex,
      distanceKm: parseKm(_distance.text),
      speedKmh: parseKg(_speed.text),
      inclinePercent: parseKg(_incline.text),
      floors: int.tryParse(_floors.text.trim()),
    );
  }

  Future<void> _finish({required bool withCardio}) async {
    final workout = ref.read(activeWorkoutProvider);
    if (workout == null) return;
    CardioRecord? cardio;
    if (withCardio) {
      final note = _note.text.trim();
      final kcal = _estimatedKcal;
      cardio = CardioRecord(
        id: _uuid.v4(),
        sessionId: workout.sessionId,
        type: _type,
        durationMinutes: _duration,
        distanceKm: _type.showsDistance ? parseKm(_distance.text) : null,
        speedKmh: _type.showsSpeed ? parseKg(_speed.text) : null,
        inclinePercent: _type.showsIncline ? parseKg(_incline.text) : null,
        floors: _type.showsFloors ? int.tryParse(_floors.text.trim()) : null,
        caloriesKcal: kcal,
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
    // Reage a mudanças do perfil para calorias.
    ref.watch(userProfileProvider);
    final kcal = _estimatedKcal;

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
          const SizedBox(height: 22),
          const Text('TIPO DE CARDIO', style: AppText.label),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: C.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CardioType>(
                value: _type,
                isExpanded: true,
                dropdownColor: C.surface,
                style: const TextStyle(
                  color: C.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  for (final t in CardioType.selectable)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (t) {
                  if (t != null) setState(() => _type = t);
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('DURAÇÃO', style: AppText.label),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundStep(
                icon: Icons.remove,
                onTap: () => setState(
                  () => _duration = _duration > 1 ? _duration - 1 : 1,
                ),
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
              _RoundStep(
                icon: Icons.add,
                onTap: () => setState(() => _duration += 1),
              ),
            ],
          ),
          if (_type.showsDistance) ...[
            const SizedBox(height: 22),
            const Text('DISTÂNCIA', style: AppText.label),
            const SizedBox(height: 10),
            TextField(
              controller: _distance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_type.showsSpeed) ...[
            const SizedBox(height: 16),
            const Text('VELOCIDADE', style: AppText.label),
            const SizedBox(height: 10),
            TextField(
              controller: _speed,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0,0',
                suffixText: 'km/h',
                suffixStyle: TextStyle(color: C.textFaint, fontSize: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_type.showsIncline) ...[
            const SizedBox(height: 16),
            const Text('INCLINAÇÃO', style: AppText.label),
            const SizedBox(height: 10),
            TextField(
              controller: _incline,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '%',
                suffixStyle: TextStyle(color: C.textFaint, fontSize: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_type.showsFloors) ...[
            const SizedBox(height: 16),
            const Text('ANDARES', style: AppText.label),
            const SizedBox(height: 10),
            TextField(
              controller: _floors,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
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
          if (kcal != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.accentSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CALORIAS ESTIMADAS', style: AppText.labelAccent),
                  const SizedBox(height: 6),
                  Text(
                    '${kcal.round()} kcal',
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: C.accentSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          AppButton(
            label: 'Finalizar treino',
            icon: Icons.flag_rounded,
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
