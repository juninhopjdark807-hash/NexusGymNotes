import 'package:sqflite/sqflite.dart';

import 'exercise_catalog.dart';

/// Insere a biblioteca inicial de forma **idempotente**.
///
/// - Não duplica: usa o id estável do catálogo (`ConflictAlgorithm.ignore`).
/// - Não apaga exercícios personalizados.
/// - Não apaga histórico.
/// - Pode rodar em todo `open()` com segurança.
class ExerciseSeed {
  ExerciseSeed._();

  static Future<void> run(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final item in ExerciseCatalog.all) {
      batch.insert(
        'exercises',
        {
          'id': item.id,
          'name': item.name,
          'muscle_group': item.muscleGroup.name,
          'created_at': now,
          'type': item.type.name,
          'is_custom': 0,
          'active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
