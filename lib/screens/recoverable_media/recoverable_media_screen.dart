import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/recovery_service.dart';

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

  List<MediaFile> _mediaFiles = <MediaFile>[];

  bool _isScanning = false;
  bool _isRecovering = false;

  int _imageCount = 0;
  int _videoCount = 0;
  int _documentCount = 0;

  @override
  void initState() {
    super.initState();
    _scanMedia();
  }

  Future<void> _scanMedia() async {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _mediaFiles = <MediaFile>[];
      _imageCount = 0;
      _videoCount = 0;
      _documentCount = 0;
    });

    try {
      final List<MediaFile> result =
          await _scanner.scanMedia();

      if (!mounted) {
        return;
      }

      int images = 0;
      int videos = 0;
      int documents = 0;

      for (final MediaFile file in result) {
        if (file.isImage) {
          images++;
        } else if (file.isVideo) {
          videos++;
        } else if (file.isDocument) {
          documents++;
        }
      }

      setState(() {
        _mediaFiles = result;
        _imageCount = images;
        _videoCount = videos;
        _documentCount = documents;
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
    return _mediaFiles
        .where((MediaFile file) => file.selected)
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
            'file${selected.length == 1 ? '' : 's'}?',
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

    try {
      /*
       * VERY IMPORTANT:
       *
       * We pass ONLY "selected".
       *
       * We do NOT pass _mediaFiles.
       */
      final RecoveryResult result =
          await _recovery.recoverFiles(selected);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecovering = false;
      });

      await _showRecoveryResult(result);
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

  Future<void> _showRecoveryResult(
    RecoveryResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: <Widget>[
              Icon(
                result.recoveredFiles > 0
                    ? Icons.check_circle
                    : Icons.error,
                color: result.recoveredFiles > 0
                    ? Colors.green
                    : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Recovery Complete',
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
                  '${result.recoveredFiles} '
                  '${result.recoveredFiles == 1 ? 'File' : 'Files'} '
                  'Recovered',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

const SizedBox(height: 20),
                _resultRow(
                  Icons.image,
                  'Photos',
                  result.photos,
                ),
                _resultRow(
                  Icons.video_library,
                  'Videos',
                  result.videos,
                ),
                _resultRow(
                  Icons.description,
                  'Documents',
                  result.documents,
                ),
                if (result.failedFiles > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  _resultRow(
                    Icons.error_outline,
                    'Failed',
                    result.failedFiles,
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Saved to',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '/Recova/Recovered/',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.errors.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  const Text(
                    'Some files could not be recovered:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ...result.errors
                      .take(5)
                      .map(
                        (String error) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 4,
                          ),
                          child: Text(
                            '• $error',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                ],
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

    // Remove only successfully selected/recovered files
    // from this screen.
    if (result.recoveredFiles > 0) {
      setState(() {
        _mediaFiles.removeWhere(
          (MediaFile file) =>
              file.selected,
        );
      });
    }
  }

  Widget _resultRow(
    IconData icon,
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
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
                fontSize: 17,
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
    });
  }

  void _clearSelection() {
    setState(() {
      for (final MediaFile file
          in _mediaFiles) {
        file.selected = false;
      }
    });
  }

  Widget _buildThumbnail(
    MediaFile media,
  ) {
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
    int index,
  ) {
    return GestureDetector(
      onTap: () => _toggleFile(media),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: _buildThumbnail(media),
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
              'Please wait',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_mediaFiles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _scanMedia,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 180),
            Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No media found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
          child: GridView.builder(
            padding:
                const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.90,
            ),
            itemCount: _mediaFiles.length,
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              return _mediaCard(
                _mediaFiles[index],
                index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final int selected =
        _selectedFiles.length;

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
            Icons.search,
            color: Colors.white,
            size: 45,
          ),
          const SizedBox(height: 8),
          const Text(
            'Deep Media Scan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Found ${_mediaFiles.length} accessible files',
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
                _imageCount,
              ),
              _countItem(
                Icons.video_library,
                'Videos',
                _videoCount,
              ),
              _countItem(
                Icons.description,
                'Documents',
                _documentCount,
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

  Widget _bottomButtons() {
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
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectAll,
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
                  child: OutlinedButton.icon(
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
                      ? 'Recovering...'
                      : 'Recover Selected'
                      ,
                ),
                style: FilledButton.styleFrom(
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
  Widget build(BuildContext context) {
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
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar:
          _mediaFiles.isEmpty ||
                  _isScanning
              ? null
              : _bottomButtons(),
    );
  }
}
