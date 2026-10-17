/// Someone the user sends cards to ("Dona Cida", "Grupo da família").
/// Stored only on the device.
class Recipient {
  const Recipient({required this.id, required this.name, this.birthDate});

  final String id;

  /// Name exactly as it should appear on the card.
  final String name;
  final DateTime? birthDate;

  /// Whether [day] is this person's birthday. People born on 29 February
  /// celebrate on the 28th in non-leap years.
  bool isBirthday(DateTime day) {
    final b = birthDate;
    if (b == null) return false;
    if (b.month == day.month && b.day == day.day) return true;
    final isLeap = DateTime(day.year, 2, 29).month == 2;
    return b.month == 2 && b.day == 29 && !isLeap && day.month == 2 && day.day == 28;
  }

  Recipient copyWith({String? name, DateTime? birthDate, bool clearBirthDate = false}) =>
      Recipient(
        id: id,
        name: name ?? this.name,
        birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      );

  factory Recipient.fromJson(Map<String, dynamic> json) => Recipient(
        id: json['id'] as String,
        name: json['name'] as String,
        birthDate: json['birthDate'] == null
            ? null
            : DateTime.parse(json['birthDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthDate': birthDate == null
            ? null
            : '${birthDate!.year.toString().padLeft(4, '0')}-'
                '${birthDate!.month.toString().padLeft(2, '0')}-'
                '${birthDate!.day.toString().padLeft(2, '0')}',
      };
}
