import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';
import '../../services/recovery_service.dart';
import '../../services/hidden_folder_scanner_service.dart';

enum HiddenCategory {
  all,
  folders,
  images,
  videos,
  documents,
  recentlyDeleted,
}

class HiddenMediaScreen extends StatefulWidget {
  const HiddenMediaScreen({
    super.key,
  });

  @override
  State<HiddenMediaScreen> createState() =>
      _HiddenMediaScreenState();
}

class _HiddenMediaScreenState
    extends State<HiddenMediaScreen> {
  final MediaScannerService scanner =
      MediaScannerService();

  final HiddenFolderScannerService hiddenScanner =
      HiddenFolderScannerService();

  final RecoveryService recoveryService =
      RecoveryService();

  HiddenCategory selectedCategory =
      HiddenCategory.all;

  List<MediaFile> files = [];

  List<MediaFile> imageFiles = [];

  List<MediaFile> videoFiles = [];

  List<MediaFile> documentFiles = [];

  /*
   * This remains separate from hidden media.
   *
   * It will be populated by the future Deep Media Scan
   * recently-deleted scanner.
   */
  List<MediaFile> recentlyDeletedFiles = [];

  bool loading = false;

  double progress = 0;

  int images = 0;

  int videos = 0;

  int documents = 0;

  int hiddenFolders = 0;

  final Set<String> hiddenFolderPaths = {};

  String folder = "Ready";

  Future<void> scan() async {
    setState(() {
      loading = true;

      progress = 0;

      images = 0;

      videos = 0;

      documents = 0;

      hiddenFolders = 0;

      hiddenFolderPaths.clear();

      files.clear();

      imageFiles.clear();

      videoFiles.clear();

      documentFiles.clear();

      folder = "Scanning hidden media...";
    });

    try {
      final scannedFiles =
          await scanner.scanMedia(
        onProgress: (
          percent,
          currentFolder,
          current,
          total,
          imageCount,
          videoCount,
          documentCount,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            progress = percent;

            folder = currentFolder;

            images = imageCount;

            videos = videoCount;

            documents = documentCount;
          });
        },
      );

      files =
          List<MediaFile>.from(scannedFiles);

      final hiddenFiles =
          await hiddenScanner.scanHiddenFolders(
        onProgress: (
          double scanProgress,
          String scanFolder,
          int current,
          int total,
          int imageCount,
          int videoCount,
          int documentCount,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            progress = scanProgress;

            folder = "Hidden: $scanFolder";

            images = imageCount;

            videos = videoCount;

            documents = documentCount;

            hiddenFolderPaths.add(
              scanFolder,
            );
          });
        },
      );

      files.addAll(hiddenFiles);

      files = removeDuplicates(files);

      imageFiles = files
          .where(
            (file) =>
                file.mediaType ==
                MediaType.image,
          )
          .toList();

      videoFiles = files
          .where(
            (file) =>
                file.mediaType ==
                MediaType.video,
          )
          .toList();

      documentFiles = files
          .where(
            (file) =>
                _isDocument(file.fileName),
          )
          .toList();

      images = imageFiles.length;

      videos = videoFiles.length;

      documents = documentFiles.length;

      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;

        progress = 1;

        folder = "Scan Completed";

        hiddenFolders =
            hiddenFolderPaths.length;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Hidden Scan Complete\n\n"
            "Images: ${imageFiles.length}\n"
            "Videos: ${videoFiles.length}\n"
            "Documents: ${documentFiles.length}\n"
            "Folders: $hiddenFolders\n"
            "Total: ${files.length}",
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;

        progress = 0;

        folder = "Scan failed";
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Scan failed: $e",
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> recoverSelected() async {
    final selectedFiles = files
        .where(
          (file) => file.selected,
        )
        .toList();

    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Select files first",
          ),
        ),
      );

      return;
    }

    try {
      final count =
          await recoveryService.recoverFiles(
        selectedFiles,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "$count files recovered successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Recovery failed: $e",
          ),
        ),
      );
    }
  }

  bool _isDocument(String fileName) {
    final String name =
        fileName.toLowerCase();

    const List<String>
        documentExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.csv',
      '.rtf',
      '.odt',
      '.ods',
      '.odp',
      '.epub',
      '.html',
      '.htm',
      '.xml',
      '.json',
      '.log',
      '.md',
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
    ];

    return documentExtensions.any(
      (extension) =>
          name.endsWith(extension),
    );
  }

  IconData _documentIcon(
    String fileName,
  ) {
    final String name =
        fileName.toLowerCase();

    if (name.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }

    if (name.endsWith('.doc') ||
        name.endsWith('.docx')) {
      return Icons.description;
    }

    if (name.endsWith('.xls') ||
        name.endsWith('.xlsx') ||
        name.endsWith('.csv')) {
      return Icons.table_chart;
    }

    if (name.endsWith('.ppt') ||
        name.endsWith('.pptx')) {
      return Icons.slideshow;
    }

    if (name.endsWith('.zip') ||
        name.endsWith('.rar') ||
        name.endsWith('.7z') ||
        name.endsWith('.tar') ||
        name.endsWith('.gz')) {
      return Icons.archive;
    }

    if (name.endsWith('.txt') ||
        name.endsWith('.log') ||
        name.endsWith('.md')) {
      return Icons.article;
    }

    return Icons.insert_drive_file;
  }

  String _documentType(
    String fileName,
  ) {
    final int dot =
        fileName.lastIndexOf('.');

    if (dot == -1) {
      return 'DOCUMENT';
    }

    return fileName
        .substring(dot + 1)
        .toUpperCase();
  }

  List<MediaFile> _visibleFiles() {
    switch (selectedCategory) {
      case HiddenCategory.images:
        return imageFiles;

      case HiddenCategory.videos:
        return videoFiles;

      case HiddenCategory.documents:
        return documentFiles;

      case HiddenCategory.folders:
        return files;

      case HiddenCategory.recentlyDeleted:
        return recentlyDeletedFiles;

      case HiddenCategory.all:
        return files;
    }
  }

  void _selectCategory(
    HiddenCategory category,
  ) {
    setState(() {
      selectedCategory = category;
    });
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required HiddenCategory category,
  }) {
    final bool selected =
        selectedCategory == category;

    final bool recentlyDeleted =
        category ==
            HiddenCategory.recentlyDeleted;

    return Padding(
      padding:
          const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          _selectCategory(category);
        },
        avatar: Icon(
          icon,
          size: 15,
          color: selected
              ? Colors.white
              : recentlyDeleted
                  ? Colors.red.shade700
                  : Colors.grey.shade700,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color: selected
                ? Colors.white
                : recentlyDeleted
                    ? Colors.red.shade700
                    : Colors.grey.shade800,
          ),
        ),
        labelPadding:
            const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 2,
        ),
        materialTapTargetSize:
            MaterialTapTargetSize
                .shrinkWrap,
        visualDensity:
            const VisualDensity(
          horizontal: -2,
          vertical: -2,
        ),
        backgroundColor:
            recentlyDeleted
                ? Colors.red.shade50
                : Colors.grey.shade100,
        selectedColor:
            recentlyDeleted
                ? Colors.red.shade600
                : const Color(0xff512DA8),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : recentlyDeleted
                  ? Colors.red.shade200
                  : Colors.grey.shade300,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCategoryChip(
              label: 'All',
              icon:
                  Icons.grid_view_rounded,
              category:
                  HiddenCategory.all,
            ),
            _buildCategoryChip(
              label: 'Photos',
              icon:
                  Icons.photo_rounded,
              category:
                  HiddenCategory.images,
            ),
            _buildCategoryChip(
              label: 'Docs',
              icon:
                  Icons.description_rounded,
              category:
                  HiddenCategory.documents,
            ),
            _buildCategoryChip(
              label: 'Videos',
              icon:
                  Icons.video_library_rounded,
              category:
                  HiddenCategory.videos,
            ),
            _buildCategoryChip(
              label: 'Recently Deleted',
              icon:
                  Icons.delete_sweep_rounded,
              category:
                  HiddenCategory.recentlyDeleted,
            ),
          ],
        ),
      ),
    );
  }



@override
  Widget build(
    BuildContext context,
  ) {
    final List<MediaFile> visibleFiles =
        _visibleFiles();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hidden Media Finder",
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ==========================================================
          // DASHBOARD
          // ==========================================================

          Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              10,
            ),
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(22),
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xff512DA8),
                  Color(0xff9C27B0),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.folder_off,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            loading
                                ? "Searching Hidden Files"
                                : "Find Hidden Media",
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          const Text(
                            "Scan hidden folders and recover "
                            "media & documents",
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  folder,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================================
          // COMPACT CATEGORY FILTERS
          // ==========================================================

          _buildFilterBar(),

          const SizedBox(
            height: 10,
          ),

          // ==========================================================
          // COMPACT STATISTICS
          // ==========================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _miniStat(
                    Icons.photo_library,
                    "Photos",
                    images,
                    Colors.blue,
                  ),
                ),
                const SizedBox(
                  width: 6,
                ),
                Expanded(
                  child:
                      _miniStat(
                    Icons.video_collection,
                    "Videos",
                    videos,
                    Colors.orange,
                  ),
                ),
                const SizedBox(
                  width: 6,
                ),
                Expanded(
                  child:
                      _miniStat(
                    Icons.description,
                    "Docs",
                    documents,
                    Colors.teal,
                  ),
                ),
                const SizedBox(
                  width: 6,
                ),
                Expanded(
                  child:
                      _miniStat(
                    Icons.folder_off,
                    "Folders",
                    hiddenFolders,
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ==========================================================
          // ACTION BUTTONS
          // ==========================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : scan,
                    icon: const Icon(
                      Icons.search,
                      size: 18,
                    ),
                    label: Text(
                      loading
                          ? "Scanning..."
                          : "Scan Hidden Media",
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        loading
                            ? null
                            : recoverSelected,
                    icon: const Icon(
                      Icons.restore,
                      size: 18,
                    ),
                    label:
                        const Text(
                      "Recover Selected",
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ==========================================================
          // RECENTLY DELETED INFORMATION
          // ==========================================================

          if (selectedCategory ==
              HiddenCategory.recentlyDeleted)
            Container(
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color:
                      Colors.red.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color:
                        Colors.red.shade700,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      "Recently Deleted will be "
                      "populated by Deep Media Scan.",
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 6,
          ),
          // ==========================================================
          // FILE GRID
          // ==========================================================

          Expanded(
            child:
                visibleFiles.isEmpty &&
                        !loading
                    ? _emptyState()
                    : GridView.builder(
                        padding:
                            const EdgeInsets
                                .all(10),
                        itemCount:
                            visibleFiles.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio:
                              0.85,
                        ),
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final MediaFile
                              media =
                              visibleFiles[
                                  index];

                          if (_isDocument(
                            media.fileName,
                          )) {
                            return _buildDocumentCard(
                              media,
                            );
                          }

                          if (media.asset ==
                              null) {
                            return _buildFallbackMediaCard(
                              media,
                            );
                          }

                          return FutureBuilder<
                              Uint8List?>(
                            future: media
                                .asset!
                                .thumbnailDataWithSize(
                              const ThumbnailSize
                                  .square(
                                400,
                              ),
                            ),
                            builder:
                                (
                              context,
                              snapshot,
                            ) {
                              if (!snapshot
                                  .hasData) {
                                return Container(
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .grey
                                        .shade200,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      16,
                                    ),
                                  ),
                                  child:
                                      const Center(
                                    child:
                                        CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    media.selected =
                                        !media.selected;
                                  });
                                },
                                child:
                                    Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                      child:
                                          Image.memory(
                                        snapshot
                                            .data!,
                                        width:
                                            double.infinity,
                                        height:
                                            double.infinity,
                                        fit: BoxFit
                                            .cover,
                                      ),
                                    ),

                                    if (media
                                            .mediaType ==
                                        MediaType
                                            .video)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child:
                                            Container(
                                          padding:
                                              const EdgeInsets
                                                  .all(
                                            6,
                                          ),
                                          decoration:
                                              const BoxDecoration(
                                            color:
                                                Colors.black54,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child:
                                              const Icon(
                                            Icons
                                                .play_arrow,
                                            color:
                                                Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),

                                    if (media.selected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child:
                                            Container(
                                          padding:
                                              const EdgeInsets
                                                  .all(
                                            5,
                                          ),
                                          decoration:
                                              const BoxDecoration(
                                            color:
                                                Colors.green,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child:
                                              const Icon(
                                            Icons
                                                .check,
                                            color:
                                                Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),

                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      right: 6,
                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              8,
                                          vertical:
                                              4,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors.black54,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            Text(
                                          media
                                              .fileName,
                                          maxLines:
                                              1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    IconData icon,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
        horizontal: 4,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(
            width: 4,
          ),
          Column(
            children: [
              Text(
                count.toString(),
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 Widget _buildDocumentCard(
    MediaFile media,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          media.selected =
              !media.selected;
        });
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  _documentIcon(
                    media.fileName,
                  ),
                  size: 72,
                  color: Colors.teal,
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.teal
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    _documentType(
                      media.fileName,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.teal,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                  ),
                  child: Text(
                    media.fileName,
                    maxLines: 2,
                    textAlign:
                        TextAlign.center,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (media.selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.all(
                  5,
                ),
                decoration:
                    const BoxDecoration(
                  color: Colors.green,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackMediaCard(
    MediaFile media,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          media.selected =
              !media.selected;
        });
      },
      child: Stack(
        children: [
          Container(
            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade200,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: Center(
              child: Icon(
                media.mediaType ==
                        MediaType.video
                    ? Icons.video_file
                    : Icons.image,
                size: 65,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ),
          if (media.selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.all(
                  5,
                ),
                decoration:
                    const BoxDecoration(
                  color: Colors.green,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.black54,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
              child: Text(
                media.fileName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 List<MediaFile> removeDuplicates(
    List<MediaFile> mediaList,
  ) {
    final Map<String, MediaFile>
        unique = {};

    for (final MediaFile media
        in mediaList) {
      final String key =
          media.filePath.isNotEmpty
              ? media.filePath
              : "${media.fileName}_${media.filePath.length}";

      if (!unique.containsKey(key)) {
        unique[key] = media;
      }
    }

    return unique.values.toList();
  }

  Widget _emptyState() {
    String title;

    String subtitle;

    IconData icon;

    switch (selectedCategory) {
      case HiddenCategory.images:
        title =
            "No hidden images found";
        subtitle =
            "Run scan to search hidden image files";
        icon =
            Icons.photo_library_outlined;
        break;

      case HiddenCategory.videos:
        title =
            "No hidden videos found";
        subtitle =
            "Run scan to search hidden video files";
        icon =
            Icons.video_library_outlined;
        break;

      case HiddenCategory.documents:
        title =
            "No hidden documents found";
        subtitle =
            "Run scan to search PDF, DOC, TXT and other documents";
        icon =
            Icons.description_outlined;
        break;

      case HiddenCategory.folders:
        title =
            "No hidden folders found";
        subtitle =
            "Run scan to search hidden folders";
        icon = Icons.folder_off;
        break;

      case HiddenCategory.recentlyDeleted:
        title =
            "No recently deleted media";
        subtitle =
            "Deep Media Scan will search accessible trash and recoverable locations.";
        icon =
            Icons.delete_sweep_outlined;
        break;

      case HiddenCategory.all:
        title =
            "No hidden files found";
        subtitle =
            "Run scan to search hidden media and documents";
        icon = Icons.folder_off;
        break;
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
