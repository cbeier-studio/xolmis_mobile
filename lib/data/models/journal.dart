import '../models/tag.dart';

/// Represents a field journal entry stored locally by the app.
class FieldJournal {
  late int? id;
  final String title;
  String? notes;
  final DateTime? creationDate;
  final DateTime? lastModifiedDate;
  String? observer;
  List<JournalTag> tags;

  FieldJournal({
    this.id,
    required this.title,
    this.notes,
    this.creationDate,
    this.lastModifiedDate,
    this.observer,
    this.tags = const [],
  });

  /// Creates a [FieldJournal] from a SQLite row map.
  factory FieldJournal.fromMap(Map<String, dynamic> map) {
    return FieldJournal(
      id: map['id'],
      title: map['title'],
      notes: map['notes'],
      creationDate: map['creationDate'] != null
          ? DateTime.parse(map['creationDate'])
          : null,
      lastModifiedDate: map['lastModifiedDate'] != null
          ? DateTime.parse(map['lastModifiedDate'])
          : null,
      observer: map['observer'],
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
    List<JournalTag>? tags,
  }) {
    return FieldJournal(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      creationDate: creationDate ?? this.creationDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      observer: observer ?? this.observer,
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
      notes: json['notes'],
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
      lastModifiedDate: json['lastModifiedDate'] != null ? DateTime.parse(json['lastModifiedDate']) : null,
      observer: json['observer'],
      tags: tagsList,
    );
  }
}