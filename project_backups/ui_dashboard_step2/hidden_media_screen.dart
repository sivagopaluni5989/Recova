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



class _HiddenMediaScreenState extends State<HiddenMediaScreen> {


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

      ){

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

      progress = 1;

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


          // COMPACT HEADER CARD

          Container(

            margin:
            const EdgeInsets.all(12),


            padding:
            const EdgeInsets.all(14),


            decoration: BoxDecoration(

              borderRadius:
              BorderRadius.circular(18),


              gradient:
              const LinearGradient(

                colors: [

                  Color(0xff7B1FA2),

                  Color(0xffBA68C8),

                ],

              ),

            ),


            child: Column(

              children: [


                Row(

                  children: [


                    const Icon(

                      Icons.visibility_off,

                      color: Colors.white,

                      size:40,

                    ),


                    const SizedBox(width:12),


                    Expanded(

                      child: Text(

                        loading
                            ? "Searching Hidden Media"
                            : "Find Hidden Files",

                        style:
                        const TextStyle(

                          color:Colors.white,

                          fontSize:18,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                    ),


                  ],

                ),



                const SizedBox(height:12),



                LinearProgressIndicator(

                  value:progress,

                  minHeight:7,

                  borderRadius:
                  BorderRadius.circular(10),

                ),



                const SizedBox(height:5),


                Text(

                  folder,

                  maxLines:1,

                  overflow:
                  TextOverflow.ellipsis,


                  style:
                  const TextStyle(

                    color:
                    Colors.white70,

                    fontSize:12,

                  ),

                ),


              ],

            ),


          ),




          // SMALL STAT CARDS

          Padding(

            padding:
            const EdgeInsets.symmetric(
              horizontal:12,
            ),


            child: Row(

              children: [


                Expanded(

                  child:_countCard(

                    Icons.image,
                    "Images",
                    images,
                    Colors.blue,

                  ),

                ),



                const SizedBox(width:8),



                Expanded(

                  child:_countCard(

                    Icons.video_library,
                    "Videos",
                    videos,
                    Colors.orange,

                  ),

                ),



                const SizedBox(width:8),



                Expanded(

                  child:_countCard(

                    Icons.description,
                    "Docs",
                    documents,
                    Colors.purple,

                  ),

                ),


              ],

            ),

          ),




          const SizedBox(height:12),




          // START SCAN BUTTON

          Padding(

            padding:
            const EdgeInsets.symmetric(
              horizontal:12,
            ),


            child:SizedBox(

              width:double.infinity,


              child:ElevatedButton.icon(

                style:
                ElevatedButton.styleFrom(

                  padding:
                  const EdgeInsets.all(14),

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(14),

                  ),

                ),


                onPressed:
                loading ? null : scan,


                icon:
                const Icon(
                  Icons.search,
                ),


                label:Text(

                  loading
                      ? "Scanning..."
                      : "Start Scan",

                ),

              ),

            ),

          ),





          const SizedBox(height:8),





          Expanded(


            child:GridView.builder(

              padding:
              const EdgeInsets.all(6),


              itemCount:
              files.length,


              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount:3,

                crossAxisSpacing:4,

                mainAxisSpacing:4,

              ),



              itemBuilder:
              (context,index){


                final media =
                files[index];


                return FutureBuilder(


                  future:
                  media.asset
                      .thumbnailDataWithSize(

                    const ThumbnailSize.square(250),

                  ),



                  builder:
                  (context,snapshot){


                    if(!snapshot.hasData){

                      return const Card(

                        child:
                        Center(

                          child:
                          CircularProgressIndicator(),

                        ),

                      );

                    }



                    return ClipRRect(

                      borderRadius:
                      BorderRadius.circular(8),


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


    return Container(

      padding:
      const EdgeInsets.symmetric(
        vertical:10,
      ),


      decoration:
      BoxDecoration(

        color:
        Colors.white,


        borderRadius:
        BorderRadius.circular(14),


        boxShadow:[

          const BoxShadow(

            blurRadius:5,

            color:Colors.black12,

          )

        ],

      ),


      child:Column(

        children:[


          Icon(

            icon,

            color:color,

            size:26,

          ),


          const SizedBox(height:3),


          Text(

            count.toString(),

            style:
            const TextStyle(

              fontWeight:
              FontWeight.bold,

              fontSize:18,

            ),

          ),


          Text(

            title,

            style:
            const TextStyle(

              fontSize:11,

            ),

          ),


        ],

      ),


    );


  }


}
