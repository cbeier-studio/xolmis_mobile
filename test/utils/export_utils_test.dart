import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/utils/export_utils.dart';

void main() {
  group('Excel export cell value formatting', () {
    test('converts empty and whitespace values to null cell values', () {
      final rows = [
        ['Header1', 'Header2', 'Header3'],
        [null, '', '   '],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[1][0], isNull);
      expect(cellRows[1][1], isNull);
      expect(cellRows[1][2], isNull);
    });

    test('converts integer numbers and integer strings to IntCellValue', () {
      final rows = [
        [42, 0, -10, '100', '0', '-5'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(const IntCellValue(42)));
      expect(cellRows[0][1], equals(const IntCellValue(0)));
      expect(cellRows[0][2], equals(const IntCellValue(-10)));
      expect(cellRows[0][3], equals(const IntCellValue(100)));
      expect(cellRows[0][4], equals(const IntCellValue(0)));
      expect(cellRows[0][5], equals(const IntCellValue(-5)));
    });

    test('preserves strings with leading zeros as TextCellValue', () {
      final rows = [
        ['007', '01', '000'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(TextCellValue('007')));
      expect(cellRows[0][1], equals(TextCellValue('01')));
      expect(cellRows[0][2], equals(TextCellValue('000')));
    });

    test('preserves formatted decimal strings and non-integer strings as TextCellValue', () {
      final rows = [
        ['-23.5505', '-23,5505', 'Point count', '2025-01-15', '14:30:00'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(TextCellValue('-23.5505')));
      expect(cellRows[0][1], equals(TextCellValue('-23,5505')));
      expect(cellRows[0][2], equals(TextCellValue('Point count')));
      expect(cellRows[0][3], equals(TextCellValue('2025-01-15')));
      expect(cellRows[0][4], equals(TextCellValue('14:30:00')));
    });

    test('preserves double and boolean types', () {
      final rows = [
        [12.34, true, false],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(const DoubleCellValue(12.34)));
      expect(cellRows[0][1], equals(const BoolCellValue(true)));
      expect(cellRows[0][2], equals(const BoolCellValue(false)));
    });
  });
}
