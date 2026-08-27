import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';

/// Botão redondo de passo (− / +) usado nos campos de peso e repetições.
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: C.surface,
          ),
          child: Icon(icon, size: 17, color: enabled ? C.textDim : C.textFaint),
        ),
      ),
    );
  }
}

/// Campo grande de peso (kg), com passo de 2,5 kg e digitação direta.
class WeightField extends StatelessWidget {
  const WeightField({
    super.key,
    required this.controller,
    this.step = 2.5,
    this.enabled = true,
  });

  final TextEditingController controller;
  final double step;
  final bool enabled;

  void _step(double delta) {
    final current = parseKg(controller.text) ?? 0;
    final next = ((current + delta) * 100).roundToDouble() / 100;
    if (next <= 0) {
      controller.text = '';
      return;
    }
    controller.text = formatKg(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          StepButton(icon: Icons.remove, enabled: enabled, onTap: () => _step(-step)),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: C.text,
              ),
              decoration: const InputDecoration.collapsed(isDense: true),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          StepButton(icon: Icons.add, enabled: enabled, onTap: () => _step(step)),
        ],
      ),
    );
  }
}

/// Campo grande de repetições, com passo de 1 e digitação direta.
class RepsField extends StatelessWidget {
  const RepsField({
    super.key,
    required this.controller,
    this.step = 1,
    this.enabled = true,
  });

  final TextEditingController controller;
  final int step;
  final bool enabled;

  void _step(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    controller.text = next >= 1 ? '$next' : '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          StepButton(icon: Icons.remove, enabled: enabled, onTap: () => _step(-step)),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: C.text,
              ),
              decoration: const InputDecoration.collapsed(isDense: true),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          StepButton(icon: Icons.add, enabled: enabled, onTap: () => _step(step)),
        ],
      ),
    );
  }
}

/// Linha de registro de série: [peso] [reps] [REGISTRAR].
class SetInputRow extends StatelessWidget {
  const SetInputRow({
    super.key,
    required this.weightController,
    required this.repsController,
    required this.onRegister,
    this.registerLabel = 'REGISTRAR',
    this.enabled = true,
  });

  final TextEditingController weightController;
  final TextEditingController repsController;
  final VoidCallback onRegister;
  final String registerLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 11, child: WeightField(controller: weightController, enabled: enabled)),
        const SizedBox(width: 10),
        Expanded(flex: 6, child: RepsField(controller: repsController, enabled: enabled)),
        const SizedBox(width: 10),
        _RegisterButton(label: registerLabel, onTap: enabled ? onRegister : null),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.accent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 92,
          height: 64,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: onTap != null ? C.accentInk : C.accentInk.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
