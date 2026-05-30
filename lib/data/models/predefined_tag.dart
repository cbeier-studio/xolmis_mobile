/// Represents a reusable tag definition stored in `predefined_tags`.
class PredefinedTag {
  final int id;
  final String name;
  final int colorIndex;
  final bool isCustom;

  const PredefinedTag({required this.id, required this.name, required this.colorIndex, required this.isCustom});

  /// Creates a [PredefinedTag] from a SQLite row map.
  factory PredefinedTag.fromMap(Map<String, dynamic> map) {
    return PredefinedTag(
      id: map['id'] as int,
      name: map['name'] as String,
      colorIndex: map['colorIndex'] as int,
      isCustom: (map['isCustom'] as int? ?? 0) == 1,
    );
  }

  /// Converts this definition to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'colorIndex': colorIndex, 'isCustom': isCustom ? 1 : 0};
  }

  /// Returns a copy with selected fields replaced.
  PredefinedTag copyWith({int? id, String? name, int? colorIndex, bool? isCustom}) {
    return PredefinedTag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
