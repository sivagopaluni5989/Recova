import 'dart:io';

import '../models/media_file.dart';

class HiddenFolderScannerService {
  static const String storageRoot =
      '/storage/emulated/0';

  final List<String> hiddenLocations = [
    '$storageRoot/DCIM/.thumbnails',
    '$storageRoot/Pictures/.thumbnails',
    '$storageRoot/WhatsApp/Media/.Statuses',
    '$storageRoot/Android/media',
  ];

  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'heic',
    'heif',
  ];

  static const List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    '3gp',
    'webm',
    'm4v',
    'flv',
  ];

  static const List<String> documentExtensions = [
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
  ];

  Future<List<MediaFile>> scanHiddenFolders({
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
    final List<MediaFile> hiddenFiles = [];

    int imageCount = 0;
    int videoCount = 0;
    int documentCount = 0;

    final List<Directory> folders = [];

    /*
     * Find only directories that actually exist and are
     * accessible from the device.
     */
    for (final String path in hiddenLocations) {
      try {
        final Directory directory = Directory(path);

        if (await directory.exists()) {
          folders.add(directory);
        }
      } catch (_) {
        // Ignore inaccessible locations.
      }
    }

    final int totalFolders = folders.length;

    if (totalFolders == 0) {
      onProgress?.call(
        1.0,
        'No accessible hidden folders',
        0,
        0,
        0,
        0,
        0,
      );

      return hiddenFiles;
    }

    int currentFolder = 0;

    for (final Directory folder in folders) {
      currentFolder++;

      await _scanDirectory(
        folder,
        hiddenFiles,
        onFileFound: (
          MediaFile file,
        ) {
          if (file.mediaType == MediaType.image) {
            imageCount++;
          } else if (file.mediaType == MediaType.video) {
            videoCount++;
          } else if (file.mediaType == MediaType.document) {
            documentCount++;
          }

          onProgress?.call(
            currentFolder / totalFolders,
            folder.path,
            currentFolder,
            totalFolders,
            imageCount,
            videoCount,
            documentCount,
          );
        },
      );
    }

    return hiddenFiles;
  }

  Future<void> _scanDirectory(
    Directory directory,
    List<MediaFile> result, {
    required Function(MediaFile file) onFileFound,
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

        final String path = entity.path;

        final int dotIndex = path.lastIndexOf('.');

        if (dotIndex == -1) {
          continue;
        }

        final String extension =
            path.substring(dotIndex + 1).toLowerCase();

        MediaType? mediaType;

        if (imageExtensions.contains(extension)) {
          mediaType = MediaType.image;
        } else if (videoExtensions.contains(extension)) {
          mediaType = MediaType.video;
        } else if (documentExtensions.contains(extension)) {
          mediaType = MediaType.document;
        }

        if (mediaType == null) {
          continue;
        }

        final String fileName =
            path.split('/').last;

        final MediaFile media = MediaFile(
          filePath: path,
          fileName: fileName,
          mediaType: mediaType,
          source: directory.path,
        );

        result.add(media);

        onFileFound(media);
      }
    } catch (_) {
      /*
       * Android may deny access to some directories.
       *
       * Do not terminate the complete hidden-media scan.
       */
    }
  }
}
