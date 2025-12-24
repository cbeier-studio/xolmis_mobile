

// Field journal class

class FieldJournal {
  late int? id;
  final String title;
  String? notes;
  final DateTime? creationDate;
  final DateTime? lastModifiedDate;
  String? observer;

  FieldJournal({
    this.id,
    required this.title,
    this.notes,
    this.creationDate,
    this.lastModifiedDate,
    this.observer,
  });

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

  FieldJournal copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? creationDate,
    DateTime? lastModifiedDate,
    String? observer,
  }) {
    return FieldJournal(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      creationDate: creationDate ?? this.creationDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      observer: observer ?? this.observer,
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
        'observer: $observer'
        '}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'creationDate': creationDate?.toIso8601String(),
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'observer': observer,
    };
  }

  factory FieldJournal.fromJson(Map<String, dynamic> json) {
    return FieldJournal(
      id: json['id'],
      title: json['title'],
      notes: json['notes'],
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
      lastModifiedDate: json['lastModifiedDate'] != null ? DateTime.parse(json['lastModifiedDate']) : null,
      observer: json['observer'],
    );
  }
}