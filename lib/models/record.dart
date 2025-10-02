class Record {
  final int? id;
  final int? userId;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final int priority;
  final bool isArchived;

  Record({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.tags,
    this.priority = 0,
    this.isArchived = false,
  });

  // Convert Record to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
      'tags': tags != null ? _encodeTags(tags!) : null,
      'priority': priority,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  // Create Record from Map (database retrieval)
  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id']?.toInt(),
      userId: map['userId']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata']) : null,
      tags: map['tags'] != null ? _decodeTags(map['tags']) : null,
      priority: map['priority'] ?? 0,
      isArchived: (map['isArchived'] ?? 0) == 1,
    );
  }

  // Create a copy of Record with updated fields
  Record copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    int? priority,
    bool? isArchived,
  }) {
    return Record(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Helper methods for metadata encoding/decoding
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    // Simple JSON-like encoding for demonstration
    // In a real app, you might use dart:convert
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadataString) {
    // Simple decoding - in a real app, use proper JSON parsing
    return <String, dynamic>{};
  }

  // Helper methods for tags encoding/decoding
  static String _encodeTags(List<String> tags) {
    return tags.join(',');
  }

  static List<String> _decodeTags(String tagsString) {
    if (tagsString.isEmpty) return [];
    return tagsString.split(',').map((tag) => tag.trim()).toList();
  }

  // Utility methods
  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      case 3:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  bool get hasHighPriority => priority >= 2;
  bool get hasTags => tags != null && tags!.isNotEmpty;
  int get tagCount => tags?.length ?? 0;

  @override
  String toString() {
    return 'Record{id: $id, userId: $userId, title: $title, description: $description, category: $category, priority: $priority, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.priority == priority &&
        other.isArchived == isArchived &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        priority.hashCode ^
        isArchived.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}