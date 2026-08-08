import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media_file.dart';
import '../../providers/media_provider.dart';

import '../../widgets/media_grid_item.dart';
import '../../widgets/recovery_summary_dialog.dart';
import '../../widgets/recova_feature_card.dart';



class ScannerScreen extends StatelessWidget {


  const ScannerScreen({

    super.key,

  });



  @override
  Widget build(BuildContext context) {


    return Scaffold(



      appBar: AppBar(


        title:

        const Text(

          "Recoverable Scanner",

        ),


        centerTitle:true,


      ),





      body:

      Consumer<MediaProvider>(



        builder:(context, provider, child){



          return Column(



            children:[





              RecovaFeatureCard(



                icon:

                Icons.search,





                title:

                "Deep Media Scan",





                subtitle:

                "Find recoverable photos, videos and documents",





                colors:

                const [



                  Color(0xff1565FF),


                  Color(0xff64B5F6),



                ],





                buttonText:

                provider.isScanning

                    ? "Scanning..."

                    : "START SCAN",





                onPressed:

                provider.isScanning

                    ? null

                    :

                    (){


                  provider.startScan();


                },



              ),








              Padding(


                padding:

                const EdgeInsets.symmetric(

                  horizontal:16,

                ),




                child:Row(



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




                  child:Column(



                    children:[



                      LinearProgressIndicator(



                        value:

                        provider.progressService.progress,


                      ),




                      const SizedBox(

                        height:5,

                      ),




                      Text(



                        "${(provider.progressService.progress * 100).toInt()} %",



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

                    provider.selectedFilter == MediaType.image,



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

                    provider.selectedFilter == MediaType.document,



                    onSelected:(_){


                      provider.changeFilter(

                          MediaType.document

                      );


                    },


                  ),


                  FilterChip(


                    label:

                    const Text("Videos"),



                    selected:

                    provider.selectedFilter == MediaType.video,



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



            ],



          );



        },



      ),





      // NEW: Recover button fixed at bottom

      bottomNavigationBar:



      Consumer<MediaProvider>(



        builder:(context, provider, child){



          if(provider.selectedFiles.isEmpty){



            return const SizedBox.shrink();



          }





          return SafeArea(



            child:Padding(



              padding:

              const EdgeInsets.all(12),




              child:SizedBox(



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



            color:

            color,



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
