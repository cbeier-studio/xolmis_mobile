import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/widgets/timer_progress_indicator.dart';

Widget _wrapWithTheme({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  group('TimerProgressIndicator', () {
    testWidgets('uses the light-theme colors when visible and active', (tester) async {
      final inventory = Inventory(
        id: 'inv-1',
        type: InventoryType.invCasual,
        duration: 10,
        isPaused: false,
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          brightness: Brightness.light,
          child: TimerProgressIndicator(
            value: 0.25,
            isVisible: true,
            inventory: inventory,
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(indicator.backgroundColor, equals(Colors.grey[200]));
      expect(indicator.valueColor!.value, equals(Colors.deepPurple));
    });

    testWidgets('uses paused and dark-theme colors when inventory is paused', (tester) async {
      final inventory = Inventory(
        id: 'inv-2',
        type: InventoryType.invCasual,
        duration: 10,
        isPaused: true,
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          brightness: Brightness.dark,
          child: TimerProgressIndicator(
            value: 0.5,
            isVisible: true,
            inventory: inventory,
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(indicator.backgroundColor, equals(Colors.black));
      expect(indicator.valueColor!.value, equals(Colors.amber));
    });

    testWidgets('hides the background when not visible', (tester) async {
      final inventory = Inventory(
        id: 'inv-3',
        type: InventoryType.invCasual,
        duration: 10,
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          brightness: Brightness.light,
          child: TimerProgressIndicator(
            value: null,
            isVisible: false,
            inventory: inventory,
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(indicator.backgroundColor, isNull);
      expect(indicator.valueColor!.value, equals(Colors.deepPurple));
    });
  });
}


