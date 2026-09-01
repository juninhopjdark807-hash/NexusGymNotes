import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/set_record.dart';

/// Linha de série registrada.
///
/// - Tocar: editar peso/reps.
/// - Deslizar para a esquerda: excluir (com desfazer).
/// - [intervalLabel]: tempo desde a série anterior (null = não exibir).
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.onEdit,
    required this.onDelete,
    this.intervalLabel,
    this.setNumber,
  });

  final SetRecord set;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Texto do intervalo (ex.: "01:42" ou "—"). Null = oculto.
  final String? intervalLabel;

  /// Número da série na etapa (opcional).
  final int? setNumber;

  @override
  Widget build(BuildContext context) {
    final hasInterval = intervalLabel != null;
    return Dismissible(
      key: ValueKey('set-${set.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: C.dangerSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: C.danger,
          size: 20,
        ),
      ),
      child: Material(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          splashColor: C.accentSoft,
          child: Container(
            constraints: BoxConstraints(minHeight: hasInterval ? 56 : 50),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.strokeSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: C.accentSoft,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: C.accentSecondary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            if (setNumber != null)
                              TextSpan(
                                text: 'S$setNumber  ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: C.textFaint,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            TextSpan(
                              text: formatKg(set.weightKg),
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: C.text,
                              ),
                            ),
                            const TextSpan(
                              text: ' kg',
                              style:
                                  TextStyle(fontSize: 11, color: C.textFaint),
                            ),
                            TextSpan(
                              text: '  × ${set.reps}',
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: C.accentSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasInterval) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Intervalo: $intervalLabel',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: C.textFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.edit_rounded, color: C.textFaint, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
