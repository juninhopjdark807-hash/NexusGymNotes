import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/workout_template.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import 'exercise_picker_sheet.dart';

/// Criação/edição de um treino planejado.
///
/// - Nome do treino
/// - Adicionar/remover exercícios
/// - Reordenar por drag & drop
/// - Aquecimento/preparatória ativados por exercício
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, this.templateId});

  /// `null` = treino novo.
  final String? templateId;

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _nameController = TextEditingController();
  late List<WorkoutExercise> _items;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Lista mutável — const [] impede .add() ao criar exercícios.
    _items = <WorkoutExercise>[];
    if (widget.templateId == null) _loaded = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome ao treino'),
          backgroundColor: C.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final existing = widget.templateId != null
        ? ref.read(templateProvider(widget.templateId!)).valueOrNull
        : null;
    final now = DateTime.now();
    final template = WorkoutTemplate(
      id: existing?.id ?? ref.read(templateRepositoryProvider).newId(),
      name: name,
      exercises: List.generate(_items.length, (i) => _items[i].copyWith(position: i)),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      assignedBy: existing?.assignedBy,
    );
    await ref.read(templateRepositoryProvider).save(template);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Excluir treino?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Os treinos já realizados permanecem no histórico.',
          style: TextStyle(fontSize: 14, color: C.textDim, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'EXCLUIR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: C.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (widget.templateId != null) {
      await ref.read(templateRepositoryProvider).delete(widget.templateId!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPicker() async {
    final existingIds = _items.map((i) => i.exerciseId).toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ExercisePickerSheet(
        existingExerciseIds: existingIds,
        onAdded: (exerciseId) {
          setState(() {
            _items.add(WorkoutExercise(
              id: ref.read(templateRepositoryProvider).newId(),
              exerciseId: exerciseId,
            ));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateId = widget.templateId;
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final exerciseById = {for (final e in exercises) e.id: e};

    // Carrega o treino existente uma única vez (quando os dados chegam).
    if (templateId != null && !_loaded) {
      final t = ref.watch(templateProvider(templateId)).valueOrNull;
      if (t != null) {
        _nameController.text = t.name;
        _items = t.exercises
            .map(
              (e) => WorkoutExercise(
                id: e.id,
                exerciseId: e.exerciseId,
                position: e.position,
                warmupEnabled: e.warmupEnabled,
                prepEnabled: e.prepEnabled,
              ),
            )
            .toList();
        _loaded = true;
      }
    }
    final loading = templateId != null && !_loaded;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho: voltar + nome do treino
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'NOME DO TREINO',
                        hintStyle: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: C.textFaint,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: C.stroke),
            const SizedBox(height: 6),
            // Lista de exercícios (drag & drop)
            if (loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: C.textFaint),
                ),
              )
            else if (_items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Toque em "Adicionar exercício"\npara montar o treino',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      height: 1.5,
                      color: C.textFaint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView(
                  key: const ValueKey('template-reorder'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  // onReorderItem já ajusta newIndex (API pós v3.41).
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      _ItemRow(
                        key: ValueKey(_items[i].id),
                        index: i,
                        item: _items[i],
                        name: exerciseById[_items[i].exerciseId]?.name ?? 'Exercício',
                        muscle:
                            exerciseById[_items[i].exerciseId]?.muscleGroup.label ?? '',
                        onToggleWarmup: () => setState(
                              () => _items[i] = _items[i].copyWith(
                                warmupEnabled: !_items[i].warmupEnabled,
                              ),
                            ),
                        onTogglePrep: () => setState(
                              () => _items[i] = _items[i].copyWith(
                                prepEnabled: !_items[i].prepEnabled,
                              ),
                            ),
                        onRemove: () => setState(() => _items.removeAt(i)),
                      ),
                  ],
                ),
              ),
            // Ações
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  AppButton(
                    label: 'Adicionar exercício',
                    variant: AppButtonVariant.ghost,
                    icon: Icons.add_rounded,
                    height: 54,
                    onPressed: _openPicker,
                  ),
                  if (templateId != null)
                    TextButton(
                      onPressed: _confirmDelete,
                      child: const Text(
                        'EXCLUIR TREINO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: C.danger,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  AppButton(label: 'Salvar treino', onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha do exercício dentro do treino: arrastar, AQ/PR, remover.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.name,
    required this.muscle,
    required this.onToggleWarmup,
    required this.onTogglePrep,
    required this.onRemove,
  });

  final int index;
  final WorkoutExercise item;
  final String name;
  final String muscle;
  final VoidCallback onToggleWarmup;
  final VoidCallback onTogglePrep;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Handle manual (buildDefaultDragHandles: false).
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_indicator_rounded,
              color: C.textFaint,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  muscle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    color: C.textFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StageToggle(label: 'AQ', on: item.warmupEnabled, onTap: onToggleWarmup),
          const SizedBox(width: 8),
          _StageToggle(label: 'PR', on: item.prepEnabled, onTap: onTogglePrep),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: C.textFaint, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alternador compacto de etapa (AQ = aquecimento, PR = preparatória).
class _StageToggle extends StatelessWidget {
  const _StageToggle({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: on ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on ? C.accent : C.stroke),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: on ? C.accent : C.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}
