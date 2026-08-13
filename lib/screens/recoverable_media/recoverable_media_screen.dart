
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/recovery_service.dart';
import '../../services/recently_deleted_service.dart';
import '../../services/recovery_history_service.dart';

class RecoverableMediaScreen extends StatefulWidget {
  const RecoverableMediaScreen({
    super.key,
  });

  @override
  State<RecoverableMediaScreen> createState() =>
      _RecoverableMediaScreenState();
}

class _RecoverableMediaScreenState
    extends State<RecoverableMediaScreen> {
  final MediaScannerService _scanner =
      MediaScannerService();

  final RecoveryService _recovery =
      RecoveryService();

  final RecentlyDeletedService _recentlyDeleted =
      RecentlyDeletedService();

  final RecoveryHistoryService _historyService =
    RecoveryHistoryService();


  /// Currently accessible media.
  List<MediaFile> _mediaFiles = <MediaFile>[];

  /// Android MediaStore trash / recently deleted media.
  List<MediaFile> _recentlyDeletedFiles =
      <MediaFile>[];

  bool _isScanning = false;
  bool _isRecovering = false;

  int _imageCount = 0;
  int _videoCount = 0;
  int _documentCount = 0;
  int _recoveredCount = 0;


  int _deletedImageCount = 0;
  int _deletedVideoCount = 0;
  int _deletedDocumentCount = 0;

  @override
void initState() {
  super.initState();
  _loadRecoveredCount();
  _scanMedia();
}

Future<void> _loadRecoveredCount() async {
  try {
    final int count =
        await _historyService.getTotalRecovered();

    if (!mounted) {
      return;
    }

    setState(() {
      _recoveredCount = count;
    });
  } catch (_) {
    // Keep the displayed count at zero if history
    // cannot be loaded.
  }
}

  Future<void> _scanMedia() async {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;

      _mediaFiles = <MediaFile>[];
      _recentlyDeletedFiles = <MediaFile>[];

      _imageCount = 0;
      _videoCount = 0;
      _documentCount = 0;

      _deletedImageCount = 0;
      _deletedVideoCount = 0;
      _deletedDocumentCount = 0;
    });

    try {
      /*
       * IMPORTANT:
       *
       * We perform TWO independent scans.
       *
       * 1. Android MediaStore Trash
       * 2. Currently accessible media through PhotoManager
       *
       * These must remain separate because their recovery
       * mechanisms are different.
       */

      final List<MediaFile> deleted =
          await _recentlyDeleted.scanRecentlyDeleted();

      final List<MediaFile> accessible =
          await _scanner.scanMedia();

      if (!mounted) {
        return;
      }

      int images = 0;
      int videos = 0;
      int documents = 0;

      int deletedImages = 0;
      int deletedVideos = 0;
      int deletedDocuments = 0;

      for (final MediaFile file in accessible) {
        if (file.isImage) {
          images++;
        } else if (file.isVideo) {
          videos++;
        } else if (file.isDocument) {
          documents++;
        }
      }

      for (final MediaFile file in deleted) {
        if (file.isImage) {
          deletedImages++;
        } else if (file.isVideo) {
          deletedVideos++;
        } else if (file.isDocument) {
          deletedDocuments++;
        }
      }

      setState(() {
        _mediaFiles = accessible;
        _recentlyDeletedFiles = deleted;

        _imageCount = images;
        _videoCount = videos;
        _documentCount = documents;

        _deletedImageCount = deletedImages;
        _deletedVideoCount = deletedVideos;
        _deletedDocumentCount = deletedDocuments;

        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isScanning = false;
      });

      _showMessage(
        'Scan failed: $e',
        isError: true,
      );
    }
  }

  List<MediaFile> get _selectedFiles {
    return <MediaFile>[
      ..._mediaFiles.where(
        (MediaFile file) => file.selected,
      ),
      ..._recentlyDeletedFiles.where(
        (MediaFile file) => file.selected,
      ),
    ];
  }

  List<MediaFile> get _selectedRecentlyDeletedFiles {
    return _recentlyDeletedFiles
        .where(
          (MediaFile file) => file.selected,
        )
        .toList();
  }

  List<MediaFile> get _selectedAccessibleFiles {
    return _mediaFiles
        .where(
          (MediaFile file) => file.selected,
        )
        .toList();
  }

  Future<void> _recoverSelected() async {
    if (_isRecovering) {
      return;
    }

    final List<MediaFile> selected =
        _selectedFiles;

    if (selected.isEmpty) {
      _showMessage(
        'Please select at least one file.',
      );
      return;
    }

    final List<MediaFile> deletedSelected =
        _selectedRecentlyDeletedFiles;

    final List<MediaFile> accessibleSelected =
        _selectedAccessibleFiles;

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Recover Selected',
          ),
          content: Text(
            'Recover ${selected.length} selected '
            'file${selected.length == 1 ? '' : 's'}?\n\n'
            '${deletedSelected.length} from Recently Deleted\n'
            '${accessibleSelected.length} accessible media file'
            '${accessibleSelected.length == 1 ? '' : 's'}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('RECOVER'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isRecovering = true;
    });

    int restoredFromTrash = 0;
    RecoveryResult? normalRecoveryResult;

    try {
      /*
       * ============================================================
       * PART 1: RECENTLY DELETED / ANDROID TRASH
       * ============================================================
       *
       * These are content:// MediaStore URIs.
       *
       * They MUST NOT be passed to RecoveryService because
       * RecoveryService uses dart:io File().
       *
       * Instead Android's MediaStore trash restore request
       * is used.
       */
      if (deletedSelected.isNotEmpty) {
  final bool restoreRequest =
      await _recentlyDeleted.requestRestore(
    deletedSelected,
  );

  if (restoreRequest) {
    /*
     * Android has completed the MediaStore restore
     * confirmation request successfully.
     *
     * These files were still present in Android's
     * MediaStore Trash. Recova is NOT recovering
     * permanently deleted files.
     */
    restoredFromTrash =
        deletedSelected.length;
  }
}

/*
 * ============================================================
 * PART 2: NORMAL ACCESSIBLE MEDIA
 * ============================================================
 *
 * These files still exist and are accessible to the app.
 * They are handled by RecoveryService.
 */
if (accessibleSelected.isNotEmpty) {
  normalRecoveryResult =
      await _recovery.recoverFiles(
    accessibleSelected,
  );
}

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecovering = false;
      });

      await _showCombinedRecoveryResult(
  restoredFromTrash: restoredFromTrash,
  deletedRequested: deletedSelected.length,
  normalResult: normalRecoveryResult,
);

await _loadRecoveredCount();


      
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecovering = false;
      });

      _showMessage(
        'Recovery failed: $e',
        isError: true,
      );
    }
  }

  Future<void> _showCombinedRecoveryResult({
    required int restoredFromTrash,
    required int deletedRequested,
    required RecoveryResult? normalResult,
  }) async {
    final int normalRecovered =
        normalResult?.recoveredFiles ?? 0;

    final int normalFailed =
        normalResult?.failedFiles ?? 0;

    final int totalRecovered =
        restoredFromTrash + normalRecovered;

    final int totalRequested =
        deletedRequested +
            (normalResult == null
                ? 0
                : normalResult.recoveredFiles +
                    normalResult.failedFiles);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: Row(
            children: <Widget>[
              Icon(
                totalRecovered > 0
                    ? Icons.check_circle
                    : Icons.info,
                color: totalRecovered > 0
                    ? Colors.green
                    : Colors.orange,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Recovery Result',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$totalRecovered '
                  '${totalRecovered == 1 ? 'File' : 'Files'} '
                  'Processed',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (deletedRequested > 0) ...[
                  _resultRow(
                    Icons.delete_outline,
                    'Recently Deleted',
                    restoredFromTrash,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Android restore confirmation was '
                    'requested for the selected trash items.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],

                if (normalResult != null) ...[
                  const SizedBox(height: 16),

                  _resultRow(
                    Icons.image,
                    'Photos Recovered',
                    normalResult.photos,
                  ),

                  _resultRow(
                    Icons.video_library,
                    'Videos Recovered',
                    normalResult.videos,
                  ),

                  _resultRow(
                    Icons.description,
                    'Documents Recovered',
                    normalResult.documents,
                  ),

                  if (normalFailed > 0)
                    _resultRow(
                      Icons.error_outline,
                      'Failed',
                      normalFailed,
                    ),
                ],

                const SizedBox(height: 20),

                const Text(
                  'Normal recovered files are saved to:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  '/Recova/Recovered/',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (normalResult != null &&
                    normalResult.errors.isNotEmpty) ...[
                  const SizedBox(height: 18),

                  const Text(
                    'Some normal files could not be recovered:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  ...normalResult.errors
                      .take(5)
                      .map(
                        (String error) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 4,
                          ),
                          child: Text(
                            '• $error',
                            style:
                                const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                ],

                if (totalRequested == 0)
                  const Text(
                    'No files were processed.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    /*
     * Remove successfully processed normal files from
     * this screen.
     *
     * Recently Deleted items are NOT removed here because
     * requestRestore() only launches Android's restore
     * request. We have not yet independently verified that
     * the user completed the system confirmation.
     */
    if (normalRecovered > 0) {
      setState(() {
        _mediaFiles.removeWhere(
          (MediaFile file) =>
              file.selected &&
              file.source != 'Recently Deleted',
        );
      });
    }

    /*
     * Refresh after an Android trash restore request.
     *
     * The Android system may take a moment to complete the
     * operation, so this refresh is intentionally delayed.
     */
    if (restoredFromTrash > 0) {
      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      if (mounted) {
        await _scanMedia();
      }
    }
  }

  Widget _resultRow(
    IconData icon,
    String label,
    int value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFile(
    MediaFile file,
  ) {
    setState(() {
      file.selected = !file.selected;
    });
  }

  void _selectAll() {
    setState(() {
      for (final MediaFile file
          in _mediaFiles) {
        file.selected = true;
      }

      for (final MediaFile file
          in _recentlyDeletedFiles) {
        file.selected = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      for (final MediaFile file
          in _mediaFiles) {
        file.selected = false;
      }

      for (final MediaFile file
          in _recentlyDeletedFiles) {
        file.selected = false;
      }
    });
  }
 Widget _buildThumbnail(
    MediaFile media,
  ) {
    /*
     * Recently Deleted items don't have an AssetEntity.
     * They are represented by content:// MediaStore URIs,
     * so use the icon fallback for them.
     */
    if (media.asset != null) {
      return FutureBuilder<Uint8List?>(
        future: media.asset!
            .thumbnailDataWithSize(
          const ThumbnailSize.square(300),
          quality: 80,
        ),
        builder: (
          BuildContext context,
          AsyncSnapshot<Uint8List?> snapshot,
        ) {
          if (snapshot.hasData &&
              snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }

          return _fileFallback(media);
        },
      );
    }

    return _fileFallback(media);
  }

  Widget _fileFallback(
    MediaFile media,
  ) {
    /*
     * Don't try File(content://...).
     *
     * Recently Deleted MediaStore items use a URI,
     * not a filesystem path.
     */
    if (media.source == 'Recently Deleted') {
      return _iconPlaceholder(media);
    }

    final File file =
        File(media.filePath);

    if (file.existsSync() &&
        media.isImage) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stack,
        ) {
          return _iconPlaceholder(media);
        },
      );
    }

    return _iconPlaceholder(media);
  }

  Widget _iconPlaceholder(
    MediaFile media,
  ) {
    return Center(
      child: Icon(
        media.isVideo
            ? Icons.video_library
            : media.isDocument
                ? Icons.description
                : Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _mediaCard(
    MediaFile media,
  ) {
    final bool isDeleted =
        media.source == 'Recently Deleted';

    return GestureDetector(
      onTap: () => _toggleFile(media),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: Container(
              color: Colors.grey.shade100,
              child: _buildThumbnail(media),
            ),
          ),

          if (media.isVideo)
            const Center(
              child: CircleAvatar(
                radius: 25,
                backgroundColor:
                    Colors.black54,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

          /*
           * Source indicator.
           */
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isDeleted
                    ? Colors.orange.shade800
                    : Colors.black54,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                isDeleted
                    ? 'TRASH'
                    : 'MEDIA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /*
           * File name.
           */
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                media.fileName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          /*
           * Selection indicator.
           */
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: media.selected
                    ? Colors.blue
                    : Colors.white70,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: media.selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Scanning media...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Checking Android Trash and accessible media',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final bool hasDeleted =
        _recentlyDeletedFiles.isNotEmpty;

    final bool hasAccessible =
        _mediaFiles.isNotEmpty;

    if (!hasDeleted && !hasAccessible) {
      return RefreshIndicator(
        onRefresh: _scanMedia,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 150),
            Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No recoverable media found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                'Recova can only recover files that '
                'Android currently exposes or that '
                'remain accessible to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        _buildHeader(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _scanMedia,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.only(
                bottom: 20,
              ),
              children: <Widget>[
                if (hasDeleted)
                  _buildRecentlyDeletedSection(),

                if (hasAccessible)
                  _buildAccessibleSection(),

                if (!hasDeleted)
                  _buildNoTrashInfo(),

                if (!hasAccessible)
                  _buildNoAccessibleInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final int selected =
        _selectedFiles.length;

    final int total =
        _mediaFiles.length +
            _recentlyDeletedFiles.length;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF185ABC),
            Color(0xFF2E75B6),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.restore,
            color: Colors.white,
            size: 45,
          ),

          const SizedBox(height: 8),

          const Text(
            'Recoverable Media',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '$total recoverable items found',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 16),

          Row(
  mainAxisAlignment:
      MainAxisAlignment.spaceAround,
  children: <Widget>[
    _countItem(
      Icons.image,
      'Photos',
      _imageCount +
          _deletedImageCount,
    ),
    _countItem(
      Icons.video_library,
      'Videos',
      _videoCount +
          _deletedVideoCount,
    ),
    _countItem(
      Icons.description,
      'Documents',
      _documentCount +
          _deletedDocumentCount,
    ),
    _countItem(
      Icons.check_circle,
      'Recovered',
      _recoveredCount,
    ),
  ],
),

          const SizedBox(height: 15),

          Text(
            '$selected selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

 Widget _countItem(
    IconData icon,
    String title,
    int count,
  ) {
    return Column(
      children: <Widget>[
        Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyDeletedSection() {
    return _buildSection(
      title: 'Recently Deleted',
      subtitle:
          'Items Android currently exposes in MediaStore Trash',
      icon: Icons.delete_outline,
      count: _recentlyDeletedFiles.length,
      files: _recentlyDeletedFiles,
      isRecentlyDeleted: true,
    );
  }

  Widget _buildAccessibleSection() {
    return _buildSection(
      title: 'Accessible Media',
      subtitle:
          'Media currently accessible through Android MediaStore',
      icon: Icons.photo_library_outlined,
      count: _mediaFiles.length,
      files: _mediaFiles,
      isRecentlyDeleted: false,
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required List<MediaFile> files,
    required bool isRecentlyDeleted,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              6,
              8,
              6,
              10,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 27,
                  color: isRecentlyDeleted
                      ? Colors.orange.shade800
                      : Colors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$title ($count)',
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(0),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.90,
            ),
            itemCount: files.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              return _mediaCard(
                files[index],
              );
            },
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildNoTrashInfo() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No Android MediaStore Trash items '
              'are currently exposed. This does not '
              'mean permanently deleted files exist '
              'or can be recovered.',
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccessibleInfo() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blue.shade200,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.photo_library_outlined,
            color: Colors.blue,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No currently accessible media was found.',
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    final int selected =
        _selectedFiles.length;

    final int deletedSelected =
        _selectedRecentlyDeletedFiles.length;

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          12,
        ),
        child: Column(
          children: <Widget>[
            if (selected > 0)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Text(
                  '$selected selected'
                  '${deletedSelected > 0 ? ' • $deletedSelected from Trash' : ''}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),

            Row(
              children: <Widget>[
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _selectAll,
                    icon: const Icon(
                      Icons.select_all,
                    ),
                    label: const Text(
                      'Select All',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _clearSelection,
                    icon: const Icon(
                      Icons.clear_all,
                    ),
                    label: const Text(
                      'Clear',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isRecovering
                        ? null
                        : _recoverSelected,
                icon: _isRecovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.restore,
                      ),
                label: Text(
                  _isRecovering
                      ? 'Processing...'
                      : 'Recover Selected',
                ),
                style:
                    FilledButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    52,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasFiles =
        _mediaFiles.isNotEmpty ||
            _recentlyDeletedFiles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recoverable Scanner',
        ),
        actions: <Widget>[
          IconButton(
            onPressed:
                _isScanning
                    ? null
                    : _scanMedia,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Scan again',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar:
          !hasFiles || _isScanning
              ? null
              : _bottomButtons(),
    );
  }
}
