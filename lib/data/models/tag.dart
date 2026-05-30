/// Represents a tag associated with a field journal entry.
class JournalTag {
  late int? id;
  final int journalId;
  final int? predefinedTagId;
  final String name;
  final int colorIndex;
  final bool isCustom;

  JournalTag({
    this.id,
    required this.journalId,
    this.predefinedTagId,
    required this.name,
    required this.colorIndex,
    this.isCustom = false,
  });

  /// Creates a [JournalTag] from a SQLite row map.
  factory JournalTag.fromMap(Map<String, dynamic> map) {
    return JournalTag(
      id: map['id'],
      journalId: map['journalId'],
      predefinedTagId: map['tagId'] ?? map['predefinedTagId'],
      name: map['name'],
      colorIndex: map['colorIndex'],
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
    );
  }

  /// Converts this tag into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {'id': id, 'journalId': journalId, 'tagId': predefinedTagId};
  }

  /// Returns a copy of this tag with the provided fields replaced.
  JournalTag copyWith({int? id, int? journalId, int? predefinedTagId, String? name, int? colorIndex, bool? isCustom}) {
    return JournalTag(
      id: id ?? this.id,
      journalId: journalId ?? this.journalId,
      predefinedTagId: predefinedTagId ?? this.predefinedTagId,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  String toString() {
    return 'JournalTag{'
        'id: $id, '
        'journalId: $journalId, '
        'predefinedTagId: $predefinedTagId, '
        'name: $name, '
        'colorIndex: $colorIndex, '
        'isCustom: $isCustom'
        '}';
  }

  /// Converts this tag into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journalId': journalId,
      'predefinedTagId': predefinedTagId,
      'name': name,
      'colorIndex': colorIndex,
      'isCustom': isCustom,
    };
  }

  /// Creates a [JournalTag] from a JSON map.
  factory JournalTag.fromJson(Map<String, dynamic> json) {
    return JournalTag(
      id: json['id'],
      journalId: json['journalId'],
      predefinedTagId: json['predefinedTagId'],
      name: json['name'],
      colorIndex: json['colorIndex'],
      isCustom: json['isCustom'] ?? false,
    );
  }
}
