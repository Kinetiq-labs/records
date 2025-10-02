class BusinessYear {
  final int? id;
  final String yearId;
  final String tenantId;
  final int yearNumber;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int totalEntries;
  final DateTime createdAt;
  final int syncStatus;

  const BusinessYear({
    this.id,
    required this.yearId,
    required this.tenantId,
    required this.yearNumber,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.totalEntries = 0,
    required this.createdAt,
    this.syncStatus = 1,
  });

  factory BusinessYear.fromMap(Map<String, dynamic> map) {
    return BusinessYear(
      id: map['id'],
      yearId: map['year_id'],
      tenantId: map['tenant_id'],
      yearNumber: map['year_number'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: map['is_active'] == 1,
      totalEntries: map['total_entries'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: map['sync_status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year_id': yearId,
      'tenant_id': tenantId,
      'year_number': yearNumber,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'is_active': isActive ? 1 : 0,
      'total_entries': totalEntries,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
}

class BusinessMonth {
  final int? id;
  final String monthId;
  final String yearId;
  final int monthNumber;
  final String monthName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalEntries;
  final DateTime createdAt;
  final int syncStatus;

  const BusinessMonth({
    this.id,
    required this.monthId,
    required this.yearId,
    required this.monthNumber,
    required this.monthName,
    required this.startDate,
    required this.endDate,
    this.totalEntries = 0,
    required this.createdAt,
    this.syncStatus = 1,
  });

  factory BusinessMonth.fromMap(Map<String, dynamic> map) {
    return BusinessMonth(
      id: map['id'],
      monthId: map['month_id'],
      yearId: map['year_id'],
      monthNumber: map['month_number'],
      monthName: map['month_name'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      totalEntries: map['total_entries'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: map['sync_status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month_id': monthId,
      'year_id': yearId,
      'month_number': monthNumber,
      'month_name': monthName,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'total_entries': totalEntries,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
}

class BusinessDay {
  final int? id;
  final String dayId;
  final String monthId;
  final DateTime dayDate;
  final String dayName;
  final int totalEntries;
  final DateTime createdAt;
  final int syncStatus;

  const BusinessDay({
    this.id,
    required this.dayId,
    required this.monthId,
    required this.dayDate,
    required this.dayName,
    this.totalEntries = 0,
    required this.createdAt,
    this.syncStatus = 1,
  });

  factory BusinessDay.fromMap(Map<String, dynamic> map) {
    return BusinessDay(
      id: map['id'],
      dayId: map['day_id'],
      monthId: map['month_id'],
      dayDate: DateTime.parse(map['day_date']),
      dayName: map['day_name'],
      totalEntries: map['total_entries'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: map['sync_status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day_id': dayId,
      'month_id': monthId,
      'day_date': dayDate.toIso8601String().substring(0, 10),
      'day_name': dayName,
      'total_entries': totalEntries,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
}