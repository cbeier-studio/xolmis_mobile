import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/database_helper.dart';

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
        final imagePath = imageRow['imagePath'] as String?;
        if (imagePath != null && await File(imagePath).exists()) {
          encoder.addFile(File(imagePath), path.basename(imagePath));
        }
      }
    }
    encoder.close();
    return true;
  } catch (e) {
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

    // Delete the existing database file if it exists
    if (await File(dbFile).exists()) {
      await File(dbFile).delete();
    }

    final inputStream = InputFileStream(filePath);
    final archive = ZipDecoder().decodeStream(inputStream);

    // Check if the database file exists in the archive
    final dbFileInArchive = archive.findFile('xolmis_database.db');
    if (dbFileInArchive == null) {
      debugPrint('Error: xolmis_database.db not found in the backup file.');
      return false;
    }

    for (final file in archive) {
      final filename = file.name;
      if (filename == 'xolmis_database.db') {
        final outputStream = OutputFileStream(dbFile);
        outputStream.writeBytes(file.content);
        outputStream.close();
      } else {
        final imageDirectory = await getApplicationDocumentsDirectory();
        final imageOutputPath = path.join(imageDirectory.path, filename);
        final imageOutputFile = File(imageOutputPath);
        await imageOutputFile.create(recursive: true);
        await imageOutputFile.writeAsBytes(file.content);
      }
    }
    // Re-open the database
    final db = await dbHelper.initDatabase();

    // Update image paths in the database
    final images = await db.query('images', columns: ['id', 'imagePath']);
    if (images.isNotEmpty) {
      final imageDirectory = await getApplicationDocumentsDirectory();
      for (final imageRow in images) {
        final imageId = imageRow['id'] as int?;
        final oldImagePath = imageRow['imagePath'] as String?;
        if (imageId != null && oldImagePath != null) {
          final imageName = path.basename(oldImagePath);
          final newImagePath = path.join(imageDirectory.path, imageName);
          if (await File(newImagePath).exists()) {
            await db.update('images', {'imagePath': newImagePath}, where: 'id = ?', whereArgs: [imageId]);
          }
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Error restoring database: $e');
    return false;
  }
}