class Customer {
  final int? id;
  final String customerId;
  final String tenantId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final double? discountPercent; // Discount percentage (0-100) for this customer
  final double? previousArrears; // Previous arrears amount
  final double? received; // Received amount
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Customer({
    this.id,
    required this.customerId,
    required this.tenantId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.discountPercent,
    this.previousArrears,
    this.received,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Factory constructor from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      customerId: map['customer_id'],
      tenantId: map['tenant_id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      discountPercent: map['discount_percent']?.toDouble(),
      previousArrears: map['previous_arrears']?.toDouble(),
      received: map['received']?.toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'discount_percent': discountPercent,
      'previous_arrears': previousArrears,
      'received': received,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Copy with method for updates
  Customer copyWith({
    int? id,
    String? customerId,
    String? tenantId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? discountPercent,
    double? previousArrears,
    double? received,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      discountPercent: discountPercent ?? this.discountPercent,
      previousArrears: previousArrears ?? this.previousArrears,
      received: received ?? this.received,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Customer{customerId: $customerId, name: $name, phone: $phone}';
  }
}