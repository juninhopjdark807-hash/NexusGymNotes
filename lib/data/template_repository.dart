import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/workout_template.dart';
import 'database.dart';

/// Persistência de treinos planejados (templates) e sua ordem de exercícios.
class TemplateRepository {
  TemplateRepository._(this._db);

  static final TemplateRepository shared = TemplateRepository._(
    AppDatabase.instance.db,
  );

  final Database _db;
  final _uuid = const Uuid();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes async* {
    yield null;
    yield* _changes.stream;
  }

  void _emit() => _changes.add(null);

  String newId() => _uuid.v4();

  Future<List<WorkoutTemplate>> getAll() async {
    final tRows = await _db.query('templates', orderBy: 'updated_at DESC');
    final eRows = await _db.query(
      'template_exercises',
      orderBy: 'position ASC',
    );
    final byTemplate = <String, List<WorkoutExercise>>{};
    for (final r in eRows) {
      final list = byTemplate.putIfAbsent(r['template_id'] as String, () => []);
      list.add(WorkoutExercise(
        id: r['id'] as String,
        exerciseId: r['exercise_id'] as String,
        position: r['position'] as int,
        warmupEnabled: (r['warmup_enabled'] as int) == 1,
        prepEnabled: (r['prep_enabled'] as int) == 1,
      ));
    }
    return tRows
        .map((r) => WorkoutTemplate(
              id: r['id'] as String,
              name: r['name'] as String,
              exercises: byTemplate[r['id'] as String] ?? const [],
              assignedBy: r['assigned_by'] as String?,
              createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
            ))
        .toList(growable: false);
  }

  Future<WorkoutTemplate?> getById(String id) async {
    final rows = await _db.query('templates', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final eRows = await _db.query(
      'template_exercises',
      where: 'template_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    final items = eRows
        .map((r) => WorkoutExercise(
              id: r['id'] as String,
              exerciseId: r['exercise_id'] as String,
              position: r['position'] as int,
              warmupEnabled: (r['warmup_enabled'] as int) == 1,
              prepEnabled: (r['prep_enabled'] as int) == 1,
            ))
        .toList(growable: false);
    final r = rows.first;
    return WorkoutTemplate(
      id: r['id'] as String,
      name: r['name'] as String,
      exercises: items,
      assignedBy: r['assigned_by'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    );
  }

  /// Cria ou atualiza o treino (substituindo a lista de exercícios).
  Future<void> save(WorkoutTemplate template) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'templates',
        {
          'id': template.id,
          'name': template.name,
          'assigned_by': template.assignedBy,
          'created_at': template.createdAt.millisecondsSinceEpoch,
          'updated_at': template.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [template.id],
      );
      for (final item in template.exercises) {
        await txn.insert('template_exercises', {
          'id': item.id,
          'template_id': template.id,
          'exercise_id': item.exerciseId,
          'position': item.position,
          'warmup_enabled': item.warmupEnabled ? 1 : 0,
          'prep_enabled': item.prepEnabled ? 1 : 0,
        });
      }
    });
    _emit();
  }

  Future<void> delete(String id) async {
    await _db.delete('templates', where: 'id = ?', whereArgs: [id]);
    _emit();
  }
}
