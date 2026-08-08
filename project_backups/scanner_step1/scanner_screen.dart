import '../../widgets/media_grid_item.dart';
import '../../widgets/recovery_summary_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media_file.dart';
import '../../providers/media_provider.dart';
import '../../widgets/scan_progress_card.dart';


class ScannerScreen extends StatelessWidget {
  const ScannerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<MediaProvider>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recoverable Media Scanner",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            ScanProgressCard(

              progress:
                  provider.progressService.progress,

              imagesFound:
                  provider.imageCount,

              videosFound:
                  provider.videoCount,

              documentsFound:
                  provider.progressService.documentsFound,

              isScanning:
                  provider.isScanning,

              onCancel: () {

                provider
                    .progressService
                    .cancelScan();

              },

            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(

              spacing: 8,

              runSpacing: 8,

              children: [

                FilterChip(

                  label: const Text("All"),

                  selected:
                      provider.selectedFilter == null,

                  onSelected: (_) {

                    provider.changeFilter(null);

                  },

                ),

                FilterChip(

                  label: const Text("Photos"),

                  selected:
                      provider.selectedFilter ==
                          MediaType.image,

                  onSelected: (_) {

                    provider.changeFilter(
                      MediaType.image,
                    );

                  },

                ),

                FilterChip(

                  label: const Text("Videos"),

                  selected:
                      provider.selectedFilter ==
                          MediaType.video,

                  onSelected: (_) {

                    provider.changeFilter(
                      MediaType.video,
                    );

                  },

                ),

                FilterChip(

                  label: const Text("Documents"),

                  selected:
                      provider.selectedFilter ==
                          MediaType.document,

                  onSelected: (_) {

                    provider.changeFilter(
                      MediaType.document,
                    );

                  },

                ),

              ],

            ),

            const SizedBox(
              height: 12,
            ),

                                    SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed:

                    provider.selectedFiles.isEmpty

                        ? null

                        : () async {


                            await provider.recoverSelected();


                            if (context.mounted) {


                              showDialog(

                                context: context,

                                builder: (context) {


                                  return RecoverySummaryDialog(

                                    images:
                                        provider.imageCount,

                                    videos:
                                        provider.videoCount,

                                    documents:
                                        provider.documentCount,

                                  );


                                },

                              );


                            }


                          },


                icon: const Icon(

                  Icons.restore,

                ),


                label: const Text(

                  "Recover Selected",

                ),


              ),

            ),


            const SizedBox(
              height: 20,
            ),

                        Expanded(

              child:

                  provider.filteredFiles.isEmpty

                      ? const Center(

                          child: Text(
                            "No media scanned",
                          ),

                        )

                      : GridView.builder(

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(

                            crossAxisCount: 3,

                            crossAxisSpacing: 8,

                            mainAxisSpacing: 8,

                          ),

                          itemCount:
                              provider.filteredFiles.length,

                          itemBuilder:
                              (context, index) {

                            final media =
                                provider.filteredFiles[index];

                            return MediaGridItem(

                              mediaFile: media,

                              onTap: () {

                                provider.toggleSelection(
                                  media,
                                );

                              },

                            );

                          },

                        ),

            ),

          ],

        ),

      ),

    );

  }

}
