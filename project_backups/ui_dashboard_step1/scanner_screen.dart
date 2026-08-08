import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media_file.dart';
import '../../providers/media_provider.dart';

import '../../widgets/media_grid_item.dart';
import '../../widgets/recovery_summary_dialog.dart';


class ScannerScreen extends StatelessWidget {

  const ScannerScreen({
    super.key,
  });


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Recoverable Scanner",
        ),

        centerTitle: true,

      ),



      body: Consumer<MediaProvider>(


        builder:(context, provider, child){


          return Column(


            children:[



              Padding(

                padding:
                    const EdgeInsets.all(16),


                child: Container(


                  padding:
    const EdgeInsets.symmetric(
      vertical:12,
      horizontal:14,
    ),


                  decoration: BoxDecoration(


                    borderRadius:
                        BorderRadius.circular(22),


                    gradient:
                        const LinearGradient(

                      colors:[

                        Color(0xff1565FF),

                        Color(0xff64B5F6),

                      ],

                    ),

                  ),



                  child: Column(


                    children:[



                      const Icon(

                        Icons.search,

                        color:Colors.white,

                        size:38,

                      ),



                      const SizedBox(
                        height:6,
                      ),



                      const Text(

                        "Deep Media Scan",

                        style:
                        TextStyle(

                          color:Colors.white,

                          fontSize:18,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),



                      const SizedBox(
                        height:5,
                      ),



                      const Text(

                        "Find recoverable photos, videos and documents",

                        textAlign:
                        TextAlign.center,

                        style:
                        TextStyle(

                          color:Colors.white70,

                          fontSize:12,

                        ),

                      ),



                      const SizedBox(
                        height:10,
                      ),



                      SizedBox(

                        width:
                        double.infinity,


                        child:
                        ElevatedButton.icon(


                          onPressed:

                              provider.isScanning

                              ? null

                              : (){

                            provider.startScan();

                          },


                          icon:
                          Icon(

                            provider.isScanning

                            ? Icons.hourglass_top

                            : Icons.play_arrow,

                          ),



                          label:
                          Text(

                            provider.isScanning

                            ? "Scanning..."

                            : "START SCAN",

                          ),


                        ),

                      ),


                    ],

                  ),


                ),

              ),





              Padding(

                padding:
                const EdgeInsets.symmetric(
                  horizontal:16,
                ),


                child: Row(


                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,


                  children:[


                    _counter(

                      "Photos",

                      provider.imageCount,

                      Icons.image,

                      Colors.blue,

                    ),



                    _counter(

                      "Videos",

                      provider.videoCount,

                      Icons.video_library,

                      Colors.orange,

                    ),



                    _counter(

                      "Docs",

                      provider.documentCount,

                      Icons.description,

                      Colors.purple,

                    ),


                  ],


                ),

              ),





              const SizedBox(
                height:10,
              ),




              if(provider.isScanning)

                Padding(

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:20,
                  ),

                  child:

                  Column(

                    children:[


                      LinearProgressIndicator(

                        value:
                        provider.progressService.progress,

                      ),


                      const SizedBox(
                        height:5,
                      ),


                      Text(

                        "${(provider.progressService.progress*100).toStringAsFixed(0)} %",

                      ),

                    ],

                  ),

                ),





              Wrap(

                spacing:8,


                children:[


                  FilterChip(

                    label:
                    const Text("All"),

                    selected:
                    provider.selectedFilter == null,

                    onSelected:(_){

                      provider.changeFilter(null);

                    },

                  ),



                  FilterChip(

                    label:
                    const Text("Photos"),

                    selected:
                    provider.selectedFilter ==
                        MediaType.image,


                    onSelected:(_){

                      provider.changeFilter(
                          MediaType.image
                      );

                    },

                  ),

                 FilterChip(

  label:
  const Text("Docs"),


  selected:
  provider.selectedFilter ==
      MediaType.document,


  onSelected:(_){

    provider.changeFilter(
      MediaType.document,
    );

  },

),



                  FilterChip(

                    label:
                    const Text("Videos"),

                    selected:
                    provider.selectedFilter ==
                        MediaType.video,


                    onSelected:(_){

                      provider.changeFilter(
                          MediaType.video
                      );

                    },

                  ),



                ],

              ),





              Expanded(


                child:

                provider.filteredFiles.isEmpty


                ?

                const Center(

                  child:

                  Text(
                    "No media scanned",
                  ),

                )


                :

                GridView.builder(


                  padding:
                  const EdgeInsets.all(8),


                  gridDelegate:

                  const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount:3,

                    crossAxisSpacing:6,

                    mainAxisSpacing:6,

                  ),


                  itemCount:
                  provider.filteredFiles.length,


                  itemBuilder:(context,index){


                    final media =
                    provider.filteredFiles[index];



                    return MediaGridItem(

                      mediaFile:
                      media,

                      onTap:(){

                        provider.toggleSelection(
                          media,
                        );

                      },

                    );


                  },

                ),

              ),





              if(provider.selectedFiles.isNotEmpty)

                Padding(

                  padding:
                  const EdgeInsets.all(12),


                  child:

                  SizedBox(

                    width:
                    double.infinity,


                    child:
                    ElevatedButton.icon(

                      icon:
                      const Icon(
                        Icons.restore,
                      ),


                      label:
                      const Text(
                        "Recover Selected",
                      ),


                      onPressed:() async{


                        await provider.recoverSelected();


                        if(context.mounted){


                          showDialog(

                            context:context,

                            builder:(context){

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

                    ),

                  ),

                ),



            ],

          );


        },


      ),


    );

  }




  Widget _counter(

      String title,

      int count,

      IconData icon,

      Color color,

      ){


    return Column(

      children:[


        CircleAvatar(

          radius:22,

          backgroundColor:
          color.withValues(alpha:0.15),

          child:
          Icon(

            icon,

            color:color,

          ),

        ),


        Text(

          count.toString(),

          style:
          const TextStyle(

            fontWeight:
            FontWeight.bold,

            fontSize:18,

          ),

        ),



        Text(title),


      ],

    );


  }


}
