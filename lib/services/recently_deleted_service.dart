import 'package:flutter/services.dart';

import '../models/media_file.dart';

class RecentlyDeletedService {
  static const MethodChannel _channel =
      MethodChannel('com.recova/recently_deleted');

  /// Returns media items that Android currently exposes as
  /// trashed / recently deleted through MediaStore.
  ///
  /// This does NOT claim that every permanently deleted file
  /// can be recovered.
  Future<List<MediaFile>> scanRecentlyDeleted() async {
    try {
      final dynamic response =
          await _channel.invokeMethod(
        'getRecentlyDeletedMedia',
      );

      if (response == null) {
        return <MediaFile>[];
      }

      if (response is! List) {
        return <MediaFile>[];
      }

      final List<MediaFile> files =
          <MediaFile>[];

      for (final dynamic item in response) {
        if (item is! Map) {
          continue;
        }

        final String uri =
            item['uri']?.toString() ?? '';

        final String name =
            item['name']?.toString() ?? 'Unknown';

        final String mediaTypeString =
            item['mediaType']?.toString() ?? '';

        if (uri.isEmpty || name.isEmpty) {
          continue;
        }

        final MediaType? mediaType =
            _parseMediaType(mediaTypeString);

        if (mediaType == null) {
          continue;
        }

        files.add(
          MediaFile(
            asset: null,
            filePath: uri,
            fileName: name,
            mediaType: mediaType,
            source: 'Recently Deleted',
            selected: false,
          ),
        );
      }

      return files;
    } on PlatformException {
      return <MediaFile>[];
    } catch (_) {
      return <MediaFile>[];
    }
  }

  MediaType? _parseMediaType(
    String value,
  ) {
    switch (value.toLowerCase()) {
      case 'image':
        return MediaType.image;

      case 'video':
        return MediaType.video;

      case 'document':
        return MediaType.document;

      default:
        return null;
    }
  }

  /// Requests Android to restore the supplied
  /// MediaStore trash items.
  ///
  /// Android may display its own confirmation UI.
  Future<bool> requestRestore(
    List<MediaFile> files,
  ) async {
    if (files.isEmpty) {
      return false;
    }

    final List<String> uris = files
        .map(
          (MediaFile file) =>
              file.filePath.trim(),
        )
        .where(
          (String uri) => uri.isNotEmpty,
        )
        .toList();

    if (uris.isEmpty) {
      return false;
    }

    try {
      final dynamic result =
          await _channel.invokeMethod(
        'requestRestore',
        <String, dynamic>{
          'uris': uris,
        },
      );

      return result == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
