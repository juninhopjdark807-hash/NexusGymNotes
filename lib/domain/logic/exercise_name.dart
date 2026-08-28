/// Normalização de nomes de exercício para busca e detecção de duplicatas.
///
/// Remove acentos, deixa minúsculo e colapsa espaços — “Supino Reto” e
/// “supino reto” são tratados como o mesmo nome.
class ExerciseName {
  ExerciseName._();

  static const Map<String, String> _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  /// Forma canônica para comparação (sem acento, minúsculo, espaços únicos).
  static String normalize(String raw) {
    final lower = raw.trim().toLowerCase();
    final buf = StringBuffer();
    for (final r in lower.runes) {
      final ch = String.fromCharCode(r);
      buf.write(_accents[ch] ?? ch);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Tokens de busca (palavras individuais).
  static List<String> tokens(String raw) {
    final n = normalize(raw);
    if (n.isEmpty) return const [];
    return n.split(' ').where((t) => t.isNotEmpty).toList(growable: false);
  }

  /// A query casa com o nome se todas as palavras da query aparecem no nome
  /// (ordem livre) ou se a query inteira é substring do nome.
  static bool matches(String exerciseName, String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    final name = normalize(exerciseName);
    if (name.contains(q)) return true;
    final qTokens = tokens(query);
    if (qTokens.isEmpty) return true;
    return qTokens.every(name.contains);
  }

  /// Dois nomes são equivalentes (duplicata).
  static bool isSame(String a, String b) => normalize(a) == normalize(b);
}
