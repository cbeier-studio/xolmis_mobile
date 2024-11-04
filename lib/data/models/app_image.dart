class AppImage {
  final int? id;
  final String imagePath;
  String? notes;
  final int? vegetationId;
  final int? eggId;
  final int? specimenId;
  final int? nestRevisionId;

  AppImage({
    this.id,
    required this.imagePath,
    this.notes,
    this.vegetationId,
    this.eggId,
    this.specimenId,
    this.nestRevisionId,
  });

  factory AppImage.fromMap(Map<String, dynamic> map) {
    return AppImage(
      id: map['id'],
      imagePath: map['imagePath'],
      notes: map['notes'],
      vegetationId: map['vegetationId'],
      eggId: map['eggId'],
      specimenId: map['specimenId'],
      nestRevisionId: map['nestRevisionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'notes': notes,
      'vegetationId': vegetationId,
      'eggId': eggId,
      'specimenId': specimenId,
      'nestRevisionId': nestRevisionId,
    };
  }

  AppImage copyWith({
    int? id,
    String? imagePath,
    String? notes,
    int? vegetationId,
    int? eggId,
    int? specimenId,
    int? nestRevisionId,
  }) {
    return AppImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      vegetationId: vegetationId ?? this.vegetationId,
      eggId: eggId ?? this.eggId,
      specimenId: specimenId ?? this.specimenId,
      nestRevisionId: nestRevisionId ?? this.nestRevisionId,
    );
  }
}