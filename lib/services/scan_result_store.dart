import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_file.dart';

class ScanResultStore {
  static const String _imagesKey = 'recova_scan_images';
  static const String _videosKey = 'recova_scan_videos';
  static const String _documentsKey = 'recova_scan_documents';
  static const String _foldersKey = 'recova_scan_folders';
  static const String _hiddenKey = 'recova_scan_hidden';
  static const String _recentlyDeletedKey =
      'recova_scan_recently_deleted';

  static const String _lastScanTimeKey =
      'recova_last_scan_time';

  static const String _scanCompletedKey =
      'recova_scan_completed';

  /// ------------------------------------------------------------
  /// SAVE COMPLETE SCAN
  /// ------------------------------------------------------------

  Future<void> saveScanResults({
    List<MediaFile> images = const <MediaFile>[],
    List<MediaFile> videos = const <MediaFile>[],
    List<MediaFile> documents = const <MediaFile>[],
    List<String> folders = const <String>[],
    List<MediaFile> hidden = const <MediaFile>[],
    List<MediaFile> recentlyDeleted =
        const <MediaFile>[],
  }) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _imagesKey,
      jsonEncode(
        images.map(_mediaFileToMap).toList(),
      ),
    );

    await prefs.setString(
      _videosKey,
      jsonEncode(
        videos.map(_mediaFileToMap).toList(),
      ),
    );

    await prefs.setString(
      _documentsKey,
      jsonEncode(
        documents.map(_mediaFileToMap).toList(),
      ),
    );

    await prefs.setString(
      _foldersKey,
      jsonEncode(folders),
    );

    await prefs.setString(
      _hiddenKey,
      jsonEncode(
        hidden.map(_mediaFileToMap).toList(),
      ),
    );

    await prefs.setString(
      _recentlyDeletedKey,
      jsonEncode(
        recentlyDeleted.map(_mediaFileToMap).toList(),
      ),
    );

    await prefs.setString(
      _lastScanTimeKey,
      DateTime.now().toIso8601String(),
    );

    await prefs.setBool(
      _scanCompletedKey,
      true,
    );
  }

  /// ------------------------------------------------------------
  /// SAVE ONLY ONE CATEGORY
  /// ------------------------------------------------------------

  Future<void> saveImages(
    List<MediaFile> files,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _imagesKey,
      jsonEncode(
        files.map(_mediaFileToMap).toList(),
      ),
    );
  }

  Future<void> saveVideos(
    List<MediaFile> files,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _videosKey,
      jsonEncode(
        files.map(_mediaFileToMap).toList(),
      ),
    );
  }

  Future<void> saveDocuments(
    List<MediaFile> files,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _documentsKey,
      jsonEncode(
        files.map(_mediaFileToMap).toList(),
      ),
    );
  }

  Future<void> saveFolders(
    List<String> folders,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _foldersKey,
      jsonEncode(folders),
    );
  }

  Future<void> saveHidden(
    List<MediaFile> files,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _hiddenKey,
      jsonEncode(
        files.map(_mediaFileToMap).toList(),
      ),
    );
  }

  Future<void> saveRecentlyDeleted(
    List<MediaFile> files,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _recentlyDeletedKey,
      jsonEncode(
        files.map(_mediaFileToMap).toList(),
      ),
    );
  }

  /// ------------------------------------------------------------
  /// LOAD CATEGORIES
  /// ------------------------------------------------------------

  Future<List<MediaFile>> loadImages() async {
    return _loadMediaFiles(_imagesKey);
  }

  Future<List<MediaFile>> loadVideos() async {
    return _loadMediaFiles(_videosKey);
  }

  Future<List<MediaFile>> loadDocuments() async {
    return _loadMediaFiles(_documentsKey);
  }

  Future<List<String>> loadFolders() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? raw =
        prefs.getString(_foldersKey);

    if (raw == null || raw.isEmpty) {
      return <String>[];
    }

    try {
      final dynamic decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        return <String>[];
      }

      return decoded
          .map(
            (dynamic value) =>
                value.toString(),
          )
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<List<MediaFile>> loadHidden() async {
    return _loadMediaFiles(_hiddenKey);
  }

  Future<List<MediaFile>>
      loadRecentlyDeleted() async {
    return _loadMediaFiles(
      _recentlyDeletedKey,
    );
  }

  /// ------------------------------------------------------------
  /// LOAD EVERYTHING
  /// ------------------------------------------------------------

  Future<Map<String, dynamic>>
      loadAllResults() async {
    return <String, dynamic>{
      'images': await loadImages(),
      'videos': await loadVideos(),
      'documents': await loadDocuments(),
      'folders': await loadFolders(),
      'hidden': await loadHidden(),
      'recentlyDeleted':
          await loadRecentlyDeleted(),
      'lastScanTime':
          await getLastScanTime(),
      'scanCompleted':
          await isScanCompleted(),
    };
  }

  /// ------------------------------------------------------------
  /// SCAN STATUS
  /// ------------------------------------------------------------

  Future<bool> isScanCompleted() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _scanCompletedKey,
        ) ??
        false;
  }

  Future<DateTime?> getLastScanTime() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? value =
        prefs.getString(_lastScanTimeKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  /// ------------------------------------------------------------
  /// CLEAR STORED RESULTS
  /// ------------------------------------------------------------

  Future<void> clearAll() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_imagesKey);
    await prefs.remove(_videosKey);
    await prefs.remove(_documentsKey);
    await prefs.remove(_foldersKey);
    await prefs.remove(_hiddenKey);
    await prefs.remove(_recentlyDeletedKey);
    await prefs.remove(_lastScanTimeKey);
    await prefs.remove(_scanCompletedKey);
  }

  /// ------------------------------------------------------------
  /// INTERNAL MEDIA FILE STORAGE
  /// ------------------------------------------------------------

  Map<String, dynamic> _mediaFileToMap(
    MediaFile file,
  ) {
    return <String, dynamic>{
      'filePath': file.filePath,
      'fileName': file.fileName,
      'mediaType':
          file.mediaType.name,
      'source': file.source,
      'selected': false,
    };
  }

  Future<List<MediaFile>> _loadMediaFiles(
    String key,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? raw =
        prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return <MediaFile>[];
    }

    try {
      final dynamic decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        return <MediaFile>[];
      }

      final List<MediaFile> results =
          <MediaFile>[];

      for (final dynamic item in decoded) {
        if (item is! Map) {
          continue;
        }

        final String filePath =
            item['filePath']?.toString() ?? '';

        final String fileName =
            item['fileName']?.toString() ?? '';

        final String mediaTypeName =
            item['mediaType']?.toString() ?? '';

        final String source =
            item['source']?.toString() ?? '';

        if (filePath.isEmpty ||
            fileName.isEmpty ||
            mediaTypeName.isEmpty) {
          continue;
        }

        final MediaType? mediaType =
            _parseMediaType(
          mediaTypeName,
        );

        if (mediaType == null) {
          continue;
        }

        results.add(
          MediaFile(
            asset: null,
            filePath: filePath,
            fileName: fileName,
            mediaType: mediaType,
            source: source,
            selected: false,
          ),
        );
      }

      return results;
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
}
