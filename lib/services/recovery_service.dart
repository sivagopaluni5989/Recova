import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../models/media_file.dart';

class RecoveryResult {
  final int recoveredFiles;
  final int photos;
  final int videos;
  final int documents;
  final int failedFiles;
  final List<String> errors;

  const RecoveryResult({
    required this.recoveredFiles,
    required this.photos,
    required this.videos,
    required this.documents,
    required this.failedFiles,
    required this.errors,
  });

  int get total => recoveredFiles;

  bool get isSuccess => recoveredFiles > 0 && failedFiles == 0;

  bool get hasFailures => failedFiles > 0;
}

class RecoveryService {
  static const String recoveredRoot =
      '/storage/emulated/0/Recova/Recovered';

  static const String recoveredImages =
      'Pictures/Recova/Recovered/Images/';

  static const String recoveredVideos =
      'Movies/Recova/Recovered/Videos/';

  static const String recoveredDocuments =
      '/storage/emulated/0/Recova/Recovered/Documents';

  /// Recover ONLY the files supplied in [files].
  ///
  /// IMPORTANT:
  /// This method never scans all media by itself.
  /// If one file is supplied, only one file is processed.
  Future<RecoveryResult> recoverFiles(
    List<MediaFile> files,
  ) async {
    int recovered = 0;
    int photos = 0;
    int videos = 0;
    int documents = 0;
    int failed = 0;

    final List<String> errors = <String>[];

    if (files.isEmpty) {
      return const RecoveryResult(
        recoveredFiles: 0,
        photos: 0,
        videos: 0,
        documents: 0,
        failedFiles: 0,
        errors: <String>[],
      );
    }

    await _createDirectories();

    // Process ONLY the supplied selection.
    for (final MediaFile media in files) {
      try {
        final bool success = await _recoverSingle(media);

        if (success) {
          recovered++;

          if (media.isImage) {
            photos++;
          } else if (media.isVideo) {
            videos++;
          } else if (media.isDocument) {
            documents++;
          }
        } else {
          failed++;

          errors.add(
            'Could not recover: ${media.fileName}',
          );
        }
      } catch (e) {
        failed++;

        errors.add(
          '${media.fileName}: $e',
        );
      }
    }

    return RecoveryResult(
      recoveredFiles: recovered,
      photos: photos,
      videos: videos,
      documents: documents,
      failedFiles: failed,
      errors: errors,
    );
  }

  /// Compatibility helper.
  Future<RecoveryResult> recoverSelected(
    List<MediaFile> selectedFiles,
  ) async {
    return recoverFiles(selectedFiles);
  }

  Future<bool> _recoverSingle(MediaFile media) async {
    final String sourcePath = media.filePath.trim();

    if (sourcePath.isEmpty) {
      return false;
    }

    File sourceFile = File(sourcePath);

    /*
     * MediaStore/PhotoManager assets can sometimes have a path that is
     * unavailable directly. If that happens, try obtaining the original
     * file through AssetEntity.
     */
    if (!await sourceFile.exists()) {
      if (media.asset != null) {
        try {
          final File? assetFile =
              await media.asset!.loadFile(isOrigin: true);

          if (assetFile != null && await assetFile.exists()) {
            sourceFile = assetFile;
          }
        } catch (_) {
          // Continue and return false below.
        }
      }
    }

    if (!await sourceFile.exists()) {
      return false;
    }

    final String fileName = _safeFileName(
      media.fileName.isNotEmpty
          ? media.fileName
          : _fileNameFromPath(sourceFile.path),
    );

    /*
     * IMAGE
     *
     * PhotoManager saves the file into MediaStore.
     * This is important because simply copying a file with dart:io does
     * not guarantee that Gallery will immediately index it.
     */
    if (media.isImage) {
      try {
        final AssetEntity entity =
            await PhotoManager.editor.saveImageWithPath(
          sourceFile.path,
          title: fileName,
          relativePath: recoveredImages,
        );

        return entity.id.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    /*
     * VIDEO
     */
    if (media.isVideo) {
      try {
        final AssetEntity entity =
            await PhotoManager.editor.saveVideo(
          sourceFile,
          title: fileName,
          relativePath: recoveredVideos,
        );

        return entity.id.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    /*
     * DOCUMENT
     *
     * Documents are not handled by PhotoManager.
     * Copy the actual file bytes to:
     *
     * /storage/emulated/0/Recova/Recovered/Documents/
     */
    if (media.isDocument) {
      try {
        final Directory directory =
            Directory(recoveredDocuments);

        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final String targetPath =
            await _uniqueTargetPath(
          directory.path,
          fileName,
        );

        await sourceFile.copy(targetPath);

        return await File(targetPath).exists();
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> _createDirectories() async {
    try {
      await Directory(recoveredRoot).create(
        recursive: true,
      );
    } catch (_) {}

    try {
      await Directory(recoveredDocuments).create(
        recursive: true,
      );
    } catch (_) {}
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

    final int dot = fileName.lastIndexOf('.');

    String base;
    String extension;

    if (dot > 0) {
      base = fileName.substring(0, dot);
      extension = fileName.substring(dot);
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

  String _safeFileName(String name) {
    String result = name;

    result = result.replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );

    result = result.trim();

    if (result.isEmpty) {
      result = 'Recovered_File';
    }

    return result;
  }

  String _fileNameFromPath(String path) {
    final String normalized =
        path.replaceAll('\\', '/');

    final int index =
        normalized.lastIndexOf('/');

    if (index == -1) {
      return normalized;
    }

    return normalized.substring(index + 1);
  }

  /// Returns the logical Recova recovery directory.
  String getRecoveredPath() {
    return recoveredRoot;
  }

  /// Check whether the Recova recovery directory exists.
  Future<bool> recoveredDirectoryExists() async {
    return Directory(recoveredRoot).exists();
  }

  /// Get all files currently stored in Recova/Recovered.
  Future<List<File>> getRecoveredFiles() async {
    final Directory root =
        Directory(recoveredRoot);

    if (!await root.exists()) {
      return <File>[];
    }

    final List<File> files = <File>[];

    try {
      await for (final FileSystemEntity entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (_) {}

    return files;
  }
}
