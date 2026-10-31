import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/generated/l10n.dart';
import 'package:xolmis/widgets/export_options_bottom_sheet.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: [
      S.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders default prefix and formats correctly', (tester) async {
    ExportOptionsResult? result;

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showExportOptionsBottomSheet(
                  context: context,
                  defaultPrefix: 'test_prefix',
                  title: 'Export test',
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify title and prefix field
    expect(find.text('Export test'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('test_prefix'), findsAtLeastNWidgets(1));

    // Verify format chips
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
    expect(find.text('KML'), findsOneWidget);

    // Tap Export
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.prefix, 'test_prefix');
    expect(result!.formats, containsAll([
      ExportFormat.csv,
      ExportFormat.excel,
      ExportFormat.json,
      ExportFormat.kml,
    ]));
  });

  testWidgets('disables export button when all formats are deselected', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                await showExportOptionsBottomSheet(
                  context: context,
                  defaultPrefix: 'inventories',
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Deselect all 4 formats
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KML'));
    await tester.pumpAndSettle();

    final s = S.of(tester.element(find.byType(TextField)));

    // Verify warning is displayed
    expect(find.text(s.selectAtLeastOneFormat), findsOneWidget);

    // Verify FilledButton is disabled
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Export'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('disables export button when prefix is empty and validates', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                await showExportOptionsBottomSheet(
                  context: context,
                  defaultPrefix: 'inventories',
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Clear prefix
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    final s = S.of(tester.element(find.byType(TextField)));

    // Verify validation error
    expect(find.text(s.fileNamePrefixRequired), findsOneWidget);

    // Verify FilledButton is disabled
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Export'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('restores previously saved formats from SharedPreferences', (tester) async {
    SharedPreferences.setMockInitialValues({
      kExportSelectedFormatsPreferenceKey: ['csv', 'json'],
    });

    ExportOptionsResult? result;

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showExportOptionsBottomSheet(
                  context: context,
                  defaultPrefix: 'saved_test',
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Export with restored formats
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.formats, {ExportFormat.csv, ExportFormat.json});
  });

  testWidgets('renders custom availableFormats for Field Journal export', (tester) async {
    ExportOptionsResult? result;

    await tester.pumpWidget(
      _buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showExportOptionsBottomSheet(
                  context: context,
                  defaultPrefix: 'selected_journals',
                  title: 'Export journals',
                  availableFormats: const [
                    ExportFormat.txt,
                    ExportFormat.markdown,
                    ExportFormat.word,
                    ExportFormat.json,
                    ExportFormat.pdf,
                  ],
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Export journals'), findsOneWidget);
    expect(find.text('Plain Text'), findsOneWidget);
    expect(find.text('Markdown'), findsOneWidget);
    expect(find.text('Word'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.prefix, 'selected_journals');
    expect(result!.formats, {
      ExportFormat.txt,
      ExportFormat.markdown,
      ExportFormat.word,
      ExportFormat.json,
      ExportFormat.pdf,
    });
  });
}
