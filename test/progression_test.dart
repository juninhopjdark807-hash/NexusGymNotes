import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/domain/logic/progression.dart';

void main() {
  group('Progression.roundEven', () {
    test('arredonda para o número par mais próximo', () {
      expect(Progression.roundEven(33), 34);
      expect(Progression.roundEven(99), 100);
      expect(Progression.roundEven(30), 30);
      expect(Progression.roundEven(90), 90);
      expect(Progression.roundEven(34), 34);
      expect(Progression.roundEven(29), 30);
      expect(Progression.roundEven(33.6), 34); // 33.6 -> 34
      expect(Progression.roundEven(98.9), 98); // 98.9 -> par mais próximo: 98
    });
  });

  group('Sugestões a partir da referência', () {
    test('referência 110 kg (exemplo da especificação)', () {
      expect(Progression.warmupSuggestion(110), 34); // 33 -> 34
      expect(Progression.prepSuggestion(110), 100); // 99 -> 100
    });

    test('referência 100 kg (exemplo da especificação)', () {
      expect(Progression.warmupSuggestion(100), 30); // 30 -> 30
      expect(Progression.prepSuggestion(100), 90); // 90 -> 90
    });

    test('fatores padrão: 30% e 90%', () {
      expect(Progression.warmupFactor, 0.30);
      expect(Progression.prepFactor, 0.90);
    });
  });

  group('Referência (maior carga de trabalho anterior)', () {
    test('primeira execução: sem histórico retorna null', () {
      expect(Progression.referenceFromWorkSets(const []), isNull);
    });

    test('retorna a maior carga de trabalho', () {
      expect(Progression.referenceFromWorkSets([100, 100, 110]), 110);
      expect(Progression.referenceFromWorkSets([110, 100, 105]), 110);
      expect(Progression.referenceFromWorkSets([90]), 90);
    });

    test('carga menor não altera a referência', () {
      expect(Progression.referenceFromWorkSets([110, 90, 95]), 110);
    });
  });
}
