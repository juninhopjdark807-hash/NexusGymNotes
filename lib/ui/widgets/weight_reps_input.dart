import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';

/// Botão redondo de passo (− / +).
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.surface,
              border: Border.all(color: C.strokeSoft),
            ),
            child: Icon(
              icon,
              size: size * 0.42,
              color: enabled ? C.textDim : C.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

const InputDecoration _fieldDecoration = InputDecoration(
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  filled: false,
  isCollapsed: true,
  isDense: true,
  contentPadding: EdgeInsets.zero,
  constraints: BoxConstraints(),
);

/// Campo grande de peso (kg) — hierarquia visual máxima no treino.
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
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Row(
        children: [
          StepButton(
            icon: Icons.remove,
            enabled: enabled,
            size: 40,
            onTap: () => _step(-step),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: C.text,
                height: 1.1,
              ),
              decoration: _fieldDecoration,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          StepButton(
            icon: Icons.add,
            enabled: enabled,
            size: 40,
            onTap: () => _step(step),
          ),
        ],
      ),
    );
  }
}

/// Campo de repetições com largura garantida.
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
      height: 72,
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepButton(
            icon: Icons.remove,
            enabled: enabled,
            size: 40,
            onTap: () => _step(-step),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: C.text,
                height: 1.1,
              ),
              decoration: _fieldDecoration,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          StepButton(
            icon: Icons.add,
            enabled: enabled,
            size: 40,
            onTap: () => _step(step),
          ),
        ],
      ),
    );
  }
}

/// Linha de registro: [peso] [reps] [REGISTRAR].
class SetInputRow extends StatelessWidget {
  const SetInputRow({
    super.key,
    required this.weightController,
    required this.repsController,
    required this.onRegister,
    this.registerLabel = 'CONCLUIR',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: WeightField(controller: weightController, enabled: enabled),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 132,
          child: RepsField(controller: repsController, enabled: enabled),
        ),
        const SizedBox(width: 8),
        _RegisterButton(
          label: registerLabel,
          onTap: enabled ? onRegister : null,
        ),
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
      color: onTap != null ? C.accent : C.accent.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 88,
          height: 72,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                height: 1.15,
                color: onTap != null
                    ? C.accentInk
                    : C.accentInk.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
