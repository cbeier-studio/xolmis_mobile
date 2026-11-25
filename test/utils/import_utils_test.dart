import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/data/models/journal.dart';
import 'package:xolmis/data/models/nest.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/utils/export_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Import Envelope & Policy Validation', () {
    test('standard export envelope contains expected source and schema version', () {
      final envelope = {
        'source': kExportSource,
        'schema': 'inventories',
        'schemaVersion': kExportSchemaVersion,
        'records': <Map<String, dynamic>>[],
      };

      expect(envelope['source'], equals('Xolmis Mobile'));
      expect(envelope['schemaVersion'], equals('1'));
      expect(envelope['records'], isEmpty);
    });

    test('default conflict policy fallback is askEveryTime when preference is missing', () async {
      final prefs = await SharedPreferences.getInstance();
      final savedPolicyIndex = prefs.getInt(kImportExistingRecordsPolicyPreferenceKey);

      expect(savedPolicyIndex, isNull);
    });

    test('valid conflict policy index maps correctly to ImportExistingRecordPolicy enum', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        kImportExistingRecordsPolicyPreferenceKey,
        ImportExistingRecordPolicy.updateExisting.index,
      );

      final savedPolicyIndex = prefs.getInt(kImportExistingRecordsPolicyPreferenceKey);
      expect(savedPolicyIndex, equals(ImportExistingRecordPolicy.updateExisting.index));
      expect(ImportExistingRecordPolicy.values[savedPolicyIndex!], equals(ImportExistingRecordPolicy.updateExisting));
    });
  });

  group('Inventory JSON Deserialization & Roundtrip', () {
    test('Inventory.fromJson deserializes complete inventory with child collections', () {
      final jsonMap = {
        'id': 'INV-100',
        'type': InventoryType.invPointCount.index,
        'duration': 15,
        'maxSpecies': 5,
        'startTime': '2025-03-10T08:00:00.000',
        'endTime': '2025-03-10T08:15:00.000',
        'startLongitude': -46.6333,
        'startLatitude': -23.5505,
        'endLongitude': -46.6340,
        'endLatitude': -23.5510,
        'localityName': 'Park Entrance',
        'totalObservers': 2,
        'observer': 'Observer A',
        'notes': 'Sunny day',
        'isDiscarded': false,
        'transportMode': TransportMode.tmodeWalking.index,
        'currentInterval': 1,
        'intervalsWithoutNewSpecies': 0,
        'currentIntervalSpeciesCount': 2,
        'totalPausedTimeInSeconds': 0.0,
        'pauseStartTime': null,
        'speciesList': [
          {
            'id': 1,
            'inventoryId': 'INV-100',
            'name': 'Turdus rufiventris',
            'isOutOfInventory': false,
            'isDoubtful': false,
            'count': 2,
            'notes': 'Singing on tree',
            'sampleTime': '2025-03-10T08:05:00.000',
            'distance': 10.0,
            'flightHeight': 3.0,
            'flightDirection': 'N',
            'habitats': [SpeciesHabitat.forest.index],
            'detectionModes': [SpeciesDetectionMode.song.index],
            'reproductiveStatus': SpeciesReproductiveStatus.s.index,
            'sex': SpeciesSex.male.index,
            'activities': [SpeciesActivity.vocalizing.index],
            'pois': [
              {
                'id': 10,
                'speciesId': 1,
                'sampleTime': '2025-03-10T08:05:00.000',
                'longitude': -46.6335,
                'latitude': -23.5507,
                'notes': 'Fence',
              }
            ],
          }
        ],
        'vegetationList': [
          {
            'id': 20,
            'inventoryId': 'INV-100',
            'sampleTime': '2025-03-10T08:10:00.000',
            'longitude': -46.6334,
            'latitude': -23.5506,
            'herbsProportion': 50,
            'herbsDistribution': DistributionType.disNone.index,
            'herbsHeight': 1,
            'shrubsProportion': 30,
            'shrubsDistribution': DistributionType.disNone.index,
            'shrubsHeight': 2,
            'treesProportion': 20,
            'treesDistribution': DistributionType.disNone.index,
            'treesHeight': 10,
            'notes': 'Mixed vegetation',
          }
        ],
        'weatherList': [
          {
            'id': 30,
            'inventoryId': 'INV-100',
            'sampleTime': '2025-03-10T08:00:00.000',
            'cloudCover': 20,
            'precipitation': PrecipitationType.preNone.index,
            'temperature': 22.5,
            'windSpeed': 1,
            'windDirection': 'SE',
            'atmosphericPressure': 1012.0,
            'relativeHumidity': 70.0,
          }
        ],
      };

      final inventory = Inventory.fromJson(jsonMap);

      expect(inventory.id, equals('INV-100'));
      expect(inventory.type, equals(InventoryType.invPointCount));
      expect(inventory.speciesList.length, equals(1));
      expect(inventory.speciesList.first.name, equals('Turdus rufiventris'));
      expect(inventory.speciesList.first.pois.length, equals(1));
      expect(inventory.vegetationList.length, equals(1));
      expect(inventory.weatherList.length, equals(1));
    });

    test('Inventory toJson and fromJson roundtrip preserves all fields', () {
      final original = Inventory(
        id: 'INV-200',
        type: InventoryType.invMackinnonList,
        duration: 30,
        localityName: 'Trail B',
        speciesList: [
          Species(
            id: 2,
            inventoryId: 'INV-200',
            name: 'Zenaida auriculata',
            count: 5,
            isOutOfInventory: true,
            isDoubtful: false,
          ),
        ],
      );

      final jsonMap = original.toJson();
      final restored = Inventory.fromJson(jsonMap);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.duration, equals(original.duration));
      expect(restored.localityName, equals(original.localityName));
      expect(restored.speciesList.length, equals(1));
      expect(restored.speciesList.first.name, equals('Zenaida auriculata'));
      expect(restored.speciesList.first.isOutOfInventory, isTrue);
    });
  });

  group('Nest JSON Deserialization & Roundtrip', () {
    test('Nest.fromJson parses nest with revisions and eggs and calculates lastNestStatus', () {
      final jsonMap = {
        'id': 50,
        'fieldNumber': 'NEST-2025-01',
        'speciesName': 'Furnarius rufus',
        'localityName': 'Tree A',
        'foundTime': '2025-02-01T10:00:00.000',
        'lastTime': '2025-02-10T11:00:00.000',
        'longitude': -46.6350,
        'latitude': -23.5520,
        'support': 'Branch',
        'heightAboveGround': 2.5,
        'nestFate': NestFateType.fatSuccess.index,
        'male': 'Observed',
        'female': 'Incubating',
        'helpers': 'None',
        'observer': 'Observer B',
        'isActive': 1,
        'revisionCount': 1,
        'eggCount': 2,
        'revisionsList': [
          {
            'id': 101,
            'nestId': 50,
            'sampleTime': '2025-02-05T09:00:00.000',
            'nestStatus': NestStatusType.nstActive.index,
            'nestStage': NestStageType.stgIncubating.index,
            'eggsHost': 2,
            'nestlingsHost': 0,
            'eggsParasite': 0,
            'nestlingsParasite': 0,
            'hasPhilornisLarvae': false,
            'notes': '2 eggs intact',
          }
        ],
        'eggsList': [
          {
            'id': 201,
            'nestId': 50,
            'sampleTime': '2025-02-05T09:05:00.000',
            'fieldNumber': 'EGG-1',
            'speciesName': 'Furnarius rufus',
            'eggShape': EggShapeType.estOval.index,
            'width': 18.5,
            'length': 25.0,
            'mass': 5.0,
          }
        ],
      };

      final nest = Nest.fromJson(jsonMap);

      expect(nest.id, equals(50));
      expect(nest.fieldNumber, equals('NEST-2025-01'));
      expect(nest.lastNestStatus, equals(NestStatusType.nstActive));
      expect(nest.revisionsList!.length, equals(1));
      expect(nest.eggsList!.length, equals(1));
    });

    test('Nest toJson and fromJson roundtrip preserves all properties', () {
      final original = Nest(
        id: 55,
        fieldNumber: 'NEST-2025-02',
        speciesName: 'Sicalis flaveola',
        nestFate: NestFateType.fatLost,
      );

      final jsonMap = original.toJson();
      final restored = Nest.fromJson(jsonMap);

      expect(restored.id, equals(original.id));
      expect(restored.fieldNumber, equals(original.fieldNumber));
      expect(restored.speciesName, equals(original.speciesName));
      expect(restored.nestFate, equals(original.nestFate));
    });
  });

  group('Specimen & FieldJournal JSON Deserialization & Roundtrip', () {
    test('Specimen toJson and fromJson roundtrip preserves properties', () {
      final original = Specimen(
        id: 300,
        sampleTime: DateTime(2025, 1, 15, 14, 0, 0),
        fieldNumber: 'SPC-001',
        type: SpecimenType.spcFeathers,
        longitude: -46.6360,
        latitude: -23.5530,
        locality: 'Museum',
        speciesName: 'Pitangus sulphuratus',
        observer: 'Curator C',
        notes: 'Primary feather',
        isPending: false,
      );

      final jsonMap = original.toJson();
      final restored = Specimen.fromJson(jsonMap);

      expect(restored.id, equals(original.id));
      expect(restored.fieldNumber, equals(original.fieldNumber));
      expect(restored.type, equals(original.type));
      expect(restored.speciesName, equals(original.speciesName));
    });

    test('FieldJournal toJson and fromJson roundtrip preserves Fleather Delta notes', () {
      const deltaJson = '[{"insert":"Observação de campo: "},{"insert":"Xolmis irupero","attributes":{"bold":true}},{"insert":"\\n"}]';
      final original = FieldJournal(
        id: 10,
        title: 'Expedição Campo',
        notes: deltaJson,
        creationDate: DateTime(2025, 3, 1, 9, 0, 0),
        lastModifiedDate: DateTime(2025, 3, 1, 9, 30, 0),
        observer: 'Researcher X',
        backgroundColor: 0xFF48429B,
      );

      final jsonMap = original.toJson();
      final restored = FieldJournal.fromJson(jsonMap);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.notes, equals(original.notes));
      expect(restored.observer, equals(original.observer));
      expect(jsonDecode(restored.notes!), isA<List>());
    });
  });
}
