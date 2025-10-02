class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final UserRole role;
  final Map<String, dynamic>? preferences;
  final String? profilePicturePath;
  final String? primaryPhone;
  final String? secondaryPhone;
  final String? shopName;
  final String? shopTimings;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.role = UserRole.user,
    this.preferences,
    this.profilePicturePath,
    this.primaryPhone,
    this.secondaryPhone,
    this.shopName,
    this.shopTimings,
  });

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == UserRole.admin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get canManageUsers => isAdmin || isSuperAdmin;

  // Convert User to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'role': role.index,
      'preferences': preferences != null ? _encodePreferences(preferences!) : null,
      'profilePicturePath': profilePicturePath,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'shopName': shopName,
      'shopTimings': shopTimings,
    };
  }

  // Create User from Map (database retrieval)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isActive: (map['isActive'] ?? 1) == 1,
      role: UserRole.values[map['role'] ?? 0],
      preferences: map['preferences'] != null ? _decodePreferences(map['preferences']) : null,
      profilePicturePath: map['profilePicturePath'],
      primaryPhone: map['primaryPhone'],
      secondaryPhone: map['secondaryPhone'],
      shopName: map['shopName'],
      shopTimings: map['shopTimings'],
    );
  }

  // Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    UserRole? role,
    Map<String, dynamic>? preferences,
    String? profilePicturePath,
    String? primaryPhone,
    String? secondaryPhone,
    String? shopName,
    String? shopTimings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      shopName: shopName ?? this.shopName,
      shopTimings: shopTimings ?? this.shopTimings,
    );
  }

  // Helper methods for preferences encoding/decoding
  static String _encodePreferences(Map<String, dynamic> preferences) {
    // In a real app, use dart:convert for proper JSON encoding
    return preferences.toString();
  }

  static Map<String, dynamic> _decodePreferences(String preferencesString) {
    // In a real app, use dart:convert for proper JSON decoding
    return <String, dynamic>{};
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        role.hashCode;
  }
}

/// User roles for access control
enum UserRole {
  user,      // Regular user - can only access their own data
  admin,     // Admin - can manage users and access all data
  superAdmin // Super admin - full system access (future use)
}

/// Extension to get display names for user roles
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.superAdmin:
        return 'Super Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.user:
        return 'Can access and manage their own records';
      case UserRole.admin:
        return 'Can manage users and access all records';
      case UserRole.superAdmin:
        return 'Full system access and administration';
    }
  }
}