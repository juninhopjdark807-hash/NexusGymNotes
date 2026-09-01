/// Sexo biológico usado em estimativas (IMC/BF/TMB/calorias).
enum Sex {
  masculino('Masculino'),
  feminino('Feminino');

  const Sex(this.label);
  final String label;

  static Sex fromName(String? name) => Sex.values.firstWhere(
        (s) => s.name == name,
        orElse: () => Sex.masculino,
      );
}

/// Perfil físico do usuário (dados cadastrais).
///
/// Campos obrigatórios para salvar: [name], [sex], [birthDate],
/// [heightCm], [currentWeightKg].
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.sex,
    required this.birthDate,
    required this.heightCm,
    required this.currentWeightKg,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Sex sex;
  final DateTime birthDate;
  final double heightCm;
  final double currentWeightKg;
  final DateTime updatedAt;

  int get ageYears {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  UserProfile copyWith({
    String? name,
    Sex? sex,
    DateTime? birthDate,
    double? heightCm,
    double? currentWeightKg,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
