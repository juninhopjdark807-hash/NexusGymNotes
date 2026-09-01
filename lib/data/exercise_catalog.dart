import '../domain/models/exercise.dart';

/// Entrada do catálogo inicial (seed).
class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.type = ExerciseType.musculacao,
  });

  /// Id estável e idempotente (ex.: `lib_peito_supino_reto`).
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final ExerciseType type;
}

/// Biblioteca inicial da Fase 2.
///
/// Princípio: exercício ≠ variação de equipamento.
/// “Supino reto” cobre barra, halteres e máquina.
///
/// “Rosca inversa” aparece uma única vez (antebraço), evitando duplicata
/// com a lista de bíceps da especificação.
class ExerciseCatalog {
  ExerciseCatalog._();

  static const List<CatalogExercise> all = [
    // —— PEITO
    CatalogExercise(id: 'lib_peito_supino_reto', name: 'Supino reto', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_supino_inclinado', name: 'Supino inclinado', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_supino_declinado', name: 'Supino declinado', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_crucifixo', name: 'Crucifixo', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_crossover', name: 'Crossover', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_peck_deck', name: 'Peck deck', muscleGroup: MuscleGroup.peito),
    CatalogExercise(id: 'lib_peito_pullover', name: 'Pullover', muscleGroup: MuscleGroup.peito),

    // —— COSTAS
    CatalogExercise(id: 'lib_costas_barra_fixa', name: 'Barra fixa', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_puxada_vertical', name: 'Puxada vertical', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_remada_horizontal', name: 'Remada horizontal', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_remada_unilateral', name: 'Remada unilateral', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_remada_cavalinho', name: 'Remada cavalinho', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_remada_baixa', name: 'Remada baixa', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_pulldown', name: 'Pulldown', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_pullover_polia', name: 'Pullover na polia', muscleGroup: MuscleGroup.costas),
    CatalogExercise(id: 'lib_costas_encolhimento', name: 'Encolhimento', muscleGroup: MuscleGroup.costas),

    // —— OMBROS
    CatalogExercise(id: 'lib_ombros_desenvolvimento', name: 'Desenvolvimento', muscleGroup: MuscleGroup.ombros),
    CatalogExercise(id: 'lib_ombros_elevacao_lateral', name: 'Elevação lateral', muscleGroup: MuscleGroup.ombros),
    CatalogExercise(id: 'lib_ombros_elevacao_frontal', name: 'Elevação frontal', muscleGroup: MuscleGroup.ombros),
    CatalogExercise(id: 'lib_ombros_crucifixo_inverso', name: 'Crucifixo inverso', muscleGroup: MuscleGroup.ombros),
    CatalogExercise(id: 'lib_ombros_face_pull', name: 'Face pull', muscleGroup: MuscleGroup.ombros),
    CatalogExercise(id: 'lib_ombros_remada_alta', name: 'Remada alta', muscleGroup: MuscleGroup.ombros),

    // —— BÍCEPS
    CatalogExercise(id: 'lib_biceps_rosca_direta', name: 'Rosca direta', muscleGroup: MuscleGroup.biceps),
    CatalogExercise(id: 'lib_biceps_rosca_alternada', name: 'Rosca alternada', muscleGroup: MuscleGroup.biceps),
    CatalogExercise(id: 'lib_biceps_rosca_martelo', name: 'Rosca martelo', muscleGroup: MuscleGroup.biceps),
    CatalogExercise(id: 'lib_biceps_rosca_scott', name: 'Rosca Scott', muscleGroup: MuscleGroup.biceps),
    CatalogExercise(id: 'lib_biceps_rosca_concentrada', name: 'Rosca concentrada', muscleGroup: MuscleGroup.biceps),

    // —— TRÍCEPS
    CatalogExercise(id: 'lib_triceps_polia', name: 'Tríceps na polia', muscleGroup: MuscleGroup.triceps),
    CatalogExercise(id: 'lib_triceps_frances', name: 'Tríceps francês', muscleGroup: MuscleGroup.triceps),
    CatalogExercise(id: 'lib_triceps_testa', name: 'Tríceps testa', muscleGroup: MuscleGroup.triceps),
    CatalogExercise(id: 'lib_triceps_coice', name: 'Tríceps coice', muscleGroup: MuscleGroup.triceps),
    CatalogExercise(id: 'lib_triceps_mergulho', name: 'Mergulho para tríceps', muscleGroup: MuscleGroup.triceps),

    // —— QUADRÍCEPS
    CatalogExercise(id: 'lib_quad_agachamento', name: 'Agachamento', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_agachamento_frontal', name: 'Agachamento frontal', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_leg_press', name: 'Leg press', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_hack_squat', name: 'Hack squat', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_cadeira_extensora', name: 'Cadeira extensora', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_afundo', name: 'Afundo', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_passada', name: 'Passada', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_agachamento_bulgaro', name: 'Agachamento búlgaro', muscleGroup: MuscleGroup.quadriceps),
    CatalogExercise(id: 'lib_quad_step_up', name: 'Step-up', muscleGroup: MuscleGroup.quadriceps),

    // —— POSTERIOR DE COXA
    CatalogExercise(id: 'lib_post_stiff', name: 'Stiff', muscleGroup: MuscleGroup.posteriorCoxa),
    CatalogExercise(id: 'lib_post_terra_romeno', name: 'Levantamento terra romeno', muscleGroup: MuscleGroup.posteriorCoxa),
    CatalogExercise(id: 'lib_post_mesa_flexora', name: 'Mesa flexora', muscleGroup: MuscleGroup.posteriorCoxa),
    CatalogExercise(id: 'lib_post_cadeira_flexora', name: 'Cadeira flexora', muscleGroup: MuscleGroup.posteriorCoxa),
    CatalogExercise(id: 'lib_post_flexao_nordica', name: 'Flexão nórdica', muscleGroup: MuscleGroup.posteriorCoxa),
    CatalogExercise(id: 'lib_post_good_morning', name: 'Good morning', muscleGroup: MuscleGroup.posteriorCoxa),

    // —— GLÚTEOS
    CatalogExercise(id: 'lib_glute_elevacao_pelvica', name: 'Elevação pélvica', muscleGroup: MuscleGroup.gluteos),
    CatalogExercise(id: 'lib_glute_coice', name: 'Coice', muscleGroup: MuscleGroup.gluteos),
    CatalogExercise(id: 'lib_glute_abducao', name: 'Abdução de quadril', muscleGroup: MuscleGroup.gluteos),
    CatalogExercise(id: 'lib_glute_aducao', name: 'Adução de quadril', muscleGroup: MuscleGroup.gluteos),

    // —— PANTURRILHAS
    CatalogExercise(id: 'lib_pant_pe', name: 'Panturrilha em pé', muscleGroup: MuscleGroup.panturrilhas),
    CatalogExercise(id: 'lib_pant_sentado', name: 'Panturrilha sentado', muscleGroup: MuscleGroup.panturrilhas),
    CatalogExercise(id: 'lib_pant_leg_press', name: 'Panturrilha no leg press', muscleGroup: MuscleGroup.panturrilhas),

    // —— ABDÔMEN
    CatalogExercise(id: 'lib_abd_abdominal', name: 'Abdominal', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_infra', name: 'Abdominal infra', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_polia', name: 'Abdominal na polia', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_maquina', name: 'Abdominal máquina', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_prancha', name: 'Prancha', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_elevacao_pernas', name: 'Elevação de pernas', muscleGroup: MuscleGroup.abdomen),
    CatalogExercise(id: 'lib_abd_obliquo', name: 'Abdominal oblíquo', muscleGroup: MuscleGroup.abdomen),

    // —— LOMBAR
    CatalogExercise(id: 'lib_lombar_extensao', name: 'Extensão lombar', muscleGroup: MuscleGroup.lombar),
    CatalogExercise(id: 'lib_lombar_hiperextensao', name: 'Hiperextensão', muscleGroup: MuscleGroup.lombar),

    // —— ANTEBRAÇO (inclui Rosca inversa uma única vez)
    CatalogExercise(id: 'lib_ant_flexao_punho', name: 'Flexão de punho', muscleGroup: MuscleGroup.antebraco),
    CatalogExercise(id: 'lib_ant_extensao_punho', name: 'Extensão de punho', muscleGroup: MuscleGroup.antebraco),
    CatalogExercise(id: 'lib_ant_rosca_inversa', name: 'Rosca inversa', muscleGroup: MuscleGroup.antebraco),

    // —— CARDIO (biblioteca — distinto do cardio de finalização da sessão)
    CatalogExercise(
      id: 'lib_cardio_esteira',
      name: 'Esteira',
      muscleGroup: MuscleGroup.cardio,
      type: ExerciseType.cardio,
    ),
    CatalogExercise(
      id: 'lib_cardio_bicicleta',
      name: 'Bicicleta',
      muscleGroup: MuscleGroup.cardio,
      type: ExerciseType.cardio,
    ),
    CatalogExercise(
      id: 'lib_cardio_eliptico',
      name: 'Elíptico',
      muscleGroup: MuscleGroup.cardio,
      type: ExerciseType.cardio,
    ),
    CatalogExercise(
      id: 'lib_cardio_escada',
      name: 'Escada',
      muscleGroup: MuscleGroup.cardio,
      type: ExerciseType.cardio,
    ),
    CatalogExercise(
      id: 'lib_cardio_remo',
      name: 'Remo',
      muscleGroup: MuscleGroup.cardio,
      type: ExerciseType.cardio,
    ),
  ];
}
