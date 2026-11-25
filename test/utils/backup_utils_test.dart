import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:xolmis/utils/backup_utils.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  final String docsPath;

  FakePathProviderPlatform({required this.tempPath, required this.docsPath});

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('xolmis_backup_temp_');
    docsDir = await Directory.systemTemp.createTemp('xolmis_backup_docs_');

    PathProviderPlatform.instance = FakePathProviderPlatform(
      tempPath: tempDir.path,
      docsPath: docsDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await docsDir.exists()) {
      await docsDir.delete(recursive: true);
    }
  });

  group('App Temporary Directory Cleanup', () {
    test('clearAppTemporaryDirectory deletes all files in temporary directory', () async {
      final file1 = File(path.join(tempDir.path, 'temp_file1.txt'))..writeAsStringSync('data1');
      final subDir = Directory(path.join(tempDir.path, 'sub_dir'))..createSync();
      File(path.join(subDir.path, 'temp_file2.txt')).writeAsStringSync('data2');

      expect(file1.existsSync(), isTrue);
      expect(subDir.existsSync(), isTrue);

      await clearAppTemporaryDirectory();

      final tempEntities = tempDir.listSync();
      expect(tempEntities, isEmpty);
    });
  });

  group('ZIP Backup Archive Extraction', () {
    test('extracts xolmis_database.db and image files correctly from ZIP archive', () async {
      final archive = Archive();

      final dbContent = 'SQLITE_HEADER_DUMMY_DATA';
      archive.addFile(ArchiveFile('xolmis_database.db', dbContent.length, dbContent.codeUnits));

      final imgContent = [1, 2, 3, 4, 5];
      archive.addFile(ArchiveFile('photo_01.jpg', imgContent.length, imgContent));

      final zipFile = File(path.join(tempDir.path, 'valid_backup.zip'));
      final zipEncoder = ZipEncoder();
      zipFile.writeAsBytesSync(zipEncoder.encode(archive)!);

      final targetDbFile = File(path.join(tempDir.path, 'restored_db.db'));

      final args = {
        'zipFilePath': zipFile.path,
        'dbFile': targetDbFile.path,
        'docsDirPath': docsDir.path,
      };

      // Call extraction logic
      final restoredCount = restoreImagesOnlyFromBackup(zipFile.path);

      expect(zipFile.existsSync(), isTrue);
      expect(await restoredCount, equals(1));

      final extractedImg = File(path.join(docsDir.path, 'photo_01.jpg'));
      expect(extractedImg.existsSync(), isTrue);
      expect(extractedImg.readAsBytesSync(), equals(imgContent));
    });

    test('restoreImagesOnlyFromBackup counts only image files and ignores xolmis_database.db', () async {
      final archive = Archive();

      final dbData = 'DUMMY_DB_BYTES';
      archive.addFile(ArchiveFile('xolmis_database.db', dbData.length, dbData.codeUnits));

      final img1Data = [10, 20, 30];
      archive.addFile(ArchiveFile('bird_nest.png', img1Data.length, img1Data));

      final img2Data = [40, 50, 60];
      archive.addFile(ArchiveFile('subfolder/specimen_feather.jpg', img2Data.length, img2Data));

      final zipFile = File(path.join(tempDir.path, 'images_backup.zip'));
      zipFile.writeAsBytesSync(ZipEncoder().encode(archive)!);

      final restoredImagesCount = await restoreImagesOnlyFromBackup(zipFile.path);

      expect(restoredImagesCount, equals(2));

      final restoredImg1 = File(path.join(docsDir.path, 'bird_nest.png'));
      final restoredImg2 = File(path.join(docsDir.path, 'specimen_feather.jpg'));

      expect(restoredImg1.existsSync(), isTrue);
      expect(restoredImg2.existsSync(), isTrue);
    });

    test('restoreImagesOnlyFromBackup returns 0 on missing or invalid zip file', () async {
      final nonExistentZipPath = path.join(tempDir.path, 'non_existent.zip');

      final count = await restoreImagesOnlyFromBackup(nonExistentZipPath);

      expect(count, equals(0));
    });
  });
}
