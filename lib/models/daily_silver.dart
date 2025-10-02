class DailySilver {
  final String id;
  final DateTime date;
  final double newSilver;
  final double presentSilver; // Previous day's remaining silver
  final double totalSilverFromEntries; // Sum of silver from daily entries
  final double remainingSilver; // Calculated: presentSilver - (totalSilverFromEntries/100000) + newSilver
  final DateTime createdAt;
  final DateTime updatedAt;

  DailySilver({
    required this.id,
    required this.date,
    required this.newSilver,
    required this.presentSilver,
    required this.totalSilverFromEntries,
    required this.remainingSilver,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating from database
  factory DailySilver.fromMap(Map<String, dynamic> map) {
    return DailySilver(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      newSilver: (map['new_silver'] as num).toDouble(),
      presentSilver: (map['present_silver'] as num).toDouble(),
      totalSilverFromEntries: (map['total_silver_from_entries'] as num).toDouble(),
      remainingSilver: (map['remaining_silver'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10), // Store only date part
      'new_silver': newSilver,
      'present_silver': presentSilver,
      'total_silver_from_entries': totalSilverFromEntries,
      'remaining_silver': remainingSilver,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated values
  DailySilver copyWith({
    String? id,
    DateTime? date,
    double? newSilver,
    double? presentSilver,
    double? totalSilverFromEntries,
    double? remainingSilver,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailySilver(
      id: id ?? this.id,
      date: date ?? this.date,
      newSilver: newSilver ?? this.newSilver,
      presentSilver: presentSilver ?? this.presentSilver,
      totalSilverFromEntries: totalSilverFromEntries ?? this.totalSilverFromEntries,
      remainingSilver: remainingSilver ?? this.remainingSilver,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate remaining silver using the formula:
  // remaining_silver = present_silver - (total_silver_from_entries / 100000) + new_silver
  static double calculateRemainingSilver({
    required double presentSilver,
    required double totalSilverFromEntries,
    required double newSilver,
  }) {
    return presentSilver - (totalSilverFromEntries / 100000) + newSilver;
  }

  @override
  String toString() {
    return 'DailySilver{id: $id, date: $date, newSilver: $newSilver, presentSilver: $presentSilver, totalSilverFromEntries: $totalSilverFromEntries, remainingSilver: $remainingSilver}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailySilver &&
        other.id == id &&
        other.date == date &&
        other.newSilver == newSilver &&
        other.presentSilver == presentSilver &&
        other.totalSilverFromEntries == totalSilverFromEntries &&
        other.remainingSilver == remainingSilver;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        newSilver.hashCode ^
        presentSilver.hashCode ^
        totalSilverFromEntries.hashCode ^
        remainingSilver.hashCode;
  }
}