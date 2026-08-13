import 'dart:io';

import '../models/media_file.dart';

class RecoverableMediaService {
  /*
   * IMPORTANT:
   *
   * This service only reports files that Android currently exposes to
   * the application through accessible filesystem locations.
   *
   * It does NOT claim that every file deleted from Gallery can be found.
   *
   * True MediaStore Trash/IS_TRASHED restoration requires an Android
   * native MediaStore implementation. We will add that separately.
   */

  static const String storageRoot =
      '/storage/emulated/0';

  static const List<String> candidateDirectories = [
    '/storage/emulated/0/.Trash',
    '/storage/emulated/0/.trash',
    '/storage/emulated/0/Trash',
    '/storage/emulated/0/TrashBin',
    '/storage/emulated/0/Recycle',
    '/storage/emulated/0/RecycleBin',
    '/storage/emulated/0/DCIM/.Trash',
    '/storage/emulated/0/Pictures/.Trash',
    '/storage/emulated/0/Movies/.Trash',
    '/storage/emulated/0/Download/.Trash',
    '/storage/emulated/0/Download/.trash',
    '/storage/emulated/0/Android/media',
  ];

  static const Set<String> imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'heic',
    'heif',
    'tif',
    'tiff',
    'avif',
  };

  static const Set<String> videoExtensions = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    '3gp',
    '3gpp',
    'webm',
    'flv',
    'wmv',
    'm4v',
    'ts',
  };

  static const Set<String> documentExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'rtf',
    'odt',
    'ods',
    'odp',
    'epub',
    'html',
    'htm',
    'xml',
    'json',
    'log',
    'md',
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
  };

  Future<List<MediaFile>> scan({
    Function(
      double progress,
      String folder,
      int current,
      int total,
      int images,
      int videos,
      int documents,
    )? onProgress,
  }) async {
    final List<MediaFile> results =
        <MediaFile>[];

    int imageCount = 0;
    int videoCount = 0;
    int documentCount = 0;

    /*
     * First check known trash/recycle locations.
     */
    final List<Directory> roots =
        <Directory>[];

    for (final String path
        in candidateDirectories) {
      final Directory directory =
          Directory(path);

      try {
        if (await directory.exists()) {
          roots.add(directory);
        }
      } catch (_) {}
    }

    /*
     * Remove duplicate directory paths.
     */
    final Map<String, Directory> uniqueRoots =
        <String, Directory>{};

    for (final Directory directory in roots) {
      uniqueRoots[
          _normalizePath(directory.path).toLowerCase()] =
          directory;
    }

    final List<Directory> actualRoots =
        uniqueRoots.values.toList();

    if (actualRoots.isEmpty) {
      onProgress?.call(
        1.0,
        'No accessible Trash/Recycle folder found',
        0,
        0,
        0,
        0,
        0,
      );

      return results;
    }

    final Set<String> seen =
        <String>{};

    int current = 0;

    for (final Directory root
        in actualRoots) {
      current++;

      await _scanDirectory(
        root,
        results,
        seen,
        onFileFound: (
          MediaFile media,
        ) {
          if (media.isImage) {
            imageCount++;
          } else if (media.isVideo) {
            videoCount++;
          } else if (media.isDocument) {
            documentCount++;
          }

          onProgress?.call(
            current / actualRoots.length,
            root.path,
            current,
            actualRoots.length,
            imageCount,
            videoCount,
            documentCount,
          );
        },
      );
    }

    return results;
  }

  /// Alias for callers that prefer recoverableScan().
  Future<List<MediaFile>> recoverableScan({
    Function(
      double progress,
      String folder,
      int current,
      int total,
      int images,
      int videos,
      int documents,
    )? onProgress,
  }) {
    return scan(
      onProgress: onProgress,
    );
  }

  Future<void> _scanDirectory(
    Directory directory,
    List<MediaFile> results,
    Set<String> seen, {
    required Function(MediaFile file)
        onFileFound,
  }) async {
    try {
      await for (final FileSystemEntity entity
          in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        final MediaFile? media =
            await _createMediaFile(entity);

        if (media == null) {
          continue;
        }

        final String key =
            _normalizePath(
          media.filePath,
        ).toLowerCase();

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);

        results.add(media);

        onFileFound(media);
      }
    } catch (_) {
      /*
       * Some Android directories can be visible but not readable.
       * Continue without crashing the entire recovery scan.
       */
    }
  }

  Future<MediaFile?> _createMediaFile(
    File file,
  ) async {
    try {
      if (!await file.exists()) {
        return null;
      }

      final int size =
          await file.length();

      if (size <= 0) {
        return null;
      }

      final String path =
          _normalizePath(file.path);

      final String fileName =
          _fileNameFromPath(path);

      final String extension =
          _extension(fileName);

      MediaType? type;

      if (imageExtensions.contains(
        extension,
      )) {
        type = MediaType.image;
      } else if (videoExtensions.contains(
        extension,
      )) {
        type = MediaType.video;
      } else if (documentExtensions.contains(
        extension,
      )) {
        type = MediaType.document;
      }

      if (type == null) {
        return null;
      }

      if (!await _isReadable(file)) {
        return null;
      }

      return MediaFile(
        asset: null,
        filePath: path,
        fileName: fileName,
        mediaType: type,
        source: 'Trash/Recycle',
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isReadable(
    File file,
  ) async {
    RandomAccessFile? handle;

    try {
      handle = await file.open(
        mode: FileMode.read,
      );

      final List<int> header =
          await handle.read(16);

      return header.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      try {
        await handle?.close();
      } catch (_) {}
    }
  }

  String _normalizePath(
    String path,
  ) {
    return path.replaceAll(
      '\\',
      '/',
    );
  }

  String _fileNameFromPath(
    String path,
  ) {
    final String normalized =
        _normalizePath(path);

    final int index =
        normalized.lastIndexOf('/');

    if (index == -1) {
      return normalized;
    }

    return normalized.substring(
      index + 1,
    );
  }

  String _extension(
    String fileName,
  ) {
    final int index =
        fileName.lastIndexOf('.');

    if (index <= 0 ||
        index >= fileName.length - 1) {
      return '';
    }

    return fileName
        .substring(index + 1)
        .toLowerCase();
  }
}
