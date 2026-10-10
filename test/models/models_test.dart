import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/data/models/journal.dart';
import 'package:xolmis/data/models/inventory.dart';

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

  group('Inventory Model Tests', () {
    test('Species map/json conversion preserves doubtful flag', () {
      final species = Species(
        id: 1,
        inventoryId: 'INV-001',
        name: 'Elaenia parvirostris',
        isOutOfInventory: false,
        isDoubtful: true,
        count: 2,
      );

      final restoredFromMap = Species.fromMap(species.toMap(species.inventoryId), const []);
      final restoredFromJson = Species.fromJson(species.toJson());

      expect(restoredFromMap.isDoubtful, isTrue);
      expect(restoredFromJson.isDoubtful, isTrue);
    });

    test('Species copyWith updates doubtful flag', () {
      final species = Species(
        inventoryId: 'INV-001',
        name: 'Xolmis dominicanus',
        isOutOfInventory: false,
        isDoubtful: false,
      );

      final updated = species.copyWith(isDoubtful: true);
      expect(updated.isDoubtful, isTrue);
      expect(updated.name, equals(species.name));
    });

    test('Species map/json conversion preserves reproductiveStatus code', () {
      final species = Species(
        id: 1,
        inventoryId: 'INV-001',
        name: 'Xolmis irupero',
        isOutOfInventory: false,
        reproductiveStatus: SpeciesReproductiveStatus.h,
      );

      final map = species.toMap(species.inventoryId);
      expect(map['reproductiveStatus'], equals('H'));

      final restoredFromMap = Species.fromMap(map, const []);
      expect(restoredFromMap.reproductiveStatus, equals(SpeciesReproductiveStatus.h));

      final jsonMap = species.toJson();
      expect(jsonMap['reproductiveStatus'], equals('H'));

      final restoredFromJson = Species.fromJson(jsonMap);
      expect(restoredFromJson.reproductiveStatus, equals(SpeciesReproductiveStatus.h));
    });

    test('hasValidStartCoordinates identifies non-null and non-zero start coordinates', () {
      final invWithStart = Inventory(
        id: 'INV-001',
        type: InventoryType.invCasual,
        duration: 0,
        startLatitude: -23.55,
        startLongitude: -46.63,
      );
      expect(invWithStart.hasValidStartCoordinates, isTrue);

      final invZeroStart = Inventory(
        id: 'INV-002',
        type: InventoryType.invCasual,
        duration: 0,
        startLatitude: 0.0,
        startLongitude: 0.0,
      );
      expect(invZeroStart.hasValidStartCoordinates, isFalse);

      final invNullStart = Inventory(
        id: 'INV-003',
        type: InventoryType.invCasual,
        duration: 0,
      );
      expect(invNullStart.hasValidStartCoordinates, isFalse);
    });

    test('hasValidEndCoordinates identifies non-null and non-zero end coordinates', () {
      final invWithEnd = Inventory(
        id: 'INV-001',
        type: InventoryType.invCasual,
        duration: 0,
        endLatitude: -23.56,
        endLongitude: -46.64,
      );
      expect(invWithEnd.hasValidEndCoordinates, isTrue);

      final invZeroEnd = Inventory(
        id: 'INV-002',
        type: InventoryType.invCasual,
        duration: 0,
        endLatitude: 0.0,
        endLongitude: 0.0,
      );
      expect(invZeroEnd.hasValidEndCoordinates, isFalse);
    });

    test('hasMissingCoordinates returns correct status for active and finished inventories', () {
      // Active inventory with valid start coordinates -> not missing
      final activeInv = Inventory(
        id: 'INV-001',
        type: InventoryType.invCasual,
        duration: 0,
        isFinished: false,
        startLatitude: -23.55,
        startLongitude: -46.63,
        endLatitude: 0.0,
        endLongitude: 0.0,
      );
      expect(activeInv.hasMissingCoordinates, isFalse);

      // Finished inventory with valid start but blank end coordinates -> missing
      final finishedInvMissingEnd = Inventory(
        id: 'INV-002',
        type: InventoryType.invCasual,
        duration: 0,
        isFinished: true,
        startLatitude: -23.55,
        startLongitude: -46.63,
        endLatitude: 0.0,
        endLongitude: 0.0,
      );
      expect(finishedInvMissingEnd.hasMissingCoordinates, isTrue);

      // Finished inventory with both valid start and end coordinates -> not missing
      final finishedInvComplete = Inventory(
        id: 'INV-003',
        type: InventoryType.invCasual,
        duration: 0,
        isFinished: true,
        startLatitude: -23.55,
        startLongitude: -46.63,
        endLatitude: -23.56,
        endLongitude: -46.64,
      );
      expect(finishedInvComplete.hasMissingCoordinates, isFalse);
    });

    test('cancelTimer successfully completes without error', () {
      final inv = Inventory(
        id: 'INV-001',
        type: InventoryType.invCasual,
        duration: 10,
      );
      expect(() => inv.cancelTimer(), returnsNormally);
    });
  });
}
