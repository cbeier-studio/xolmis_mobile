// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xolmis/main.dart';
import 'package:xolmis/screens/utils.dart';
import 'package:xolmis/data/database/repositories/inventory_repository.dart';
import 'package:xolmis/data/database/repositories/species_repository.dart';
import 'package:xolmis/data/database/repositories/poi_repository.dart';
import 'package:xolmis/data/database/repositories/vegetation_repository.dart';
import 'package:xolmis/data/database/repositories/weather_repository.dart';
import 'package:xolmis/data/database/repositories/nest_repository.dart';
import 'package:xolmis/data/database/repositories/nest_revision_repository.dart';
import 'package:xolmis/data/database/repositories/egg_repository.dart';
import 'package:xolmis/data/database/repositories/specimen_repository.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final themeMode = await getThemeMode();
    await tester.pumpWidget(
        MyApp(
          themeMode: themeMode,
          inventoryRepository: inventoryRepository,
          speciesRepository: speciesRepository,
          poiRepository: poiRepository,
          vegetationRepository: vegetationRepository,
          weatherRepository: weatherRepository,
          nestRepository: nestRepository,
          nestRevisionRepository: nestRevisionRepository,
          eggRepository: eggRepository,
          specimenRepository: specimenRepository,
        )
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
