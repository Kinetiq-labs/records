class KhataEntry {
  // Primary Key & References
  final int? id;
  final String entryId;
  final String dayId;
  final String tenantId;
  
  // Entry Metadata
  final int entryIndex;
  final DateTime entryDate;
  
  // INPUT FIELDS (11 fields from form)
  final String name;           // REQUIRED
  final double? weight;        // Decimal allowed
  final String? detail;
  final int number;           // REQUIRED, integers only
  final int? returnWeight1;   // Integers only (numeric value for calculations)
  final String? returnWeight1Display; // Original format like "0.330 3P"
  final int? firstWeight;     // Integers only
  final int? silver;          // Integers only (existing field, separate from silverSold)
  final int? returnWeight2;   // Integers only
  final int? nalki;           // Integers only
  final double? silverSold;   // NEW: Silver Sold field (decimal allowed)
  final double? silverAmount; // NEW: Silver Amount field (decimal allowed)
  final bool? _silverPaid;     // NEW: Whether silver price has been paid/received

  // Getter for silverPaid with null safety
  bool get silverPaid {
    try {
      return _silverPaid ?? false;
    } catch (e) {
      // In case of any error, default to false
      return false;
    }
  }

  // COMPUTED FIELDS (6 calculated fields)
  final double? total;         // first_weight + silver
  final double? difference;    // total - return_weight_2
  final double? sumValue;      // nalki/first_weight * 1000
  final double? rtti;          // sum_value/1000*96-96
  final double? carat;         // sum_value/1000*24 (CORRECTED SPELLING)
  final double? masha;         // sum_value/1000*11.664-11.664
  
  // Computation Status
  final bool isComputed;
  final String? computationErrors;
  
  // New Fields
  final DateTime? entryTime;    // Time when entry was created (HH:MM AM/PM)
  final String? status;         // Options: 'Paid', 'Pending', 'Gold', null (empty by default)
  final double? discountPercent; // Discount percentage (0-100) for this entry
  
  // Sync & Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus;        // 0=synced, 1=pending sync
  final bool isDeleted;

  const KhataEntry({
    this.id,
    required this.entryId,
    required this.dayId,
    required this.tenantId,
    required this.entryIndex,
    required this.entryDate,
    required this.name,
    this.weight,
    this.detail,
    required this.number,
    this.returnWeight1,
    this.returnWeight1Display,
    this.firstWeight,
    this.silver,
    this.returnWeight2,
    this.nalki,
    this.silverSold,
    this.silverAmount,
    bool? silverPaid,
    this.total,
    this.difference,
    this.sumValue,
    this.rtti,
    this.carat,
    this.masha,
    this.isComputed = false,
    this.computationErrors,
    this.entryTime,
    this.status,
    this.discountPercent,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 1,
    this.isDeleted = false,
  }) : _silverPaid = silverPaid;

  // Factory constructor from database map
  factory KhataEntry.fromMap(Map<String, dynamic> map) {
    return KhataEntry(
      id: map['id'],
      entryId: map['entry_id'],
      dayId: map['day_id'],
      tenantId: map['tenant_id'],
      entryIndex: map['entry_index'],
      entryDate: DateTime.parse(map['entry_date']),
      name: map['name'],
      weight: map['weight']?.toDouble(),
      detail: map['detail'],
      number: map['number'],
      returnWeight1: map['return_weight_1'],
      returnWeight1Display: map['return_weight_1_display'],
      firstWeight: map['first_weight'],
      silver: map['silver'],
      returnWeight2: map['return_weight_2'],
      nalki: map['nalki'],
      silverSold: map['silver_sold']?.toDouble(),
      silverAmount: map['silver_amount']?.toDouble(),
      silverPaid: map['silver_paid'] == 1,
      total: map['total']?.toDouble(),
      difference: map['difference']?.toDouble(),
      sumValue: map['sum_value']?.toDouble(),
      rtti: map['rtti']?.toDouble(),
      carat: map['carat']?.toDouble(),
      masha: map['masha']?.toDouble(),
      isComputed: map['is_computed'] == 1,
      computationErrors: map['computation_errors'],
      entryTime: map['entry_time'] != null ? DateTime.parse(map['entry_time']) : null,
      status: map['status'],
      discountPercent: map['discount_percent']?.toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'],
      isDeleted: map['is_deleted'] == 1,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'entry_id': entryId,
      'day_id': dayId,
      'tenant_id': tenantId,
      'entry_index': entryIndex,
      'entry_date': entryDate.toIso8601String().substring(0, 10),
      'name': name,
      'weight': weight,
      'detail': detail,
      'number': number,
      'return_weight_1': returnWeight1,
      'return_weight_1_display': returnWeight1Display,
      'first_weight': firstWeight,
      'silver': silver,
      'return_weight_2': returnWeight2,
      'nalki': nalki,
      'silver_sold': silverSold,
      'silver_amount': silverAmount,
      'silver_paid': (_silverPaid ?? false) ? 1 : 0,
      'total': total,
      'difference': difference,
      'sum_value': sumValue,
      'rtti': rtti,
      'carat': carat,
      'masha': masha,
      'is_computed': isComputed ? 1 : 0,
      'computation_errors': computationErrors,
      'entry_time': entryTime?.toIso8601String(),
      'status': status,
      'discount_percent': discountPercent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  // Copy with method for updates
  KhataEntry copyWith({
    int? id,
    String? entryId,
    String? dayId,
    String? tenantId,
    int? entryIndex,
    DateTime? entryDate,
    String? name,
    double? weight,
    String? detail,
    int? number,
    int? returnWeight1,
    String? returnWeight1Display,
    int? firstWeight,
    int? silver,
    int? returnWeight2,
    int? nalki,
    double? silverSold,
    double? silverAmount,
    bool? silverPaid,
    double? total,
    double? difference,
    double? sumValue,
    double? rtti,
    double? carat,
    double? masha,
    bool? isComputed,
    String? computationErrors,
    DateTime? entryTime,
    String? status,
    double? discountPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    bool? isDeleted,
  }) {
    return KhataEntry(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      dayId: dayId ?? this.dayId,
      tenantId: tenantId ?? this.tenantId,
      entryIndex: entryIndex ?? this.entryIndex,
      entryDate: entryDate ?? this.entryDate,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      detail: detail ?? this.detail,
      number: number ?? this.number,
      returnWeight1: returnWeight1 ?? this.returnWeight1,
      returnWeight1Display: returnWeight1Display ?? this.returnWeight1Display,
      firstWeight: firstWeight ?? this.firstWeight,
      silver: silver ?? this.silver,
      returnWeight2: returnWeight2 ?? this.returnWeight2,
      nalki: nalki ?? this.nalki,
      silverSold: silverSold ?? this.silverSold,
      silverAmount: silverAmount ?? this.silverAmount,
      silverPaid: silverPaid ?? _silverPaid,
      total: total ?? this.total,
      difference: difference ?? this.difference,
      sumValue: sumValue ?? this.sumValue,
      rtti: rtti ?? this.rtti,
      carat: carat ?? this.carat,
      masha: masha ?? this.masha,
      isComputed: isComputed ?? this.isComputed,
      computationErrors: computationErrors ?? this.computationErrors,
      entryTime: entryTime ?? this.entryTime,
      status: status ?? this.status,
      discountPercent: discountPercent ?? this.discountPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Compute calculated fields
  KhataEntry computeFields() {
    double? newTotal;
    double? newDifference;
    double? newSumValue;
    double? newRtti;
    double? newCarat;
    double? newMasha;
    
    // 1. total = first_weight + silver
    if (firstWeight != null && silver != null) {
      newTotal = (firstWeight! + silver!).toDouble();
    }
    
    // 2. difference = total - return_weight_2
    if (newTotal != null && returnWeight2 != null) {
      newDifference = newTotal - returnWeight2!;
    }
    
    // 3. sum = nalki/first_weight * 1000
    if (nalki != null && firstWeight != null && firstWeight! != 0) {
      newSumValue = (nalki! / firstWeight!) * 1000;
    }
    
    // 4. rtti = sum/1000*96-96
    if (newSumValue != null) {
      newRtti = (newSumValue / 1000 * 96) - 96;
    }
    
    // 5. carat = sum/1000*24 (CORRECTED SPELLING)
    if (newSumValue != null) {
      newCarat = (newSumValue / 1000) * 24;
    }
    
    // 6. masha = sum/1000*11.664-11.664
    if (newSumValue != null) {
      newMasha = (newSumValue / 1000 * 11.664) - 11.664;
    }

    return copyWith(
      total: newTotal,
      difference: newDifference,
      sumValue: newSumValue,
      rtti: newRtti,
      carat: newCarat,
      masha: newMasha,
      isComputed: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'KhataEntry{entryId: $entryId, name: $name, number: $number, date: $entryDate}';
  }
}