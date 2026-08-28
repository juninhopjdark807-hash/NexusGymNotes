import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/logic/exercise_name.dart';
import '../domain/models/exercise.dart';
import 'database.dart';

/// Resultado da tentativa de criar um exercício personalizado.
sealed class CreateExerciseResult {
  const CreateExerciseResult();
}

/// Exercício criado com sucesso.
class CreateExerciseOk extends CreateExerciseResult {
  const CreateExerciseOk(this.exercise);
  final Exercise exercise;
}

/// Já existe um exercício com nome equivalente.
class CreateExerciseDuplicate extends CreateExerciseResult {
  const CreateExerciseDuplicate(this.existing);
  final Exercise existing;
}

/// Persistência de exercícios (catálogo + personalizados).
///
/// Emite [changes] a cada mutação para que a interface reaja
/// (padrão "banco como fonte da verdade").
class ExerciseRepository {
  ExerciseRepository._(this._db);

  static final ExerciseRepository shared = ExerciseRepository._(
    AppDatabase.instance.db,
  );

  final Database _db;
  final _uuid = const Uuid();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Stream de "mudou algo". Cada assinante recebe um tick imediato
  /// ao assinar, para carregar o estado atual.
  Stream<void> get changes async* {
    yield null;
    yield* _changes.stream;
  }

  void _emit() => _changes.add(null);

  /// Exercícios ativos (biblioteca + personalizados), ordenados por nome.
  Future<List<Exercise>> getAll({bool includeInactive = false}) async {
    final rows = await _db.query(
      'exercises',
      where: includeInactive ? null : 'active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<Exercise?> getById(String id) async {
    final rows = await _db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Busca por nome equivalente (normalizado), entre ativos.
  Future<Exercise?> findByNormalizedName(String name) async {
    final all = await getAll(includeInactive: false);
    for (final e in all) {
      if (ExerciseName.isSame(e.name, name)) return e;
    }
    return null;
  }

  /// Cria exercício personalizado. Bloqueia duplicata por nome equivalente.
  Future<CreateExerciseResult> createCustom({
    required String name,
    required MuscleGroup muscleGroup,
    ExerciseType type = ExerciseType.musculacao,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Nome vazio');
    }
    final existing = await findByNormalizedName(trimmed);
    if (existing != null) {
      return CreateExerciseDuplicate(existing);
    }
    final now = DateTime.now();
    final exercise = Exercise(
      id: _uuid.v4(),
      name: trimmed,
      muscleGroup: muscleGroup,
      createdAt: now,
      type: type,
      isCustom: true,
      active: true,
    );
    await _db.insert(
      'exercises',
      _toRow(exercise),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    _emit();
    return CreateExerciseOk(exercise);
  }

  /// API legada (Fase 1): cria personalizado ou lança se duplicado.
  Future<Exercise> create({
    required String name,
    required MuscleGroup muscleGroup,
  }) async {
    final result = await createCustom(name: name, muscleGroup: muscleGroup);
    return switch (result) {
      CreateExerciseOk(:final exercise) => exercise,
      CreateExerciseDuplicate(:final existing) =>
        throw StateError('Exercício já existe: ${existing.name}'),
    };
  }

  /// Desativa sem apagar (histórico e FKs preservados).
  Future<void> deactivate(String id) async {
    await _db.update(
      'exercises',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _emit();
  }

  /// Soft-delete (não remove fisicamente — Fase 2).
  Future<void> delete(String id) => deactivate(id);

  static Exercise _fromRow(Map<String, Object?> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      muscleGroup: MuscleGroup.fromName(row['muscle_group'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      type: ExerciseType.fromName(row['type'] as String?),
      isCustom: (row['is_custom'] as int?) != 0,
      active: (row['active'] as int?) != 0,
    );
  }

  static Map<String, Object?> _toRow(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'muscle_group': e.muscleGroup.name,
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'type': e.type.name,
        'is_custom': e.isCustom ? 1 : 0,
        'active': e.active ? 1 : 0,
      };
}
