import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/set_record.dart';

/// Linha de série registrada.
///
/// - Tocar: editar peso/reps.
/// - Deslizar para a esquerda: excluir (com desfazer).
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.onEdit,
    required this.onDelete,
  });

  final SetRecord set;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
            height: 56,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.strokeSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: C.accentSoft,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: C.accentSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatKg(set.weightKg),
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: C.text,
                          ),
                        ),
                        const TextSpan(
                          text: ' kg',
                          style: TextStyle(fontSize: 12, color: C.textFaint),
                        ),
                        TextSpan(
                          text: '  × ${set.reps}',
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: C.accentSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.edit_rounded, color: C.textFaint, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
