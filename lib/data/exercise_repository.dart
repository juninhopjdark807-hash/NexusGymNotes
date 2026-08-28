import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/exercise.dart';
import 'database.dart';

/// Persistência de exercícios.
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

  Future<List<Exercise>> getAll() async {
    final rows = await _db.query(
      'exercises',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<Exercise> create({
    required String name,
    required MuscleGroup muscleGroup,
  }) async {
    final now = DateTime.now();
    final exercise = Exercise(
      id: _uuid.v4(),
      name: name.trim(),
      muscleGroup: muscleGroup,
      createdAt: now,
    );
    await _db.insert(
      'exercises',
      _toRow(exercise),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _emit();
    return exercise;
  }

  Future<void> delete(String id) async {
    await _db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    _emit();
  }

  static Exercise _fromRow(Map<String, Object?> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      muscleGroup: MuscleGroup.fromName(row['muscle_group'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  static Map<String, Object?> _toRow(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'muscle_group': e.muscleGroup.name,
        'created_at': e.createdAt.millisecondsSinceEpoch,
      };
}
