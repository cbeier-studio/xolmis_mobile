/// Represents a observer.
class Observer {
  final String observerAbbrev;
  final String observerName;
  final String? emailAddress;

  Observer({
    required this.observerAbbrev,
    required this.observerName,
    this.emailAddress,
  });

  /// Creates a [Observer] from a SQLite row map.
  factory Observer.fromMap(Map<String, dynamic> map) {
    return Observer(
      observerAbbrev: map['observerAbbrev'],
      observerName: map['observerName'],
      emailAddress: map['emailAddress'],
    );
  }

  /// Converts this observer into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {'observerAbbrev': observerAbbrev, 'observerName': observerName, 'emailAddress': emailAddress};
  }

  /// Returns a copy of this observer with the provided fields replaced.
  Observer copyWith({required String observerAbbrev, required String observerName, String? emailAddress}) {
    return Observer(
      observerAbbrev: observerAbbrev,
      observerName: observerName,
      emailAddress: emailAddress ?? this.emailAddress,
    );
  }

  @override
  String toString() {
    return 'Observer{'
        'observerAbbrev: $observerAbbrev, '
        'observerName: $observerName, '
        'emailAddress: $emailAddress'
        '}';
  }

  /// Converts this observer into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'observerAbbrev': observerAbbrev,
      'observerName': observerName,
      'emailAddress': emailAddress,
    };
  }

  /// Creates a [Observer] from a JSON map.
  factory Observer.fromJson(Map<String, dynamic> json) {
    return Observer(
      observerAbbrev: json['observerAbbrev'],
      observerName: json['observerName'],
      emailAddress: json['emailAddress'],
    );
  }
}