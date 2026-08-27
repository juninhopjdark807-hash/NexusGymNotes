/// Regras de negócio de progressão e arredondamento.
///
/// Funções puras — sem dependência de UI ou persistência — para
/// que as regras sejam testáveis e reutilizáveis.
///
/// Regra fundamental:
/// > A referência do próximo treino é a MAIOR carga de trabalho
/// > registrada na execução anterior daquele exercício.
/// >
/// > Somente séries classificadas como **TRABALHO** participam do
/// > cálculo. Aquecimento e preparatória NÃO alteram a referência.
class Progression {
  Progression._();

  /// Aquecimento por padrão: 30% da referência.
  static const double warmupFactor = 0.30;

  /// Preparatória por padrão: 90% da referência.
  static const double prepFactor = 0.90;

  /// Arredonda para o número par mais próximo.
  ///
  /// Em casos exatos (ex.: 31.5), arredonda para cima.
  ///
  /// Exemplos:
  /// - 33  -> 34
  /// - 99  -> 100
  /// - 30  -> 30
  /// - 90  -> 90
  /// - 33.6 -> 34
  static double roundEven(double value) {
    if (value <= 0) return 0;
    return 2 * (value / 2).round().toDouble();
  }

  /// Sugestão de peso de aquecimento (30% da referência, par).
  static double warmupSuggestion(double referenceKg) =>
      roundEven(referenceKg * warmupFactor);

  /// Sugestão de peso preparatória (90% da referência, par).
  static double prepSuggestion(double referenceKg) =>
      roundEven(referenceKg * prepFactor);

  /// Referência: maior carga entre as séries de trabalho informadas.
  /// Retorna `null` quando não há histórico (primeira execução).
  static double? referenceFromWorkSets(Iterable<double> workWeights) {
    if (workWeights.isEmpty) return null;
    var max = workWeights.first;
    for (final w in workWeights) {
      if (w > max) max = w;
    }
    return max;
  }
}
