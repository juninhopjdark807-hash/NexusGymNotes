import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';

/// Folha para adicionar exercícios ao treino:
/// busca nos existentes ou cria um novo manualmente.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.existingExerciseIds,
    required this.onAdded,
  });

  /// Exercícios já presentes no treino (marcados como adicionados).
  final Set<String> existingExerciseIds;

  /// Chamado com o id do exercício ao adicionar/criar.
  final ValueChanged<String> onAdded;

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  final _newNameController = TextEditingController();
  MuscleGroup _group = MuscleGroup.peito;
  String _search = '';
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // Reconstroi ao digitar o nome — habilita "Criar e adicionar".
    _newNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newNameController.removeListener(_onNameChanged);
    _searchController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final exercise = await ref
          .read(exerciseRepositoryProvider)
          .create(name: name, muscleGroup: _group);
      if (!mounted) return;
      widget.onAdded(exercise.id);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível criar o exercício'),
          backgroundColor: C.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final filtered = _search.isEmpty
        ? exercises
        : exercises
              .where((e) =>
                  e.name.toLowerCase().contains(_search.toLowerCase()))
              .toList(growable: false);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final canCreate = _newNameController.text.trim().isNotEmpty && !_creating;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'EXERCÍCIOS',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, color: C.textDim, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Buscar exercício',
              prefixIcon: Icon(Icons.search_rounded, color: C.textFaint, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Nenhum exercício encontrado', style: AppText.bodyFaint),
                  )
                : ListView(
                    children: [
                      for (final ex in filtered)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: const StadiumBorder(),
                          title: Text(
                            ex.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            ex.muscleGroup.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              color: C.textFaint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: widget.existingExerciseIds.contains(ex.id)
                              ? const Icon(Icons.check_rounded, color: C.accent, size: 20)
                              : const Icon(Icons.add_rounded, color: C.textDim, size: 20),
                          onTap: widget.existingExerciseIds.contains(ex.id)
                              ? null
                              : () {
                                  widget.onAdded(ex.id);
                                  Navigator.of(context).pop();
                                },
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: C.stroke),
          const SizedBox(height: 16),
          const Text('NOVO EXERCÍCIO', style: AppText.label),
          const SizedBox(height: 10),
          TextField(
            controller: _newNameController,
            style: const TextStyle(fontSize: 14.5),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (canCreate) _createAndAdd();
            },
            decoration: const InputDecoration(hintText: 'Nome (ex.: Supino reto)'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in MuscleGroup.values)
                _GroupChip(
                  label: g.label,
                  selected: _group == g,
                  onTap: () => setState(() => _group = g),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: _creating ? 'Criando…' : 'Criar e adicionar',
            height: 54,
            onPressed: canCreate ? _createAndAdd : null,
          ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? C.accent : C.stroke),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? C.accent : C.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
