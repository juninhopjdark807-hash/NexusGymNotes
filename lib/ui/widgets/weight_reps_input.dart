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
    this.size = 34,
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
  // Anula padding do InputDecorationTheme global.
  constraints: BoxConstraints(minWidth: 0, minHeight: 0),
);

/// Campo grande de peso (kg).
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Row(
        children: [
          StepButton(
            icon: Icons.remove,
            enabled: enabled,
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
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
            onTap: () => _step(step),
          ),
        ],
      ),
    );
  }
}

/// Campo de repetições — preenche a largura do pai (sem overflow).
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.strokeSoft),
      ),
      child: Row(
        children: [
          StepButton(
            icon: Icons.remove,
            enabled: enabled,
            onTap: () => _step(-step),
          ),
          Expanded(
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
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
            onTap: () => _step(step),
          ),
        ],
      ),
    );
  }
}

/// Linha de registro: [peso] [reps] [OK].
///
/// Layout flexível — sem larguras fixas conflitantes que causam overflow.
class SetInputRow extends StatelessWidget {
  const SetInputRow({
    super.key,
    required this.weightController,
    required this.repsController,
    required this.onRegister,
    this.registerLabel = 'OK',
    this.enabled = true,
  });

  final TextEditingController weightController;
  final TextEditingController repsController;
  final VoidCallback onRegister;
  final String registerLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Em telas estreitas, reps e botão encolhem proporcionalmente.
        final maxW = constraints.maxWidth;
        final registerW = maxW < 340 ? 72.0 : 80.0;
        final repsW = maxW < 340 ? 112.0 : 120.0;
        final gap = maxW < 340 ? 6.0 : 8.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: WeightField(
                controller: weightController,
                enabled: enabled,
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: repsW,
              child: RepsField(
                controller: repsController,
                enabled: enabled,
              ),
            ),
            SizedBox(width: gap),
            _RegisterButton(
              label: registerLabel,
              width: registerW,
              onTap: enabled ? onRegister : null,
            ),
          ],
        );
      },
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    required this.label,
    required this.onTap,
    this.width = 80,
  });

  final String label;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? C.accent : C.accent.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: 64,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  height: 1.1,
                  color: onTap != null
                      ? C.accentInk
                      : C.accentInk.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
