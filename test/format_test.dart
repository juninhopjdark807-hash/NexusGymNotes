import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_gym_notes/core/format.dart';

void main() {
  group('formatKg', () {
    test('inteiro sem sufixo decimal', () {
      expect(formatKg(110), '110');
      expect(formatKg(30), '30');
      expect(formatKg(0), '0');
    });

    test('meio quilograma com vírgula (pt-BR)', () {
      expect(formatKg(100.5), '100,5');
      expect(formatKg(2.5), '2,5');
    });
  });

  group('parseKg', () {
    test('aceita vírgula, ponto e espaços', () {
      expect(parseKg('100,5'), 100.5);
      expect(parseKg('100.5'), 100.5);
      expect(parseKg(' 90 '), 90.0);
    });

    test('entrada inválida retorna null', () {
      expect(parseKg('abc'), isNull);
      expect(parseKg(''), isNull);
      expect(parseKg('-5'), isNull);
    });
  });

  group('datas', () {
    test('formato "27 AGO 2026"', () {
      expect(formatDate(DateTime(2026, 8, 27)), '27 AGO 2026');
    });

    test('chave de dia para agrupamento', () {
      expect(dateKey(DateTime(2026, 8, 5)), '2026-08-05');
    });
  });

  group('duração', () {
    test('formato em minutos', () {
      expect(formatDuration(54), '54 min');
    });

    test('tempo decorrido MM:SS', () {
      expect(formatElapsed(const Duration(minutes: 5, seconds: 4)), '05:04');
    });

    test('tempo decorrido HH:MM acima de 1h', () {
      expect(formatElapsed(const Duration(hours: 1, minutes: 7)), '1:07');
    });
  });
}
