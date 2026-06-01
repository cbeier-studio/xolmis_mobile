import '../models/tag.dart';

/// Represents a field journal entry stored locally by the app.
class FieldJournal {
  static const int defaultBackgroundColorValue = 0xFFFFF8E1; // Colors.amber[50]

  late int? id;
  String? title;
  final String notes;
  final DateTime? creationDate;
  final DateTime? lastModifiedDate;
  String? observer;
  final int backgroundColor;
  List<JournalTag> tags;

  FieldJournal({
    this.id,
    this.title,
    required this.notes,
    this.creationDate,
    this.lastModifiedDate,
    this.observer,
    this.backgroundColor = defaultBackgroundColorValue,
    this.tags = const [],
  });

  static int _parseBackgroundColor(dynamic rawValue) {
    if (rawValue is int) return rawValue;
    if (rawValue is num) return rawValue.toInt();
    if (rawValue is String) {
      final parsed = int.tryParse(rawValue);
      if (parsed != null) return parsed;
    }
    return defaultBackgroundColorValue;
  }

  /// Creates a [FieldJournal] from a SQLite row map.
  factory FieldJournal.fromMap(Map<String, dynamic> map) {
    return FieldJournal(
      id: map['id'],
      title: map['title'],
      notes: (map['notes'] as String?) ?? '',
      creationDate: map['creationDate'] != null
          ? DateTime.parse(map['creationDate'])
          : null,
      lastModifiedDate: map['lastModifiedDate'] != null
          ? DateTime.parse(map['lastModifiedDate'])
          : null,
      observer: map['observer'],
      backgroundColor: _parseBackgroundColor(map['backgroundColor']),
    );
  }

  /// Converts this journal entry into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'creationDate': creationDate?.toIso8601String(),
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'observer': observer,
      'backgroundColor': backgroundColor,
    };
  }

  /// Returns a copy of this journal entry with the provided fields replaced.
  FieldJournal copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? creationDate,
    DateTime? lastModifiedDate,
    String? observer,
    int? backgroundColor,
    List<JournalTag>? tags,
  }) {
    return FieldJournal(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      creationDate: creationDate ?? this.creationDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      observer: observer ?? this.observer,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'FieldJournal{'
        'id: $id, '
        'title: $title, '
        'notes: $notes, '
        'creationDate: $creationDate, '
        'lastModifiedDate: $lastModifiedDate, '
        'observer: $observer, '
        'backgroundColor: $backgroundColor, '
        'tags: $tags'
        '}';
  }

  /// Converts this journal entry into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'creationDate': creationDate?.toIso8601String(),
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'observer': observer,
      'backgroundColor': backgroundColor,
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }

  /// Creates a [FieldJournal] from a JSON map.
  factory FieldJournal.fromJson(Map<String, dynamic> json) {
    final tagsList = (json['tags'] as List?)
        ?.map((t) => JournalTag.fromJson(t))
        .toList() ??
        [];

    return FieldJournal(
      id: json['id'],
      title: json['title'],
      notes: (json['notes'] as String?) ?? '',
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
      lastModifiedDate: json['lastModifiedDate'] != null ? DateTime.parse(json['lastModifiedDate']) : null,
      observer: json['observer'],
      backgroundColor: _parseBackgroundColor(json['backgroundColor']),
      tags: tagsList,
    );
  }
}