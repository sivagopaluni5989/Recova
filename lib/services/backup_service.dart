import 'dart:io';

import '../models/backup_file.dart';
import '../models/media_file.dart';

class BackupService {
  static const String backupRoot =
      '/storage/emulated/0/Recova/Backups';

  static const String recoveredRoot =
      '/storage/emulated/0/Recova/Recovered';

  /// Create the Recova backup directory structure.
  Future<void> initializeBackupDirectories() async {
    await Directory(backupRoot).create(
      recursive: true,
    );

    await Directory(recoveredRoot).create(
      recursive: true,
    );
  }

  /// Create a real file backup.
  ///
  /// If [files] is supplied, ONLY those MediaFile objects are copied.
  ///
  /// If [files] is omitted, the current Recova/Recovered folder
  /// is backed up.
  Future<dynamic> createBackup([
    List<MediaFile> files =
        const <MediaFile>[],
  ]) async {
    await initializeBackupDirectories();

    final DateTime now = DateTime.now();

    final String timestamp =
        '${now.year}-'
        '${_twoDigits(now.month)}-'
        '${_twoDigits(now.day)}_'
        '${_twoDigits(now.hour)}'
        '${_twoDigits(now.minute)}'
        '${_twoDigits(now.second)}';

    final Directory backupDirectory =
        Directory(
      '$backupRoot/Backup_$timestamp',
    );

    final Directory imagesDirectory =
        Directory(
      '${backupDirectory.path}/Images',
    );

    final Directory videosDirectory =
        Directory(
      '${backupDirectory.path}/Videos',
    );

    final Directory documentsDirectory =
        Directory(
      '${backupDirectory.path}/Documents',
    );

    await imagesDirectory.create(
      recursive: true,
    );

    await videosDirectory.create(
      recursive: true,
    );

    await documentsDirectory.create(
      recursive: true,
    );

    int copied = 0;
    int failed = 0;

    /*
     * If caller supplied selected files,
     * back up ONLY those files.
     */
    if (files.isNotEmpty) {
      for (final MediaFile media in files) {
        try {
          final String source =
              media.filePath;

          final File sourceFile =
              File(source);

          if (!await sourceFile.exists()) {
            failed++;
            continue;
          }

          Directory destinationDirectory;

          if (media.isImage) {
            destinationDirectory =
                imagesDirectory;
          } else if (media.isVideo) {
            destinationDirectory =
                videosDirectory;
          } else {
            destinationDirectory =
                documentsDirectory;
          }

          final String targetPath =
              await _uniqueTargetPath(
            destinationDirectory.path,
            _safeFileName(
              media.fileName,
            ),
          );

          await sourceFile.copy(
            targetPath,
          );

          if (await File(targetPath).exists()) {
            copied++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
    } else {
      /*
       * No explicit selection:
       * back up everything currently stored under
       * Recova/Recovered.
       */
      final Directory recoveredDirectory =
          Directory(recoveredRoot);

      if (await recoveredDirectory.exists()) {
        await for (
          final FileSystemEntity entity
              in recoveredDirectory.list(
            recursive: true,
            followLinks: false,
          )
        ) {
          if (entity is! File) {
            continue;
          }

          try {
            final String extension =
                _extension(entity.path);

            final Directory destination;

            if (_imageExtensions
                .contains(extension)) {
              destination =
                  imagesDirectory;
            } else if (_videoExtensions
                .contains(extension)) {
              destination =
                  videosDirectory;
            } else {
              destination =
                  documentsDirectory;
            }

            final String target =
                await _uniqueTargetPath(
              destination.path,
              _safeFileName(
                _fileName(entity.path),
              ),
            );

            await entity.copy(target);

            if (await File(target).exists()) {
              copied++;
            } else {
              failed++;
            }
          } catch (_) {
            failed++;
          }
        }
      }
    }

    return <String, dynamic>{
      'backupPath':
          backupDirectory.path,
      'copied':
          copied,
      'failed':
          failed,
    };
  }

  /// Get all backup files from Recova/Backups.
  Future<List<BackupFile>> getBackupFiles() async {
    await initializeBackupDirectories();

    final Directory root =
        Directory(backupRoot);

    final List<BackupFile> result =
        <BackupFile>[];

    if (!await root.exists()) {
      return result;
    }

    try {
      await for (
        final FileSystemEntity entity
            in root.list(
          recursive: true,
          followLinks: false,
        )
      ) {
        if (entity is! File) {
          continue;
        }

        try {
          final int size =
              await entity.length();

          result.add(
            BackupFile(
              name: _fileName(
                entity.path,
              ),
              path: entity.path,
              size: size,
            ),
          );
        } catch (_) {}
      }
    } catch (_) {}

    result.sort(
      (BackupFile a, BackupFile b) =>
          a.name.compareTo(b.name),
    );

    return result;
  }
/// Restore a backup file.
  ///
  /// Accepts either:
  ///   restoreBackup(BackupFile)
  ///
  /// or:
  ///   restoreBackup('/path/to/file')
  Future<dynamic> restoreBackup(
    dynamic backup,
  ) async {
    String sourcePath = '';

    if (backup is BackupFile) {
      sourcePath = backup.path;
    } else if (backup is String) {
      sourcePath = backup;
    }

    if (sourcePath.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'error': 'Invalid backup file.',
      };
    }

    final File sourceFile =
        File(sourcePath);

    if (!await sourceFile.exists()) {
      return <String, dynamic>{
        'success': false,
        'error': 'Backup file does not exist.',
      };
    }

    final String extension =
        _extension(sourceFile.path);

    /*
     * Images/videos should ultimately be visible
     * to Gallery. For this service, backups are restored
     * into Recova/Recovered. MediaStore indexing can then
     * be handled by the recovery/media layer.
     */
    Directory destinationDirectory;

    if (_imageExtensions
        .contains(extension)) {
      destinationDirectory =
          Directory(
        '$recoveredRoot/Images',
      );
    } else if (_videoExtensions
        .contains(extension)) {
      destinationDirectory =
          Directory(
        '$recoveredRoot/Videos',
      );
    } else {
      destinationDirectory =
          Directory(
        '$recoveredRoot/Documents',
      );
    }

    await destinationDirectory.create(
      recursive: true,
    );

    final String target =
        await _uniqueTargetPath(
      destinationDirectory.path,
      _safeFileName(
        _fileName(sourceFile.path),
      ),
    );

    try {
      await sourceFile.copy(target);

      return <String, dynamic>{
        'success': await File(target).exists(),
        'path': target,
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': '$e',
      };
    }
  }

  /// Restore all files from a backup folder.
  Future<dynamic> restoreBackupFolder(
    String backupFolder,
  ) async {
    final Directory sourceDirectory =
        Directory(backupFolder);

    if (!await sourceDirectory.exists()) {
      return <String, dynamic>{
        'success': false,
        'copied': 0,
        'failed': 0,
      };
    }

    int copied = 0;
    int failed = 0;

    await for (
      final FileSystemEntity entity
          in sourceDirectory.list(
        recursive: true,
        followLinks: false,
      )
    ) {
      if (entity is! File) {
        continue;
      }

      final dynamic result =
          await restoreBackup(
        entity.path,
      );

      if (result is Map &&
          result['success'] == true) {
        copied++;
      } else {
        failed++;
      }
    }

    return <String, dynamic>{
      'success': copied > 0,
      'copied': copied,
      'failed': failed,
    };
  }

  /// Delete one backup file.
  Future<bool> deleteFile(
    String path,
  ) async {
    try {
      final File file = File(path);

      if (!await file.exists()) {
        return false;
      }

      await file.delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete an entire backup folder.
  Future<bool> deleteBackupFolder(
    String path,
  ) async {
    try {
      final Directory directory =
          Directory(path);

      if (!await directory.exists()) {
        return false;
      }

      await directory.delete(
        recursive: true,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _uniqueTargetPath(
    String directory,
    String fileName,
  ) async {
    String target =
        '$directory/$fileName';

    if (!await File(target).exists()) {
      return target;
    }

    final int dot =
        fileName.lastIndexOf('.');

    String base;
    String extension;

    if (dot > 0) {
      base =
          fileName.substring(0, dot);
      extension =
          fileName.substring(dot);
    } else {
      base = fileName;
      extension = '';
    }

    int counter = 1;

    while (await File(target).exists()) {
      target =
          '$directory/${base}_$counter$extension';

      counter++;
    }

    return target;
  }

  String _safeFileName(
    String name,
  ) {
    String result =
        name.replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );

    result = result.trim();

    if (result.isEmpty) {
      result = 'Backup_File';
    }

    return result;
  }

  String _fileName(String path) {
    final String normalized =
        path.replaceAll('\\', '/');

    final int index =
        normalized.lastIndexOf('/');

    if (index == -1) {
      return normalized;
    }

    return normalized.substring(
      index + 1,
    );
  }

  String _extension(String path) {
    final String name =
        _fileName(path);

    final int index =
        name.lastIndexOf('.');

    if (index == -1) {
      return '';
    }

    return name
        .substring(index)
        .toLowerCase();
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  static const Set<String>
      _imageExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
    '.heif',
  };

  static const Set<String>
      _videoExtensions = <String>{
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.3gp',
    '.m4v',
    '.webm',
    '.flv',
  };
}
