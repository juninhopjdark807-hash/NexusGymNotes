/// Formatação de valores (pt-BR) e parsing de entradas do usuário.
library;

const List<String> _mesesAbrev = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
];

const List<String> _diasSemana = [
  'DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB',
];

/// Formata um peso: 110 -> "110", 100.5 -> "100,5".
String formatKg(double kg) {
  if ((kg * 10).round() % 10 == 0) {
    return kg.toInt().toString();
  }
  return kg.toStringAsFixed(1).replaceFirst('.', ',');
}

/// Converte texto do usuário em peso (aceita vírgula ou ponto).
double? parseKg(String raw) {
  final s = raw.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  final v = double.tryParse(s);
  if (v == null || v < 0) return null;
  return v;
}

/// Converte texto do usuário em distância (km).
double? parseKm(String raw) => parseKg(raw);

/// Duração em minutos -> "54 min".
String formatDuration(int minutes) => '$minutes min';

/// Data no formato "27 AGO 2026".
String formatDate(DateTime d) => '${d.day} ${_mesesAbrev[d.month - 1]} ${d.year}';

/// Data curta "27 AGO".
String formatDateShort(DateTime d) => '${d.day} ${_mesesAbrev[d.month - 1]}';

/// Dia da semana + data: "SÁB · 27 AGO".
String formatDayLabel(DateTime d) => '${_diasSemana[d.weekday % 7]} · ${formatDateShort(d)}';

/// Chave de agrupamento por dia (YYYY-MM-DD), no fuso local.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Converte a chave "YYYY-MM-DD" em data **local** (sem ambiguidade de fuso).
DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Horário "14:32".
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Duração decorrida em "MM:SS" ou "HH:MM".
String formatElapsed(Duration d) {
  final h = d.inHours;
  if (h > 0) {
    return '$h:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  }
  return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Intervalo entre séries: "01:42" (mm:ss). Valores ≥ 1h usam "H:MM:SS".
String formatInterval(Duration d) {
  if (d.isNegative) return '—';
  final totalSec = d.inSeconds;
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Duração da sessão em HH:MM:SS (a partir de timestamps reais).
String formatSessionDuration(DateTime start, DateTime? end) {
  if (end == null) return '—';
  var d = end.difference(start);
  if (d.isNegative) d = Duration.zero;
  // Mínimo 1s se houve fim após início no mesmo segundo.
  if (d.inSeconds == 0 && end.isAfter(start)) {
    d = const Duration(seconds: 1);
  }
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

/// Índice do dia da semana (0 = domingo).
int weekdayIndex(DateTime d) => d.weekday % 7;
