import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';



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



  List<MediaFile> files = [];



  bool loading = false;



  double progress = 0;



  int images = 0;

  int videos = 0;

  int documents = 0;



  String folder = "Ready";







  Future<void> scan() async {


    setState(() {

      loading = true;

      progress = 0;

      images = 0;

      videos = 0;

      documents = 0;

      files.clear();

      folder = "Scanning...";

    });






    files = await scanner.scanMedia(



      onProgress: (

        percent,

        currentFolder,

        current,

        total,

        imageCount,

        videoCount,

        documentCount,

      ) {



        setState(() {


          progress = percent;


          folder = currentFolder;


          images = imageCount;


          videos = videoCount;


          documents = documentCount;


        });



      },


    );







    setState(() {


      loading = false;

      progress = 1.0;


      folder = "Completed";


    });


  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(


        title: const Text(

          "Hidden Media Finder",

        ),


      ),





      body: Column(


        children: [





          Padding(

            padding:
                const EdgeInsets.all(16),


            child: Container(


              padding:
                  const EdgeInsets.all(20),



              decoration: BoxDecoration(


                borderRadius:
                    BorderRadius.circular(24),



                gradient:
                    const LinearGradient(

                  colors:[

                    Color(0xff7B1FA2),

                    Color(0xffCE93D8),

                  ],

                ),


              ),




              child: Column(


                children:[




                  const Icon(

                    Icons.visibility_off,

                    size:55,

                    color:Colors.white,

                  ),





                  const SizedBox(height:10),




                  Text(

                    loading

                    ? "Searching Hidden Media"

                    : "Find Hidden Files",

                    style:
                        const TextStyle(

                      color:Colors.white,

                      fontSize:20,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),





                  const SizedBox(height:15),




                  LinearProgressIndicator(


                    value:progress,


                    minHeight:10,


                    borderRadius:
                        BorderRadius.circular(10),


                  ),




                  const SizedBox(height:10),




                  Text(

                    "${(progress*100).toStringAsFixed(0)} %",

                    style:
                        const TextStyle(

                      color:Colors.white,

                      fontSize:18,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),



                  const SizedBox(height:8),




                  Text(

                    folder,

                    style:
                        const TextStyle(

                      color:Colors.white70,

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


                _countCard(
                  Icons.image,
                  "Images",
                  images,
                  Colors.blue,
                ),



                _countCard(
                  Icons.video_library,
                  "Videos",
                  videos,
                  Colors.orange,
                ),



                _countCard(
                  Icons.description,
                  "Docs",
                  documents,
                  Colors.purple,
                ),


              ],


            ),


          ),





          const SizedBox(height:15),





          ElevatedButton.icon(


            onPressed:
                loading ? null : scan,



            icon:
                const Icon(Icons.search),



            label:
                Text(

                  loading
                  ? "Scanning..."
                  : "Start Scan",

                ),


          ),






          Expanded(


            child:
            GridView.builder(


              padding:
                  const EdgeInsets.all(5),


              itemCount:
                  files.length,



              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount:3,

                crossAxisSpacing:3,

                mainAxisSpacing:3,

              ),



              itemBuilder:(context,index){


                final media =
                    files[index];



                return FutureBuilder(


                  future:
                      media.asset
                      .thumbnailDataWithSize(

                    const ThumbnailSize.square(300),

                  ),



                  builder:(context,snapshot){



                    if(!snapshot.hasData){


                      return const Card(

                        child:
                        Center(

                          child:
                          CircularProgressIndicator(),

                        ),

                      );


                    }





                    return Card(


                      clipBehavior:
                          Clip.antiAlias,


                      child:
                      Image.memory(

                        snapshot.data!,

                        fit:
                        BoxFit.cover,

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






  Widget _countCard(
      IconData icon,
      String title,
      int count,
      Color color,
      ){



    return Column(


      children:[



        CircleAvatar(

          backgroundColor:
              color.withValues(alpha:0.15),


          child:
          Icon(

            icon,

            color:color,

          ),


        ),



        const SizedBox(height:5),



        Text(

          count.toString(),

          style:
          const TextStyle(

            fontWeight:
            FontWeight.bold,

          ),

        ),



        Text(title),



      ],


    );


  }


}
