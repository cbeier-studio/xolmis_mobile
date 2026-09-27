import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/data/models/journal.dart';

void main() {
  group('Specimen Model Tests', () {
    test('Specimen toMap and fromMap conversion preserves properties', () {
      final now = DateTime.now();
      final specimen = Specimen(
        id: 1,
        sampleTime: now,
        fieldNumber: 'F-001',
        type: SpecimenType.spcFeathers,
        longitude: -58.3816,
        latitude: -34.6037,
        locality: 'Buenos Aires',
        speciesName: 'Turdus rufiventris',
        observer: 'John Doe',
        notes: 'Sample notes',
        isPending: false,
      );

      final map = specimen.toMap();
      final restored = Specimen.fromMap(map);

      expect(restored.id, equals(specimen.id));
      expect(restored.fieldNumber, equals(specimen.fieldNumber));
      expect(restored.type, equals(specimen.type));
      expect(restored.longitude, equals(specimen.longitude));
      expect(restored.latitude, equals(specimen.latitude));
      expect(restored.locality, equals(specimen.locality));
      expect(restored.speciesName, equals(specimen.speciesName));
      expect(restored.observer, equals(specimen.observer));
      expect(restored.notes, equals(specimen.notes));
      expect(restored.isPending, equals(specimen.isPending));
    });

    test('Specimen toJson and fromJson conversion preserves properties', () {
      final now = DateTime.now();
      final specimen = Specimen(
        id: 2,
        sampleTime: now,
        fieldNumber: 'F-002',
        type: SpecimenType.spcEgg,
        longitude: -56.1645,
        latitude: -34.9011,
        locality: 'Montevideo',
        speciesName: 'Furnarius rufus',
        observer: 'Jane Doe',
        notes: 'Egg sample',
        isPending: true,
      );

      final jsonMap = specimen.toJson();
      final restored = Specimen.fromJson(jsonMap);

      expect(restored.id, equals(specimen.id));
      expect(restored.fieldNumber, equals(specimen.fieldNumber));
      expect(restored.type, equals(specimen.type));
      expect(restored.speciesName, equals(specimen.speciesName));
      expect(restored.isPending, equals(specimen.isPending));
    });

    test('Specimen copyWith updates specified fields', () {
      final specimen = Specimen(fieldNumber: 'F-001', isPending: true);
      final updated = specimen.copyWith(fieldNumber: 'F-002', isPending: false);

      expect(updated.fieldNumber, equals('F-002'));
      expect(updated.isPending, isFalse);
    });
  });

  group('FieldJournal Model Tests', () {
    test('FieldJournal toMap and fromMap conversion preserves properties', () {
      final now = DateTime.now();
      final journal = FieldJournal(
        id: 1,
        title: 'Field Notes',
        notes: 'Observed many birds.',
        creationDate: now,
        lastModifiedDate: now,
        observer: 'Observer A',
        backgroundColor: 0xFFFFFFFF,
      );

      final map = journal.toMap();
      final restored = FieldJournal.fromMap(map);

      expect(restored.id, equals(journal.id));
      expect(restored.title, equals(journal.title));
      expect(restored.notes, equals(journal.notes));
      expect(restored.observer, equals(journal.observer));
      expect(restored.backgroundColor, equals(journal.backgroundColor));
    });

    test('FieldJournal copyWith updates specified fields', () {
      final journal = FieldJournal(title: 'Old Title', notes: 'Notes');
      final updated = journal.copyWith(title: 'New Title');

      expect(updated.title, equals('New Title'));
      expect(updated.notes, equals('Notes'));
    });
  });
}
