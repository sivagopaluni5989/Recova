import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../services/media_scanner_service.dart';
import '../services/scan_progress_service.dart';
import '../services/recovery_service.dart';
import '../services/recovery_history_service.dart';
import '../services/scan_result_store.dart';

class MediaProvider extends ChangeNotifier {
  final MediaScannerService _scanner =
      MediaScannerService();

  final ScanProgressService progressService =
      ScanProgressService();

  final RecoveryService _recoveryService =
      RecoveryService();

  final RecoveryHistoryService _historyService =
      RecoveryHistoryService();

  final ScanResultStore _resultStore =
      ScanResultStore();

  // ============================================================
  // LIVE NORMAL-SCAN RESULTS
  // ============================================================

  List<MediaFile> _mediaFiles = <MediaFile>[];

  // Separate category lists.
  List<MediaFile> _imageFiles = <MediaFile>[];
  List<MediaFile> _videoFiles = <MediaFile>[];
  List<MediaFile> _documentFiles = <MediaFile>[];

  bool _isScanning = false;

  MediaType? _selectedFilter;

  // ============================================================
  // GETTERS
  // ============================================================

  List<MediaFile> get mediaFiles =>
      List<MediaFile>.unmodifiable(_mediaFiles);

  List<MediaFile> get imageFiles =>
      List<MediaFile>.unmodifiable(_imageFiles);

  List<MediaFile> get videoFiles =>
      List<MediaFile>.unmodifiable(_videoFiles);

  List<MediaFile> get documentFiles =>
      List<MediaFile>.unmodifiable(_documentFiles);

  bool get isScanning =>
      _isScanning;

  MediaType? get selectedFilter =>
      _selectedFilter;

  List<MediaFile> get filteredFiles {
    if (_selectedFilter == null) {
      return _mediaFiles;
    }

    return _mediaFiles
        .where(
          (MediaFile file) =>
              file.mediaType == _selectedFilter,
        )
        .toList();
  }

  int get imageCount =>
      _imageFiles.length;

  int get videoCount =>
      _videoFiles.length;

  int get documentCount =>
      _documentFiles.length;

  int get totalCount =>
      _mediaFiles.length;

  // ============================================================
  // NORMAL MEDIA SCAN
  // ============================================================

  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }

    _mediaFiles.clear();
    _imageFiles.clear();
    _videoFiles.clear();
    _documentFiles.clear();

    _selectedFilter = null;

    _isScanning = true;

    progressService.updateProgress(0.0);
    progressService.updateImageCount(0);
    progressService.updateVideoCount(0);
    progressService.updateDocumentCount(0);

    notifyListeners();

    try {
      final List<MediaFile> scannedFiles =
          await _scanner.scanMedia(
        onProgress: (
          double percent,
          String folder,
          int current,
          int total,
          int images,
          int videos,
          int documents,
        ) {
          progressService.updateProgress(
            percent,
          );

          progressService.updateImageCount(
            images,
          );

          progressService.updateVideoCount(
            videos,
          );

          progressService.updateDocumentCount(
            documents,
          );

          notifyListeners();
        },
      );

      // ----------------------------------------------------------
      // REMOVE DUPLICATE PATHS
      // ----------------------------------------------------------

      _mediaFiles =
          _removeDuplicateFiles(
        scannedFiles,
      );

      // ----------------------------------------------------------
      // BUILD SEPARATE CATEGORY LISTS
      // ----------------------------------------------------------

      _rebuildCategoryLists();

      // ----------------------------------------------------------
      // FINAL PROGRESS COUNTS
      // ----------------------------------------------------------

      progressService.updateImageCount(
        imageCount,
      );

      progressService.updateVideoCount(
        videoCount,
      );

      progressService.updateDocumentCount(
        documentCount,
      );

      progressService.updateProgress(
        1.0,
      );

      // ----------------------------------------------------------
      // PERSIST NORMAL SCAN RESULTS
      // ----------------------------------------------------------

      await _resultStore.saveImages(
        _imageFiles,
      );

      await _resultStore.saveVideos(
        _videoFiles,
      );

      await _resultStore.saveDocuments(
        _documentFiles,
      );

      // ----------------------------------------------------------
      // IMPORTANT
      //
      // Do NOT clear:
      //   hidden
      //   folders
      //   recentlyDeleted
      //
      // here.
      //
      // Those are maintained by their own scan workflows.
      // ----------------------------------------------------------

      _isScanning = false;

      notifyListeners();
    } catch (e) {
      _isScanning = false;

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // LOAD STORED NORMAL SCAN RESULTS
  // ============================================================

  Future<void> loadStoredResults() async {
    try {
      final List<MediaFile> images =
          await _resultStore.loadImages();

      final List<MediaFile> videos =
          await _resultStore.loadVideos();

      final List<MediaFile> documents =
          await _resultStore.loadDocuments();

      final List<MediaFile> loaded =
          <MediaFile>[
        ...images,
        ...videos,
        ...documents,
      ];

      _mediaFiles =
          _removeDuplicateFiles(
        loaded,
      );

      _rebuildCategoryLists();

      progressService.updateImageCount(
        imageCount,
      );

      progressService.updateVideoCount(
        videoCount,
      );

      progressService.updateDocumentCount(
        documentCount,
      );

      notifyListeners();
    } catch (_) {
      // Stored results are optional.
      //
      // If stored data is invalid, the live scanner
      // can still operate normally.
    }
  }

  // ============================================================
  // REBUILD CATEGORY LISTS
  // ============================================================

  void _rebuildCategoryLists() {
    _imageFiles = _mediaFiles
        .where(
          (MediaFile file) =>
              file.mediaType ==
              MediaType.image,
        )
        .toList();

    _videoFiles = _mediaFiles
        .where(
          (MediaFile file) =>
              file.mediaType ==
              MediaType.video,
        )
        .toList();

    _documentFiles = _mediaFiles
        .where(
          (MediaFile file) =>
              file.mediaType ==
              MediaType.document,
        )
        .toList();
  }

  // ============================================================
  // REMOVE DUPLICATES
  // ============================================================

  List<MediaFile> _removeDuplicateFiles(
    List<MediaFile> files,
  ) {
    final Set<String> seen =
        <String>{};

    final List<MediaFile> unique =
        <MediaFile>[];

    for (final MediaFile file in files) {
      final String path =
          file.filePath.trim();

      if (path.isEmpty) {
        continue;
      }

      final String key =
          path.toLowerCase();

      if (seen.add(key)) {
        unique.add(file);
      }
    }

    return unique;
  }

  // ============================================================
  // FILTER
  // ============================================================

  void changeFilter(
    MediaType? type,
  ) {
    _selectedFilter = type;

    notifyListeners();
  }

  // ============================================================
  // SELECTION
  // ============================================================

  void toggleSelection(
    MediaFile file,
  ) {
    file.selected =
        !file.selected;

    notifyListeners();
  }

  List<MediaFile> get selectedFiles {
    return _mediaFiles
        .where(
          (MediaFile file) =>
              file.selected,
        )
        .toList();
  }

  // ============================================================
  // RECOVERY
  // ============================================================

  Future<int> recoverSelected() async {
    final List<MediaFile> files =
        selectedFiles;

    if (files.isEmpty) {
      return 0;
    }

    final RecoveryResult result =
        await _recoveryService.recoverFiles(
      files,
    );

    final int recovered =
        result.recoveredFiles;

    int totalSize = 0;

    for (final MediaFile file in files) {
      try {
        if (file.asset != null) {
          final File? source =
              await file.asset!.file;

          if (source != null &&
              await source.exists()) {
            totalSize +=
                await source.length();
          }
        } else {
          final File source =
              File(
            file.filePath,
          );

          if (await source.exists()) {
            totalSize +=
                await source.length();
          }
        }
      } catch (_) {
        // Ignore individual file size failures.
      }
    }

    await _historyService.saveHistory(
      dateTime: DateTime.now(),
      filesRecovered: recovered,
      totalSize: totalSize,
      folderPath:
    'Recova/Recovered',
    );

    return recovered;
  }

  // ============================================================
  // CLEAR LIVE RESULTS
  // ============================================================

  void clearFiles() {
    _mediaFiles.clear();
    _imageFiles.clear();
    _videoFiles.clear();
    _documentFiles.clear();

    _selectedFilter = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR SELECTION
  // ============================================================

  void clearSelection() {
    for (final MediaFile file
        in _mediaFiles) {
      file.selected = false;
    }

    notifyListeners();
  }
}
