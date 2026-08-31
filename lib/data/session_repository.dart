import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/cardio_record.dart';
import '../domain/models/set_record.dart';
import '../domain/models/workout_session.dart';
import '../domain/models/workout_template.dart';
import 'database.dart';

/// Resumo de sessão para a listagem do histórico
/// (sessão + cardio, quando houver).
class SessionSummary {
  const SessionSummary({required this.session, required this.cardio});

  final WorkoutSession session;
  final CardioRecord? cardio;
}

/// Identificação de uma sessão que contém um exercício
/// (para o histórico de evolução do exercício).
class ExerciseSessionInfo {
  const ExerciseSessionInfo({
    required this.sessionId,
    required this.startedAt,
    required this.templateName,
  });

  final String sessionId;
  final DateTime startedAt;
  final String templateName;
}

/// Persistência de treinos executados: sessões, séries e cardio.
class SessionRepository {
  SessionRepository._(this._db);

  static final SessionRepository shared = SessionRepository._(
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

  // ---------------------------------------------------------------- sessões

  Future<WorkoutSession> startSession(WorkoutTemplate template) async {
    final now = DateTime.now();
    final session = WorkoutSession(
      id: _uuid.v4(),
      templateId: template.id,
      templateName: template.name,
      assignedBy: template.assignedBy,
      startedAt: now,
    );
    await _db.insert('sessions', _sessionToRow(session));
    _emit();
    return session;
  }

  Future<WorkoutSession?> getById(String id) async {
    final rows = await _db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  /// Sessão em andamento (se houver): a mais recente sem fim.
  Future<WorkoutSession?> getActiveSession() async {
    final rows = await _db.query(
      'sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  /// Sessões concluídas (histórico), da mais recente para a mais antiga.
  Future<List<SessionSummary>> getCompletedSummaries() async {
    final rows = await _db.rawQuery('''
      SELECT s.*,
             c.type AS cardio_type,
             c.duration_minutes AS cardio_minutes
      FROM sessions s
      LEFT JOIN cardio c ON c.session_id = s.id
      WHERE s.ended_at IS NOT NULL
      ORDER BY s.started_at DESC
    ''');
    return rows.map((r) {
      final cardio = r['cardio_type'] == null
          ? null
          : CardioRecord(
                id: '',
                sessionId: r['id'] as String,
                type: CardioType.fromName(r['cardio_type'] as String?),
                durationMinutes: r['cardio_minutes'] as int,
              );
      return SessionSummary(session: _sessionFromRow(r), cardio: cardio);
    }).toList(growable: false);
  }

  /// Encerra a sessão (salvando o cardio, quando informado).
  Future<void> finishSession(String sessionId, {CardioRecord? cardio}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      final counts = await txn.rawQuery(
        'SELECT COUNT(DISTINCT exercise_id) AS n, COUNT(*) AS m '
        'FROM sets WHERE session_id = ?',
        [sessionId],
      );
      final n = (counts.isEmpty ? 0 : (counts.first['n'] as int? ?? 0));
      final m = (counts.isEmpty ? 0 : (counts.first['m'] as int? ?? 0));
      await txn.update(
        'sessions',
        {
          'ended_at': now,
          'exercise_count': n,
          'total_sets': m,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      if (cardio != null) {
        await txn.insert(
          'cardio',
          {
            'id': cardio.id,
            'session_id': cardio.sessionId,
            'type': cardio.type.name,
            'duration_minutes': cardio.durationMinutes,
            'distance_km': cardio.distanceKm,
            'note': cardio.note,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _emit();
  }

  // ------------------------------------------------------------------ séries

  Future<List<SetRecord>> setsForSession(String sessionId) async {
    final rows = await _db.query(
      'sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC, position ASC',
    );
    return rows.map(_setFromRow).toList(growable: false);
  }

  Future<void> saveSet(SetRecord set) async {
    await _db.insert('sets', _setToRow(set), conflictAlgorithm: ConflictAlgorithm.replace);
    _emit();
  }

  Future<void> updateSet(SetRecord set) async {
    await _db.update('sets', _setToRow(set), where: 'id = ?', whereArgs: [set.id]);
    _emit();
  }

  Future<void> deleteSet(String id) async {
    await _db.delete('sets', where: 'id = ?', whereArgs: [id]);
    _emit();
  }

  /// Persiste a página atual da execução (para retomar depois).
  Future<void> updateCurrentPage(String sessionId, int page) async {
    await _db.update(
      'sessions',
      {'current_page': page},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    // Sem _emit: evita rebuild de listas a cada swipe.
  }

  // -------------------------------------------------------- notas do exercício

  /// Nota da execução de [exerciseId] nesta [sessionId] (null se vazia).
  Future<String?> noteForExercise(String sessionId, String exerciseId) async {
    final rows = await _db.query(
      'exercise_notes',
      where: 'session_id = ? AND exercise_id = ?',
      whereArgs: [sessionId, exerciseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final note = (rows.first['note'] as String?)?.trim() ?? '';
    return note.isEmpty ? null : note;
  }

  /// Salva ou atualiza a nota. Texto vazio remove o registro.
  Future<void> saveExerciseNote({
    required String sessionId,
    required String exerciseId,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      await _db.delete(
        'exercise_notes',
        where: 'session_id = ? AND exercise_id = ?',
        whereArgs: [sessionId, exerciseId],
      );
    } else {
      final existing = await _db.query(
        'exercise_notes',
        columns: ['id'],
        where: 'session_id = ? AND exercise_id = ?',
        whereArgs: [sessionId, exerciseId],
        limit: 1,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      if (existing.isEmpty) {
        await _db.insert('exercise_notes', {
          'id': _uuid.v4(),
          'session_id': sessionId,
          'exercise_id': exerciseId,
          'note': trimmed,
          'updated_at': now,
        });
      } else {
        await _db.update(
          'exercise_notes',
          {'note': trimmed, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    }
    _emit();
  }

  /// Séries de **trabalho** da execução anterior do exercício
  /// (excluindo a sessão atual, quando em andamento).
  ///
  /// Base do cálculo da referência do próximo treino.
  Future<List<SetRecord>> previousWorkSets(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    // Placeholders posicionais (?) evitam mapa ambíguo (Iterable + Map spread).
    final excludeClause = excludeSessionId != null
        ? 'AND s.session_id != ?'
        : '';
    final excludeSubClause = excludeSessionId != null
        ? 'AND se2.id != ?'
        : '';
    final args = <Object?>[
      exerciseId,
      if (excludeSessionId != null) excludeSessionId,
      exerciseId,
      if (excludeSessionId != null) excludeSessionId,
    ];
    final rows = await _db.rawQuery(
      '''
      SELECT s.*
      FROM sets s
      JOIN sessions se ON se.id = s.session_id
      WHERE s.exercise_id = ?
        AND s.stage = 'trabalho'
        $excludeClause
        AND se.started_at = (
          SELECT MAX(se2.started_at)
          FROM sessions se2
          JOIN sets s2 ON s2.session_id = se2.id
          WHERE s2.exercise_id = ?
            AND s2.stage = 'trabalho'
            $excludeSubClause
        )
      ORDER BY s.position ASC
      ''',
      args,
    );
    return rows.map(_setFromRow).toList(growable: false);
  }

  // ------------------------------------------------- histórico do exercício

  /// Todas as séries do exercício (em todas as sessões), mais antigas
  /// primeiro.
  Future<List<SetRecord>> setsForExercise(String exerciseId) async {
    final rows = await _db.query(
      'sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at ASC, position ASC',
    );
    return rows.map(_setFromRow).toList(growable: false);
  }

  /// Sessões que contêm o exercício, da mais recente para a mais antiga.
  Future<List<ExerciseSessionInfo>> sessionsForExercise(String exerciseId) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT se.id, se.started_at, se.template_name
      FROM sessions se
      JOIN sets s ON s.session_id = se.id
      WHERE s.exercise_id = ?
      ORDER BY se.started_at DESC
    ''', [exerciseId]);
    return rows
        .map((r) => ExerciseSessionInfo(
              sessionId: r['id'] as String,
              startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int),
              templateName: r['template_name'] as String,
            ))
        .toList(growable: false);
  }

  // ------------------------------------------------------------------ cardio

  Future<CardioRecord?> cardioForSession(String sessionId) async {
    final rows = await _db.query('cardio', where: 'session_id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;
    return _cardioFromRow(rows.first);
  }

  // --------------------------------------------------------------- mapeamento

  static WorkoutSession _sessionFromRow(Map<String, Object?> r) {
    return WorkoutSession(
      id: r['id'] as String,
      templateId: r['template_id'] as String?,
      templateName: r['template_name'] as String,
      assignedBy: r['assigned_by'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(r['started_at'] as int),
      endedAt: r['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r['ended_at'] as int),
      exerciseCount: (r['exercise_count'] as int?) ?? 0,
      totalSets: (r['total_sets'] as int?) ?? 0,
      currentPage: (r['current_page'] as int?) ?? 0,
    );
  }

  static Map<String, Object?> _sessionToRow(WorkoutSession s) => {
        'id': s.id,
        'template_id': s.templateId,
        'template_name': s.templateName,
        'assigned_by': s.assignedBy,
        'started_at': s.startedAt.millisecondsSinceEpoch,
        'ended_at': s.endedAt?.millisecondsSinceEpoch,
        'exercise_count': s.exerciseCount,
        'total_sets': s.totalSets,
        'current_page': s.currentPage,
      };

  static SetRecord _setFromRow(Map<String, Object?> r) {
    return SetRecord(
      id: r['id'] as String,
      sessionId: r['session_id'] as String,
      exerciseId: r['exercise_id'] as String,
      stage: SetStage.fromName(r['stage'] as String?),
      weightKg: (r['weight_kg'] as num).toDouble(),
      reps: r['reps'] as int,
      order: r['position'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }

  static Map<String, Object?> _setToRow(SetRecord s) => {
        'id': s.id,
        'session_id': s.sessionId,
        'exercise_id': s.exerciseId,
        'stage': s.stage.name,
        'weight_kg': s.weightKg,
        'reps': s.reps,
        'position': s.order,
        'created_at': s.createdAt.millisecondsSinceEpoch,
      };

  static CardioRecord _cardioFromRow(Map<String, Object?> r) {
    return CardioRecord(
      id: r['id'] as String,
      sessionId: r['session_id'] as String,
      type: CardioType.fromName(r['type'] as String?),
      durationMinutes: r['duration_minutes'] as int,
      distanceKm: (r['distance_km'] as num?)?.toDouble(),
      note: r['note'] as String?,
    );
  }
}
