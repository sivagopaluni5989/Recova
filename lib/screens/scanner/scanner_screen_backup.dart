import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/media_provider.dart';
import '../../widgets/scan_progress_card.dart';
import '../../widgets/media_grid_item.dart';



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





            SizedBox(


              width: double.infinity,


              child: ElevatedButton.icon(


                onPressed:

                    provider.isScanning

                        ? null

                        : () {


                            provider.startScan();


                          },



                icon: const Icon(

                  Icons.search,

                ),



                label: Text(

                  provider.isScanning

                      ? "Scanning..."

                      : "Start Scan",

                ),



              ),


            ),






            const SizedBox(

              height: 10,

            ),





            SizedBox(


              width: double.infinity,


              child: ElevatedButton.icon(



                onPressed:


                    provider.selectedFiles.isEmpty

                        ? null

                        : () async {



                            final count =

                                await provider
                                    .recoverSelected();





                            if (context.mounted) {


                              ScaffoldMessenger.of(context)
                                  .showSnackBar(


                                SnackBar(


                                  content: Text(

                                    "$count files recovered",

                                  ),


                                ),


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



              provider.mediaFiles.isEmpty



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

                          provider.mediaFiles.length,







                      itemBuilder:

                          (context,index) {




                        final media =

                            provider.mediaFiles[index];






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
