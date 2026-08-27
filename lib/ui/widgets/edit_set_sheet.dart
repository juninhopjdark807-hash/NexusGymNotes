import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/set_record.dart';
import 'app_button.dart';
import 'weight_reps_input.dart';

/// Abre a folha de edição de uma série registrada.
Future<void> showEditSetSheet(
  BuildContext context, {
  required SetRecord set,
  required Future<void> Function(double weightKg, int reps) onSave,
  required Future<void> Function() onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: C.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _EditSetSheet(
      set: set,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _EditSetSheet extends StatefulWidget {
  const _EditSetSheet({
    required this.set,
    required this.onSave,
    required this.onDelete,
  });

  final SetRecord set;
  final Future<void> Function(double weightKg, int reps) onSave;
  final Future<void> Function() onDelete;

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: formatKg(widget.set.weightKg));
    _reps = TextEditingController(text: '${widget.set.reps}');
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = parseKg(_weight.text);
    final reps = int.tryParse(_reps.text.trim());
    if (weight == null || reps == null || reps <= 0) return;
    await widget.onSave(weight, reps);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.onDelete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EDITAR SÉRIE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: C.textFaint,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PESO (KG)', style: AppText.label),
                    const SizedBox(height: 8),
                    WeightField(controller: _weight),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REPS', style: AppText.label),
                    const SizedBox(height: 8),
                    RepsField(controller: _reps),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppButton(label: 'Salvar', onPressed: _save),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _delete,
            child: const Text(
              'EXCLUIR SÉRIE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: C.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
