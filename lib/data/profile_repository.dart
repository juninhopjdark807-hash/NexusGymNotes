import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/logic/body_composition.dart';
import '../domain/models/body_assessment.dart';
import '../domain/models/user_profile.dart';
import 'database.dart';

/// Persistência de perfil físico e avaliações corporais.
class ProfileRepository {
  ProfileRepository._(this._db);

  static final ProfileRepository shared = ProfileRepository._(
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

  static const String _profileId = 'default';

  Future<UserProfile?> getProfile() async {
    final rows = await _db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [_profileId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _profileFromRow(rows.first);
  }

  /// Salva perfil (upsert). Campos obrigatórios validados pelo chamador.
  Future<UserProfile> saveProfile({
    required String name,
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double currentWeightKg,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: _profileId,
      name: name.trim(),
      sex: sex,
      birthDate: birthDate,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      updatedAt: now,
    );
    await _db.insert(
      'user_profile',
      _profileToRow(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _emit();
    return profile;
  }

  Future<List<BodyAssessment>> getAssessments() async {
    final rows = await _db.query(
      'body_assessments',
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(_assessmentFromRow).toList(growable: false);
  }

  Future<BodyAssessment?> getLatestAssessment() async {
    final rows = await _db.query(
      'body_assessments',
      orderBy: 'date DESC, created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _assessmentFromRow(rows.first);
  }

  /// Cria avaliação com métricas calculadas a partir do perfil.
  Future<BodyAssessment> addAssessment({
    required DateTime date,
    required double weightKg,
    double? neckCm,
    double? waistCm,
    double? hipCm,
    UserProfile? profile,
  }) async {
    final p = profile ?? await getProfile();
    BodyMetrics? metrics;
    if (p != null) {
      metrics = BodyComposition.compute(
        sex: p.sex,
        birthDate: p.birthDate,
        heightCm: p.heightCm,
        weightKg: weightKg,
        neckCm: neckCm,
        waistCm: waistCm,
        hipCm: hipCm,
        asOf: date,
      );
    }

    final now = DateTime.now();
    final assessment = BodyAssessment(
      id: _uuid.v4(),
      date: DateTime(date.year, date.month, date.day),
      weightKg: weightKg,
      neckCm: neckCm,
      waistCm: waistCm,
      hipCm: hipCm,
      bmi: metrics?.bmi,
      bodyFatPercent: metrics?.bodyFatPercent,
      fatMassKg: metrics?.fatMassKg,
      leanMassKg: metrics?.leanMassKg,
      bmrKcal: metrics?.bmrKcal,
      bodyFatMethod: metrics?.bodyFatMethod,
      createdAt: now,
    );

    await _db.insert('body_assessments', _assessmentToRow(assessment));

    // Atualiza peso atual do perfil, se existir.
    if (p != null) {
      await _db.update(
        'user_profile',
        {
          'current_weight_kg': weightKg,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [_profileId],
      );
    }
    _emit();
    return assessment;
  }

  Future<void> updateAssessment(BodyAssessment a) async {
    final p = await getProfile();
    BodyMetrics? metrics;
    if (p != null) {
      metrics = BodyComposition.compute(
        sex: p.sex,
        birthDate: p.birthDate,
        heightCm: p.heightCm,
        weightKg: a.weightKg,
        neckCm: a.neckCm,
        waistCm: a.waistCm,
        hipCm: a.hipCm,
        asOf: a.date,
      );
    }
    final updated = BodyAssessment(
      id: a.id,
      date: a.date,
      weightKg: a.weightKg,
      neckCm: a.neckCm,
      waistCm: a.waistCm,
      hipCm: a.hipCm,
      bmi: metrics?.bmi ?? a.bmi,
      bodyFatPercent: metrics?.bodyFatPercent ?? a.bodyFatPercent,
      fatMassKg: metrics?.fatMassKg ?? a.fatMassKg,
      leanMassKg: metrics?.leanMassKg ?? a.leanMassKg,
      bmrKcal: metrics?.bmrKcal ?? a.bmrKcal,
      bodyFatMethod: metrics?.bodyFatMethod ?? a.bodyFatMethod,
      createdAt: a.createdAt,
    );
    await _db.update(
      'body_assessments',
      _assessmentToRow(updated),
      where: 'id = ?',
      whereArgs: [a.id],
    );
    _emit();
  }

  Future<void> deleteAssessment(String id) async {
    await _db.delete('body_assessments', where: 'id = ?', whereArgs: [id]);
    _emit();
  }

  static UserProfile _profileFromRow(Map<String, Object?> r) {
    return UserProfile(
      id: r['id'] as String,
      name: r['name'] as String,
      sex: Sex.fromName(r['sex'] as String?),
      birthDate: DateTime.fromMillisecondsSinceEpoch(r['birth_date'] as int),
      heightCm: (r['height_cm'] as num).toDouble(),
      currentWeightKg: (r['current_weight_kg'] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
    );
  }

  static Map<String, Object?> _profileToRow(UserProfile p) => {
        'id': p.id,
        'name': p.name,
        'sex': p.sex.name,
        'birth_date': DateTime(p.birthDate.year, p.birthDate.month, p.birthDate.day)
            .millisecondsSinceEpoch,
        'height_cm': p.heightCm,
        'current_weight_kg': p.currentWeightKg,
        'updated_at': p.updatedAt.millisecondsSinceEpoch,
      };

  static BodyAssessment _assessmentFromRow(Map<String, Object?> r) {
    return BodyAssessment(
      id: r['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
      weightKg: (r['weight_kg'] as num).toDouble(),
      neckCm: (r['neck_cm'] as num?)?.toDouble(),
      waistCm: (r['waist_cm'] as num?)?.toDouble(),
      hipCm: (r['hip_cm'] as num?)?.toDouble(),
      bmi: (r['bmi'] as num?)?.toDouble(),
      bodyFatPercent: (r['body_fat_percent'] as num?)?.toDouble(),
      fatMassKg: (r['fat_mass_kg'] as num?)?.toDouble(),
      leanMassKg: (r['lean_mass_kg'] as num?)?.toDouble(),
      bmrKcal: (r['bmr_kcal'] as num?)?.toDouble(),
      bodyFatMethod: r['body_fat_method'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }

  static Map<String, Object?> _assessmentToRow(BodyAssessment a) => {
        'id': a.id,
        'date': a.date.millisecondsSinceEpoch,
        'weight_kg': a.weightKg,
        'neck_cm': a.neckCm,
        'waist_cm': a.waistCm,
        'hip_cm': a.hipCm,
        'bmi': a.bmi,
        'body_fat_percent': a.bodyFatPercent,
        'fat_mass_kg': a.fatMassKg,
        'lean_mass_kg': a.leanMassKg,
        'bmr_kcal': a.bmrKcal,
        'body_fat_method': a.bodyFatMethod,
        'created_at': a.createdAt.millisecondsSinceEpoch,
      };
}
