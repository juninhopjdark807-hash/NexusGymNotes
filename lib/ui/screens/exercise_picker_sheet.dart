import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/exercise_repository.dart';
import '../../domain/logic/exercise_name.dart';
import '../../domain/models/exercise.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import '../widgets/muscle_icon.dart';

/// Folha para adicionar exercícios ao treino (Fase 2):
/// biblioteca agrupada por grupo muscular + busca + criar personalizado.
///
/// Layout à prova de teclado: altura máxima limitada + lista flexível.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.existingExerciseIds,
    required this.onAdded,
    this.onRemoved,
  });

  /// Exercícios já presentes no treino (marcados como adicionados).
  final Set<String> existingExerciseIds;

  /// Chamado com o id do exercício ao adicionar/criar.
  final ValueChanged<String> onAdded;

  /// Chamado ao DESELECIONAR (segundo toque no card) — remove do treino.
  final ValueChanged<String>? onRemoved;

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  final _newNameController = TextEditingController();
  final _newNameFocus = FocusNode();
  MuscleGroup _group = MuscleGroup.peito;
  String _search = '';
  bool _creating = false;
  bool _showCreateForm = false;

  /// Exercícios já presentes + adicionados nesta sessão da folha.
  /// Mantém a seleção múltipla sem fechar a tela: cada toque adiciona e o
  /// "Mais" vira um check verde; tocar de novo deseleciona (remove do treino);
  /// só o botão "Concluir" fecha.
  late Set<String> _selected;

  /// Apenas os adicionados DURANTE esta sessão (para saber se o toque
  /// seguinte pode desfazer a adição via onRemoved).
  late Set<String> _sessionAdded;

  /// Duplicata detectada — oferece selecionar o existente.
  Exercise? _duplicate;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.existingExerciseIds};
    _sessionAdded = <String>{};
    _newNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_duplicate != null) {
      _duplicate = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newNameController.removeListener(_onNameChanged);
    _searchController.dispose();
    _newNameController.dispose();
    _newNameFocus.dispose();
    super.dispose();
  }

  List<Exercise> _filter(List<Exercise> all) {
    if (_search.trim().isEmpty) return all;
    return all
        .where((e) => ExerciseName.matches(e.name, _search))
        .toList(growable: false);
  }

  /// Agrupa na ordem da biblioteca; omite grupos vazios.
  List<(MuscleGroup, List<Exercise>)> _groupByMuscle(List<Exercise> list) {
    final map = <MuscleGroup, List<Exercise>>{};
    for (final e in list) {
      map.putIfAbsent(e.muscleGroup, () => []).add(e);
    }
    final result = <(MuscleGroup, List<Exercise>)>[];
    for (final g in MuscleGroup.libraryOrder) {
      final items = map[g];
      if (items == null || items.isEmpty) continue;
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      result.add((g, items));
    }
    return result;
  }

  /// Seleciona/desseleciona: 1º toque adiciona (check verde, folha aberta);
  /// 2º toque remove do treino e volta o "Mais". Sempre sem fechar a folha.
  void _toggle(Exercise exercise) {
    final id = exercise.id;
    if (!_selected.contains(id)) {
      setState(() {
        _selected.add(id);
        _sessionAdded.add(id);
      });
      widget.onAdded(id);
      return;
    }
    setState(() {
      _sessionAdded.remove(id);
      _selected.remove(id);
    });
    widget.onRemoved?.call(id);
  }

  Future<void> _createAndAdd() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() {
      _creating = true;
      _duplicate = null;
    });
    try {
      final result = await ref.read(exerciseRepositoryProvider).createCustom(
            name: name,
            muscleGroup: _group,
          );
      if (!mounted) return;
      switch (result) {
        case CreateExerciseOk(:final exercise):
          // Cria e mantém na tela: item entra na lista com check verde.
          setState(() {
            _selected.add(exercise.id);
            _sessionAdded.add(exercise.id);
            _creating = false;
            _showCreateForm = false;
          });
          _newNameController.clear();
          widget.onAdded(exercise.id);
        case CreateExerciseDuplicate(:final existing):
          setState(() {
            _creating = false;
            _duplicate = existing;
          });
      }
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
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    final filtered = _filter(exercises);
    final groups = _groupByMuscle(filtered);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final canCreate =
        _newNameController.text.trim().isNotEmpty && !_creating;
    final maxHeight = (media.size.height - keyboard) * 0.92;
    final searching = _search.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: C.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ADICIONAR EXERCÍCIO',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 17,
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
                          child: Icon(
                            Icons.close_rounded,
                            color: C.textDim,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() {
                    _search = v;
                    if (v.trim().isNotEmpty) _showCreateForm = false;
                  }),
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Buscar exercício…',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: C.textFaint,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptySearch(
                          query: _search,
                          onCreate: () => setState(() {
                            _showCreateForm = true;
                            _newNameController.text = _search.trim();
                            _newNameFocus.requestFocus();
                          }),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _listItemCount(groups),
                          itemBuilder: (context, index) {
                            return _buildListItem(groups, index);
                          },
                        ),
                ),
                if (!_showCreateForm && !searching) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Criar exercício',
                    variant: AppButtonVariant.ghost,
                    icon: Icons.add_rounded,
                    height: 50,
                    onPressed: () => setState(() {
                      _showCreateForm = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _newNameFocus.requestFocus();
                      });
                    }),
                  ),
                ],
                if (_showCreateForm || (searching && filtered.isEmpty)) ...[
                  const SizedBox(height: 10),
                  Container(height: 1, color: C.stroke),
                  const SizedBox(height: 12),
                  const Text('CRIAR EXERCÍCIO', style: AppText.label),
                  const SizedBox(height: 10),
                  if (_duplicate != null)
                    _DuplicateBanner(
                      existing: _duplicate!,
                      alreadyInWorkout: _selected.contains(_duplicate!.id),
                      onSelect: () => _toggle(_duplicate!),
                    ),
                  TextField(
                    controller: _newNameController,
                    focusNode: _newNameFocus,
                    style: const TextStyle(fontSize: 14.5),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (canCreate) _createAndAdd();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Nome (ex.: Supino reto)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 76,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final g in MuscleGroup.libraryOrder)
                            if (g != MuscleGroup.outros &&
                                g != MuscleGroup.pernas &&
                                g != MuscleGroup.trapezio &&
                                g != MuscleGroup.pescoco)
                              _GroupChip(
                                label: g.label,
                                selected: _group == g,
                                onTap: () => setState(() => _group = g),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: _creating ? 'Criando…' : 'Criar e adicionar',
                    height: 54,
                    onPressed: canCreate ? _createAndAdd : null,
                  ),
                ],
                // Concluir: única forma de sair após adicionar vários itens.
                const SizedBox(height: 12),
                AppButton(
                  label: 'Concluir',
                  icon: Icons.check_rounded,
                  height: 54,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _listItemCount(List<(MuscleGroup, List<Exercise>)> groups) {
    var n = 0;
    for (final g in groups) {
      n += 1 + g.$2.length; // header + items
    }
    return n;
  }

  Widget _buildListItem(
    List<(MuscleGroup, List<Exercise>)> groups,
    int index,
  ) {
    var i = 0;
    for (final (group, items) in groups) {
      if (i == index) {
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 4 : 16, bottom: 8),
          child: Row(
            children: [
              MuscleBadge(group: group, size: 28, active: true),
              const SizedBox(width: 10),
              Text(
                group.label.toUpperCase(),
                style: AppText.labelAccent,
              ),
            ],
          ),
        );
      }
      i++;
      for (final ex in items) {
        if (i == index) {
          final already = _selected.contains(ex.id);
          return _ExerciseTile(
            exercise: ex,
            alreadyAdded: already,
            // Sempre clicável: 1º toque seleciona, 2º deseleciona.
            onTap: () => _toggle(ex),
          );
        }
        i++;
      }
    }
    return const SizedBox.shrink();
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query, required this.onCreate});

  final String query;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: C.textFaint, size: 28),
            const SizedBox(height: 12),
            Text(
              query.trim().isEmpty
                  ? 'Nenhum exercício na biblioteca'
                  : 'Nenhum resultado para “${query.trim()}”',
              style: AppText.bodyDim,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Não encontrou? Crie um exercício personalizado.',
              style: AppText.bodyFaint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCreate,
              child: const Text(
                'CRIAR EXERCÍCIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: C.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuplicateBanner extends StatelessWidget {
  const _DuplicateBanner({
    required this.existing,
    required this.alreadyInWorkout,
    required this.onSelect,
  });

  final Exercise existing;
  final bool alreadyInWorkout;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esse exercício já existe na biblioteca.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: C.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            existing.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: C.text,
            ),
          ),
          const SizedBox(height: 10),
          if (!alreadyInWorkout)
            AppButton(
              label: 'Usar existente',
              height: 46,
              onPressed: onSelect,
            )
          else
            const Text(
              'Já está neste treino.',
              style: AppText.bodyFaint,
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.alreadyAdded,
    required this.onTap,
  });

  final Exercise exercise;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: C.accentSoft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: alreadyAdded
                ? C.successSoft.withValues(alpha: 0.35)
                : C.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alreadyAdded
                  ? C.success.withValues(alpha: 0.35)
                  : C.strokeSoft,
            ),
          ),
          child: Row(
            children: [
              MuscleIcon(
                group: exercise.muscleGroup,
                size: 16,
                color: alreadyAdded ? C.success : C.textFaint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: alreadyAdded ? C.textDim : C.text,
                      ),
                    ),
                    if (exercise.isCustom) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'PERSONALIZADO',
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: C.textFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // "Mais" -> check verde ao adicionar (fica na tela até Concluir).
              Icon(
                alreadyAdded
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: alreadyAdded ? C.success : C.textDim,
                size: 20,
              ),
            ],
          ),
        ),
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
