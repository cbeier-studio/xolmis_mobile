import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import '../data/database/database_helper.dart';

/// Model representing the update result.
class UpdateSummary {
  final int year;
  final int updatesCount; // Number of pairs old/new in JSON
  final int speciesUpdated;
  final int nestsUpdated;
  final int specimensUpdated;

  UpdateSummary({
    required this.year,
    required this.updatesCount,
    this.speciesUpdated = 0,
    this.nestsUpdated = 0,
    this.specimensUpdated = 0,
  });

  @override
  String toString() {
    return 'Resumo da Atualização ($year): $updatesCount pares de nomes processados. '
        'Espécies atualizadas: $speciesUpdated, Ninhos: $nestsUpdated, Espécimes: $specimensUpdated.';
  }
}

/// Service to update species names in the database from a JSON file.
class SpeciesUpdateService {
  final DatabaseHelper _dbHelper;

  SpeciesUpdateService({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  /// Apply species updates for a given year.
  ///
  /// Load a JSON file from 'assets/updates/species_update_[year].json',
  /// and updates the tables 'species', 'nests' and 'specimens' within a transaction.
  Future<UpdateSummary> applySpeciesUpdates(int year) async {
    final db = await _dbHelper.database;
    if (db == null) {
      throw Exception('Database connection is not available.');
    }

    // Load and decode the JSON file
    final List<Map<String, dynamic>> updates = await _loadUpdatesFromFile(year);

    if (updates.isEmpty) {
      debugPrint('Nenhuma atualização de espécie encontrada para o ano $year.');
      return UpdateSummary(year: year, updatesCount: 0);
    }

    int totalSpeciesUpdated = 0;
    int totalNestsUpdated = 0;
    int totalSpecimensUpdated = 0;

    try {
      // Executa todas as operações em uma única transação para garantir atomicidade.
      // Se qualquer atualização falhar, todas serão revertidas.
      await db.transaction((txn) async {
        for (final update in updates) {
          final oldName = update['oldName'];
          final newName = update['newName'];

          if (oldName == null || newName == null) {
            debugPrint('Aviso: Registro de atualização inválido ignorado: $update');
            continue;
          }

          // 1. Atualiza a tabela 'species'
          final speciesCount = await txn.update(
            'species',
            {'name': newName},
            where: 'name = ?',
            whereArgs: [oldName],
          );
          totalSpeciesUpdated += speciesCount;

          // 2. Atualiza a tabela 'nests'
          final nestsCount = await txn.update(
            'nests',
            {'speciesName': newName},
            where: 'speciesName = ?',
            whereArgs: [oldName],
          );
          totalNestsUpdated += nestsCount;

          // 3. Atualiza a tabela 'specimens'
          final specimensCount = await txn.update(
            'specimens',
            {'speciesName': newName},
            where: 'speciesName = ?',
            whereArgs: [oldName],
          );
          totalSpecimensUpdated += specimensCount;

          if (speciesCount > 0 || nestsCount > 0 || specimensCount > 0) {
            debugPrint('"${oldName}" -> "${newName}": (species: $speciesCount, nests: $nestsCount, specimens: $specimensCount)');
          }
        }
      });

      final summary = UpdateSummary(
        year: year,
        updatesCount: updates.length,
        speciesUpdated: totalSpeciesUpdated,
        nestsUpdated: totalNestsUpdated,
        specimensUpdated: totalSpecimensUpdated,
      );

      debugPrint(summary.toString());
      return summary;

    } on DatabaseException catch (e, s) {
      debugPrint('Database error during species update: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Falha ao atualizar nomes de espécies devido a um erro no banco de dados.');
    } catch (e) {
      debugPrint('Unexpected error during species update: $e');
      rethrow;
    }
  }

  /// Load species updates from a JSON file.
  Future<List<Map<String, dynamic>>> _loadUpdatesFromFile(int year) async {
    try {
      final String filePath = 'assets/updates/species_update_$year.json';
      final String jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // É normal um arquivo para um certo ano não existir. Trata como uma lista vazia.
      debugPrint('Arquivo de atualização para o ano $year não encontrado ou inválido: $e');
      return [];
    }
  }
}
