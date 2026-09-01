import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/logic/body_composition.dart';
import '../../domain/models/user_profile.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/app_button.dart';
import '../widgets/nexus_card.dart';
import 'body_assessment_screen.dart';
import 'body_evolution_screen.dart';

/// Perfil físico + atalhos para avaliações e evolução.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();

  Sex _sex = Sex.masculino;
  DateTime? _birthDate;
  bool _measuresExpanded = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _neck.dispose();
    _waist.dispose();
    _hip.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile? p) {
    if (_loaded) return;
    if (p == null) {
      // Marca como carregado mesmo sem perfil (evita loop).
      _loaded = true;
      return;
    }
    _name.text = p.name;
    _sex = p.sex;
    _birthDate = p.birthDate;
    _height.text = formatKg(p.heightCm);
    _weight.text = formatKg(p.currentWeightKg);
    _loaded = true;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
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
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final height = parseKg(_height.text);
    final weight = parseKg(_weight.text);
    if (name.isEmpty ||
        _birthDate == null ||
        height == null ||
        height <= 0 ||
        weight == null ||
        weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, sexo, nascimento, altura e peso'),
          backgroundColor: C.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.saveProfile(
        name: name,
        sex: _sex,
        birthDate: _birthDate!,
        heightCm: height,
        currentWeightKg: weight,
      );

      // Medidas opcionais → cria avaliação se houver alguma.
      final neck = parseKg(_neck.text);
      final waist = parseKg(_waist.text);
      final hip = parseKg(_hip.text);
      if (neck != null || waist != null || hip != null) {
        await repo.addAssessment(
          date: DateTime.now(),
          weightKg: weight,
          neckCm: neck,
          waistCm: waist,
          hipCm: hip,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo'),
            backgroundColor: C.surface2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (!_loaded && !profileAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hydrate(profile));
      });
    }
    final assessments =
        ref.watch(bodyAssessmentsProvider).valueOrNull ?? const [];

    BodyMetrics? live;
    final h = parseKg(_height.text);
    final w = parseKg(_weight.text);
    if (_birthDate != null && h != null && w != null && h > 0 && w > 0) {
      live = BodyComposition.compute(
        sex: _sex,
        birthDate: _birthDate!,
        heightCm: h,
        weightKg: w,
        neckCm: parseKg(_neck.text),
        waistCm: parseKg(_waist.text),
        hipCm: parseKg(_hip.text),
      );
    }

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
                  const Text('PERFIL FÍSICO', style: AppText.displayM),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  const Text('DADOS OBRIGATÓRIOS', style: AppText.label),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  const Text('SEXO', style: AppText.label),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final s in Sex.values) ...[
                        Expanded(
                          child: _SexChip(
                            label: s.label,
                            selected: _sex == s,
                            onTap: () => setState(() => _sex = s),
                          ),
                        ),
                        if (s != Sex.values.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('DATA DE NASCIMENTO', style: AppText.label),
                  const SizedBox(height: 8),
                  Material(
                    color: C.surface2,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Selecionar data'
                              : formatDate(_birthDate!),
                          style: TextStyle(
                            color: _birthDate == null ? C.textFaint : C.text,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _height,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Altura',
                            suffixText: 'cm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Peso',
                            suffixText: 'kg',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(
                        () => _measuresExpanded = !_measuresExpanded,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'MEDIDAS CORPORAIS',
                                style: AppText.label,
                              ),
                            ),
                            Text(
                              'opcional',
                              style: AppText.bodyFaint,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _measuresExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: C.textFaint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_measuresExpanded) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _neck,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Pescoço',
                        suffixText: 'cm',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _waist,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cintura',
                        suffixText: 'cm',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _hip,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Quadril',
                        suffixText: 'cm',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  if (live != null) ...[
                    const SizedBox(height: 18),
                    const Text('ESTIMATIVAS', style: AppText.label),
                    const SizedBox(height: 10),
                    NexusCard(
                      child: Column(
                        children: [
                          _MetricRow(
                            label: 'Idade',
                            value: '${live.ageYears} anos',
                          ),
                          _MetricRow(
                            label: 'IMC',
                            value: live.bmi.toStringAsFixed(1),
                          ),
                          if (live.bodyFatPercent != null)
                            _MetricRow(
                              label: live.bodyFatLabel,
                              value:
                                  '${live.bodyFatPercent!.toStringAsFixed(1)} %',
                            ),
                          if (live.fatMassKg != null)
                            _MetricRow(
                              label: 'Massa gorda est.',
                              value:
                                  '${formatKg(live.fatMassKg!)} kg',
                            ),
                          if (live.leanMassKg != null)
                            _MetricRow(
                              label: 'Massa magra est.',
                              value:
                                  '${formatKg(live.leanMassKg!)} kg',
                            ),
                          _MetricRow(
                            label: 'Metabolismo basal est.',
                            value: '${live.bmrKcal.round()} kcal',
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AppButton(
                    label: _saving ? 'Salvando…' : 'Salvar perfil',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Nova avaliação corporal',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppFrame(
                          child: BodyAssessmentScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Evolução corporal',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppFrame(
                          child: BodyEvolutionScreen(),
                        ),
                      ),
                    ),
                  ),
                  if (assessments.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'HISTÓRICO (${assessments.length})',
                      style: AppText.label,
                    ),
                    const SizedBox(height: 10),
                    for (final a in assessments.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NexusCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatDate(a.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatKg(a.weightKg)} kg'
                                      '${a.bodyFatPercent != null ? ' · BF ${a.bodyFatPercent!.toStringAsFixed(1)}%' : ''}',
                                      style: AppText.bodyFaint,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  const _SexChip({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? C.accent : C.stroke,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? C.accentSecondary : C.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.bodyDim)),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
