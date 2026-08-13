import 'dart:io';

import '../models/media_file.dart';

class DeepScanService {
  static const String storageRoot = '/storage/emulated/0';

  static const Set<String> excludedDirectoryNames = {
    '/storage/emulated/0/Android/data',
    '/storage/emulated/0/Android/obb',
  };

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
    final List<MediaFile> results = [];

    int imageCount = 0;
    int videoCount = 0;
    int documentCount = 0;

    final Directory root = Directory(storageRoot);

    if (!await root.exists()) {
      return results;
    }

    final List<Directory> directories = <Directory>[];

    await _collectDirectories(
      root,
      directories,
    );

    if (directories.isEmpty) {
      return results;
    }

    final int totalDirectories = directories.length;

    int currentDirectory = 0;

    final Set<String> seenPaths = <String>{};

    for (final Directory directory in directories) {
      currentDirectory++;

      if (_isExcludedDirectory(directory.path)) {
        continue;
      }

      try {
        await for (final FileSystemEntity entity
            in directory.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is! File) {
            continue;
          }

          final MediaFile? media =
              await _buildMediaFile(entity);

          if (media == null) {
            continue;
          }

          final String normalizedPath =
              _normalizePath(media.filePath);

          if (!seenPaths.add(normalizedPath)) {
            continue;
          }

          results.add(media);

          if (media.isImage) {
            imageCount++;
          } else if (media.isVideo) {
            videoCount++;
          } else if (media.isDocument) {
            documentCount++;
          }
        }
      } catch (_) {
        // Some Android directories may not be readable.
      }

      onProgress?.call(
        currentDirectory / totalDirectories,
        directory.path,
        currentDirectory,
        totalDirectories,
        imageCount,
        videoCount,
        documentCount,
      );
    }

    return results;
  }

  Future<List<MediaFile>> deepScan({
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

  Future<void> _collectDirectories(
    Directory directory,
    List<Directory> result,
  ) async {
    if (_isExcludedDirectory(directory.path)) {
      return;
    }

    result.add(directory);

    try {
      await for (final FileSystemEntity entity
          in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is Directory) {
          await _collectDirectories(
            entity,
            result,
          );
        }
      }
    } catch (_) {
      // Continue when a directory is inaccessible.
    }
  }

  Future<MediaFile?> _buildMediaFile(
    File file,
  ) async {
    try {
      final String path = file.path;

      final String fileName =
          _fileName(path);

      final String extension =
          _extension(fileName);

      MediaType? mediaType;

      if (imageExtensions.contains(extension)) {
        mediaType = MediaType.image;
      } else if (videoExtensions.contains(extension)) {
        mediaType = MediaType.video;
      } else if (documentExtensions.contains(extension)) {
        mediaType = MediaType.document;
      }

      if (mediaType == null) {
        return null;
      }

      /*
       * Basic file validation.
       *
       * We don't claim that an extension alone proves
       * that the file is a valid media/document file.
       */
      final int size = await file.length();

      if (size <= 0) {
        return null;
      }

      return MediaFile(
        asset: null,
        filePath: path,
        fileName: fileName,
        mediaType: mediaType,
        source: 'Deep Scan',
      );
    } catch (_) {
      return null;
    }
  }

  bool _isExcludedDirectory(String path) {
    final String normalized =
        _normalizePath(path).toLowerCase();

    for (final String excluded
        in excludedDirectoryNames) {
      final String normalizedExcluded =
          _normalizePath(excluded).toLowerCase();

      if (normalized == normalizedExcluded ||
          normalized.startsWith(
            '$normalizedExcluded/',
          )) {
        return true;
      }
    }

    return false;
  }

  String _extension(String name) {
    final int dot = name.lastIndexOf('.');

    if (dot <= 0 || dot == name.length - 1) {
      return '';
    }

    return name
        .substring(dot + 1)
        .toLowerCase();
  }

  String _fileName(String path) {
    final String normalized =
        _normalizePath(path);

    final int slash =
        normalized.lastIndexOf('/');

    if (slash == -1) {
      return normalized;
    }

    return normalized.substring(
      slash + 1,
    );
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }
}
