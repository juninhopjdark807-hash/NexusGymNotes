import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';

/// Nova avaliação corporal datada.
class BodyAssessmentScreen extends ConsumerStatefulWidget {
  const BodyAssessmentScreen({super.key});

  @override
  ConsumerState<BodyAssessmentScreen> createState() =>
      _BodyAssessmentScreenState();
}

class _BodyAssessmentScreenState extends ConsumerState<BodyAssessmentScreen> {
  final _weight = TextEditingController();
  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(userProfileProvider).valueOrNull;
      if (p != null && mounted && _weight.text.isEmpty) {
        setState(() => _weight.text = formatKg(p.currentWeightKg));
      }
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _neck.dispose();
    _waist.dispose();
    _hip.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: C.accent,
            onPrimary: C.accentInk,
            surface: C.surface,
            onSurface: C.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final w = parseKg(_weight.text);
    if (w == null || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o peso'),
          backgroundColor: C.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).addAssessment(
            date: _date,
            weightKg: w,
            neckCm: parseKg(_neck.text),
            waistCm: parseKg(_waist.text),
            hipCm: parseKg(_hip.text),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  const Text('NOVA AVALIAÇÃO', style: AppText.displayM),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  const Text('DATA', style: AppText.label),
                  const SizedBox(height: 8),
                  Material(
                    color: C.surface2,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(formatDate(_date), style: AppText.body),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Peso',
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _neck,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Pescoço (opcional)',
                      suffixText: 'cm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _waist,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Cintura (opcional)',
                      suffixText: 'cm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hip,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Quadril (opcional)',
                      suffixText: 'cm',
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _saving ? 'Salvando…' : 'Salvar avaliação',
                    onPressed: _saving ? null : _save,
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
