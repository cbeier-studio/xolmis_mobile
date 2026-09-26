import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/data/daos/journal_dao.dart';
import 'package:xolmis/data/daos/tag_dao.dart';
import 'package:xolmis/main.dart';
import 'package:xolmis/main_screen.dart';
import 'package:xolmis/screens/inventory/inventories_screen.dart';
import 'package:xolmis/data/database/database_helper.dart';

import 'package:xolmis/providers/inventory_provider.dart';
import 'package:xolmis/providers/species_provider.dart';
import 'package:xolmis/providers/poi_provider.dart';
import 'package:xolmis/providers/tag_provider.dart';
import 'package:xolmis/providers/vegetation_provider.dart';
import 'package:xolmis/providers/weather_provider.dart';
import 'package:xolmis/providers/nest_provider.dart';
import 'package:xolmis/providers/nest_revision_provider.dart';
import 'package:xolmis/providers/egg_provider.dart';
import 'package:xolmis/providers/specimen_provider.dart';
import 'package:xolmis/providers/app_image_provider.dart';
import 'package:xolmis/providers/journal_provider.dart';

import 'package:xolmis/data/daos/egg_dao.dart';
import 'package:xolmis/data/daos/inventory_dao.dart';
import 'package:xolmis/data/daos/nest_dao.dart';
import 'package:xolmis/data/daos/nest_revision_dao.dart';
import 'package:xolmis/data/daos/poi_dao.dart';
import 'package:xolmis/data/daos/species_dao.dart';
import 'package:xolmis/data/daos/specimen_dao.dart';
import 'package:xolmis/data/daos/vegetation_dao.dart';
import 'package:xolmis/data/daos/weather_dao.dart';
import 'package:xolmis/data/daos/app_image_dao.dart';

import 'package:xolmis/services/location_service.dart';
import 'package:xolmis/services/location_service_impl.dart';
import 'package:xolmis/utils/themes.dart';

const MethodChannel _permissionHandlerChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'xolmis',
      packageName: 'org.xolmis.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionHandlerChannel, (call) async {
      switch (call.method) {
        case 'requestPermissions':
          return <int, int>{17: 1};
        case 'checkPermissionStatus':
        case 'checkServiceStatus':
          return 1;
        case 'shouldShowRequestPermissionRationale':
          return false;
        case 'openAppSettings':
          return true;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionHandlerChannel, null);
  });

  late DatabaseHelper databaseHelper;

  late InventoryDao inventoryDao;
  late SpeciesDao speciesDao;
  late PoiDao poiDao;
  late VegetationDao vegetationDao;
  late WeatherDao weatherDao;
  late NestDao nestDao;
  late NestRevisionDao nestRevisionDao;
  late EggDao eggDao;
  late SpecimenDao specimenDao;
  late AppImageDao appImageDao;
  late FieldJournalDao journalDao;
  late TagDao tagDao;

  late LocationService locationService;

  late InventoryProvider inventoryProvider;
  late SpeciesProvider speciesProvider;
  late PoiProvider poiProvider;
  late VegetationProvider vegetationProvider;
  late WeatherProvider weatherProvider;
  late NestProvider nestProvider;
  late NestRevisionProvider nestRevisionProvider;
  late EggProvider eggProvider;
  late SpecimenProvider specimenProvider;
  late AppImageProvider appImageProvider;
  late FieldJournalProvider journalProvider;
  late TagProvider tagProvider;

  late AppDependencies dependencies;

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.initDatabase();

    poiDao = PoiDao(databaseHelper);
    speciesDao = SpeciesDao(databaseHelper, poiDao);
    vegetationDao = VegetationDao(databaseHelper);
    weatherDao = WeatherDao(databaseHelper);
    inventoryDao = InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);
    eggDao = EggDao(databaseHelper);
    nestRevisionDao = NestRevisionDao(databaseHelper);
    nestDao = NestDao(databaseHelper, nestRevisionDao, eggDao);
    specimenDao = SpecimenDao(databaseHelper);
    appImageDao = AppImageDao(databaseHelper);
    journalDao = FieldJournalDao(databaseHelper);
    tagDao = TagDao(databaseHelper);

    locationService = GeolocatorServiceImpl();

    poiProvider = PoiProvider(poiDao);
    speciesProvider = SpeciesProvider(speciesDao);
    vegetationProvider = VegetationProvider(vegetationDao);
    weatherProvider = WeatherProvider(weatherDao);
    inventoryProvider = InventoryProvider(inventoryDao, speciesProvider, vegetationProvider, weatherProvider);
    eggProvider = EggProvider(eggDao);
    nestRevisionProvider = NestRevisionProvider(nestRevisionDao);
    nestProvider = NestProvider(nestDao);
    specimenProvider = SpecimenProvider(specimenDao);
    appImageProvider = AppImageProvider(appImageDao);
    journalProvider = FieldJournalProvider(journalDao);
    tagProvider = TagProvider(tagDao);


    dependencies = AppDependencies(
      inventoryDao: inventoryDao,
      speciesDao: speciesDao,
      poiDao: poiDao,
      vegetationDao: vegetationDao,
      weatherDao: weatherDao,
      nestDao: nestDao,
      nestRevisionDao: nestRevisionDao,
      eggDao: eggDao,
      specimenDao: specimenDao,
      appImageDao: appImageDao,
      journalDao: journalDao,
      tagDao: tagDao,

      locationService: locationService,

      inventoryProvider: inventoryProvider,
      speciesProvider: speciesProvider,
      poiProvider: poiProvider,
      vegetationProvider: vegetationProvider,
      weatherProvider: weatherProvider,
      nestProvider: nestProvider,
      nestRevisionProvider: nestRevisionProvider,
      eggProvider: eggProvider,
      specimenProvider: specimenProvider,
      appImageProvider: appImageProvider,
      journalProvider: journalProvider,
      tagProvider: tagProvider,
    );    
  });

  testWidgets('MyApp renders main navigation shell', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeModel(),
        child: MyApp(dependencies: dependencies),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(InventoriesScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
  });
}
