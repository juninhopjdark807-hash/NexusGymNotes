import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'exercise_seed.dart';

/// Conexão local (SQLite) do aplicativo.
///
/// Todos os dados permanecem no dispositivo; nenhuma requisição de
/// rede é feita. IDs são UUIDs e os timestamps absolutos, o que
/// prepara a estrutura para a futura sincronização com servidor.
///
/// O caminho do banco vem de [getDatabasesPath] (sqflite) — sem
/// `path_provider`, evitando o hook nativo `objective_c` no Windows
/// (quebra em caminhos de usuário com espaço, ex.: `C:\Users\Paulo Jr\`).
class AppDatabase {
  AppDatabase._(this._db);

  static AppDatabase? _instance;

  /// Instância única (criada em `main` antes de `runApp`).
  static AppDatabase get instance => _instance!;

  final Database _db;

  Database get db => _db;

  static const String _name = 'nexus_gym.db';

  /// v1–v3 = fases anteriores · v4 = perfil, avaliações, cardio expandido
  static const int _version = 4;

  static Future<AppDatabase> open() async {
    if (_instance != null) return _instance!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _name);
    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createV1Schema(database);
        await _upgradeExercisesToV2(database);
        await _upgradeToV3(database);
        await _upgradeToV4(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2 && newVersion >= 2) {
          await _upgradeExercisesToV2(database);
        }
        if (oldVersion < 3 && newVersion >= 3) {
          await _upgradeToV3(database);
        }
        if (oldVersion < 4 && newVersion >= 4) {
          await _upgradeToV4(database);
        }
      },
    );
    _instance = AppDatabase._(db);
    // Seed idempotente: roda em create e em app já existente.
    await ExerciseSeed.run(db);
    return _instance!;
  }

  static Future<void> _createV1Schema(Database database) async {
    final b = database.batch();
    b.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    b.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        assigned_by TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    b.execute('''
      CREATE TABLE template_exercises (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        warmup_enabled INTEGER NOT NULL DEFAULT 1,
        prep_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (template_id) REFERENCES templates(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
      )
    ''');
    b.execute(
      'CREATE INDEX idx_template_exercises_template ON template_exercises(template_id, position)',
    );
    b.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        template_id TEXT,
        template_name TEXT NOT NULL,
        assigned_by TEXT,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        exercise_count INTEGER NOT NULL DEFAULT 0,
        total_sets INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (template_id) REFERENCES templates(id) ON DELETE SET NULL
      )
    ''');
    b.execute('CREATE INDEX idx_sessions_started ON sessions(started_at)');
    b.execute('CREATE INDEX idx_sessions_template ON sessions(template_id)');
    b.execute('''
      CREATE TABLE sets (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        stage TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        position INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
      )
    ''');
    b.execute('CREATE INDEX idx_sets_session ON sets(session_id)');
    b.execute('CREATE INDEX idx_sets_exercise ON sets(exercise_id)');
    b.execute('''
      CREATE TABLE cardio (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        distance_km REAL,
        note TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
    await b.commit(noResult: true);
  }

  /// Adiciona colunas da Fase 2 sem apagar dados existentes.
  static Future<void> _upgradeExercisesToV2(Database database) async {
    final info = await database.rawQuery('PRAGMA table_info(exercises)');
    final cols = info.map((r) => r['name'] as String).toSet();

    if (!cols.contains('type')) {
      await database.execute(
        "ALTER TABLE exercises ADD COLUMN type TEXT NOT NULL DEFAULT 'musculacao'",
      );
    }
    if (!cols.contains('is_custom')) {
      // Existentes = personalizados do usuário (Fase 1).
      await database.execute(
        'ALTER TABLE exercises ADD COLUMN is_custom INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!cols.contains('active')) {
      await database.execute(
        'ALTER TABLE exercises ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
      );
    }
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_exercises_group ON exercises(muscle_group)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name COLLATE NOCASE)',
    );
  }

  /// Fase 3.1: notas por exercício dentro da sessão + página atual.
  static Future<void> _upgradeToV3(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS exercise_notes (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT,
        UNIQUE(session_id, exercise_id)
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_exercise_notes_session '
      'ON exercise_notes(session_id)',
    );

    final info = await database.rawQuery('PRAGMA table_info(sessions)');
    final cols = info.map((r) => r['name'] as String).toSet();
    if (!cols.contains('current_page')) {
      await database.execute(
        'ALTER TABLE sessions ADD COLUMN current_page INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  /// Fase 3.2+: perfil, avaliações corporais e campos extras de cardio.
  static Future<void> _upgradeToV4(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sex TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        current_weight_kg REAL NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS body_assessments (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        neck_cm REAL,
        waist_cm REAL,
        hip_cm REAL,
        bmi REAL,
        body_fat_percent REAL,
        fat_mass_kg REAL,
        lean_mass_kg REAL,
        bmr_kcal REAL,
        body_fat_method TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_body_assessments_date '
      'ON body_assessments(date DESC)',
    );

    final cardioInfo = await database.rawQuery('PRAGMA table_info(cardio)');
    final cardioCols = cardioInfo.map((r) => r['name'] as String).toSet();
    Future<void> addCol(String name, String def) async {
      if (!cardioCols.contains(name)) {
        await database.execute('ALTER TABLE cardio ADD COLUMN $name $def');
      }
    }

    await addCol('speed_kmh', 'REAL');
    await addCol('incline_percent', 'REAL');
    await addCol('floors', 'INTEGER');
    await addCol('calories_kcal', 'REAL');
  }

  Future<void> close() => _db.close();
}
