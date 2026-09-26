import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/database_helper.dart';
import 'utils.dart';

/// Deletes all files and directories inside the app temporary directory.
///
/// This helper is intended to remove transient files left by operations such as
/// imports, exports, or archive extraction. Failures while deleting individual
/// entries are logged with [debugPrint] and do not stop the remaining cleanup.
Future<void> clearAppTemporaryDirectory() async {
  debugPrint('[TEMP_CLEANUP] Starting temporary directory cleanup...');

  try {
    final tempDir = await getTemporaryDirectory();
    debugPrint('[TEMP_CLEANUP] Temporary directory: ${tempDir.path}');

    if (!await tempDir.exists()) {
      debugPrint('[TEMP_CLEANUP] Temporary directory does not exist. Nothing to clean.');
      return;
    }

    int deletedCount = 0;

    await for (final entity in tempDir.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
        deletedCount++;
        debugPrint('[TEMP_CLEANUP] Deleted: ${entity.path}');
      } catch (e) {
        debugPrint('[TEMP_CLEANUP] Failed to delete: ${entity.path}. Error: $e');
      }
    }

    debugPrint('[TEMP_CLEANUP] Cleanup finished. Deleted entities: $deletedCount');
  } catch (e) {
    debugPrint('[TEMP_CLEANUP] Failed to clear app temporary directory: $e');
  }
}

/// Creates a ZIP backup containing the SQLite database and all indexed images.
///
/// The backup is written to [filePath]. Besides the main
/// `xolmis_database.db` file, this method queries the `images` table and adds
/// every existing image file referenced by `imagePath` so that the backup keeps
/// database records and file-backed media in sync.
///
/// Returns `true` when the archive is created successfully and `false` if any
/// error occurs during the process.
Future<bool> backupDatabase(String filePath) async {
  try {
    final dbHelper = DatabaseHelper();
    final dbFile = path.join(await getDatabasesPath(), 'xolmis_database.db');

    final encoder = ZipFileEncoder();
    encoder.create(filePath);
    encoder.addFile(File(dbFile), path.basename(dbFile));

    final db = await dbHelper.database;
    final images = await db?.query('images', columns: ['imagePath']);

    if (images != null) {
      for (final imageRow in images) {
        final storedPath = imageRow['imagePath'] as String?;
        if (storedPath != null) {
          final absolutePath = await resolveImagePath(storedPath);
          if (await File(absolutePath).exists()) {
            encoder.addFile(File(absolutePath), path.basename(absolutePath));
          }
        }
      }
    }
    encoder.close();
    return true;
  } catch (e) {
    debugPrint('Error creating database backup: $e');
    return false;
  }
}

/// Restores a previously exported ZIP backup into local app storage.
///
/// The archive at [filePath] must contain `xolmis_database.db` plus any image
/// files referenced by the database. The current database is closed and removed
/// before extraction, then reopened after the restore completes.
///
/// After extraction, the method updates the `images` table so each stored
/// `imagePath` points to the restored file inside the application documents
/// directory.
///
/// Returns `true` if the database and related image files are restored
/// successfully; otherwise returns `false`.
Future<bool> restoreDatabase(String filePath) async {
  try {
    final dbHelper = DatabaseHelper();
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'xolmis_database.db');

    // Close the database before restoring
    await dbHelper.closeDatabase();

    // Deleta o arquivo do banco de dados existente se ele existir
    if (await File(dbFile).exists()) {
      await File(dbFile).delete();
    }

    final docsDir = await getApplicationDocumentsDirectory();

    bool success;
    try {
      // Executa a extração pesada em um isolate separado para não bloquear a UI
      success = await compute(_extractDatabaseAndImagesFromZip, {
        'zipFilePath': filePath,
        'dbFile': dbFile,
        'docsDirPath': docsDir.path,
      });
    } catch (e) {
      debugPrint('Isolate database extraction failed, falling back to main isolate: $e');
      success = _extractDatabaseAndImagesFromZip({
        'zipFilePath': filePath,
        'dbFile': dbFile,
        'docsDirPath': docsDir.path,
      });
    }

    if (!success) {
      debugPrint('Error: Failed to extract database from the backup file.');
      return false;
    }

    // Re-abre o banco de dados
    final db = await dbHelper.initDatabase();

    // Update image paths in the database to be relative (filename only)
    final images = await db.query('images', columns: ['id', 'imagePath']);
    if (images.isNotEmpty) {
      for (final imageRow in images) {
        final imageId = imageRow['id'] as int?;
        final currentPath = imageRow['imagePath'] as String?;
        if (imageId != null && currentPath != null) {
          final relativePath = path.basename(currentPath);
          await db.update('images', {'imagePath': relativePath}, where: 'id = ?', whereArgs: [imageId]);
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Error restoring database: $e');
    return false;
  }
}

Future<int> restoreImagesOnlyFromBackup(String zipFilePath) async {
  try {
    final docsDir = await getApplicationDocumentsDirectory();

    int restoredImagesCount;
    try {
      // Executa a extração pesada em um isolate separado para não bloquear a UI
      restoredImagesCount = await compute(_extractImagesFromZip, {
        'zipFilePath': zipFilePath,
        'docsDirPath': docsDir.path,
      });
    } catch (e) {
      debugPrint('Isolate images extraction failed, falling back to main isolate: $e');
      restoredImagesCount = _extractImagesFromZip({
        'zipFilePath': zipFilePath,
        'docsDirPath': docsDir.path,
      });
    }

    debugPrint('[IMAGE_RESTORE] Completed. Restored images: $restoredImagesCount');
    return restoredImagesCount;
  } catch (e) {
    debugPrint('[IMAGE_RESTORE] Error restoring images only: $e');
    return 0;
  }
}

/// Helper executado em isolate para extrair imagens e banco de dados.
bool _extractDatabaseAndImagesFromZip(Map<String, String> args) {
  final zipFilePath = args['zipFilePath']!;
  final dbFile = args['dbFile']!;
  final docsDirPath = args['docsDirPath']!;

  final inputStream = InputFileStream(zipFilePath);
  final archive = ZipDecoder().decodeStream(inputStream);

  final dbFileInArchive = archive.findFile('xolmis_database.db');
  if (dbFileInArchive == null) {
    inputStream.close();
    return false;
  }

  for (final file in archive) {
    final filename = file.name;
    if (filename == 'xolmis_database.db') {
      final outputStream = OutputFileStream(dbFile);
      outputStream.writeBytes(file.content);
      outputStream.close();
    } else if (file.isFile) {
      // Usa path.basename para evitar problemas com caminhos relativos no ZIP
      final imageOutputPath = path.join(docsDirPath, path.basename(filename));
      final imageOutputFile = File(imageOutputPath);
      imageOutputFile.createSync(recursive: true);
      imageOutputFile.writeAsBytesSync(file.content as List<int>);
    }
  }
  inputStream.close();
  return true;
}

/// Helper executado em isolate para extrair apenas imagens.
int _extractImagesFromZip(Map<String, String> args) {
  final zipFilePath = args['zipFilePath']!;
  final docsDirPath = args['docsDirPath']!;
  int restoredCount = 0;

  final inputStream = InputFileStream(zipFilePath);
  final archive = ZipDecoder().decodeStream(inputStream);

  for (final file in archive) {
    if (file.isFile && file.name != 'xolmis_database.db') {
      final filename = path.basename(file.name);
      final outputPath = path.join(docsDirPath, filename);
      final outputFile = File(outputPath);

      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(file.content as List<int>);
      restoredCount++;
    }
  }
  inputStream.close();
  return restoredCount;
}
