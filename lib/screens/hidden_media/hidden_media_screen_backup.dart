import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/media_file.dart';
import '../../services/media_scanner_service.dart';


class HiddenMediaScreen extends StatefulWidget {

  const HiddenMediaScreen({super.key});


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



  Future<void> scan() async {

    setState(() {
      loading = true;
    });


    files = await scanner.scanMedia();


    setState(() {
      loading = false;
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


          ElevatedButton(

            onPressed: scan,

            child: const Text(
              "Start Scan",
            ),

          ),



          if (loading)

            const Padding(

              padding: EdgeInsets.all(10),

              child: CircularProgressIndicator(),

            ),



          Expanded(

            child: GridView.builder(


              itemCount: files.length,


              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(

                    crossAxisCount: 3,

                    crossAxisSpacing: 2,

                    mainAxisSpacing: 2,

                  ),



              itemBuilder: (context,index){


                final media = files[index];



                return FutureBuilder(

                  future: media.asset!.thumbnailDataWithSize(
  const ThumbnailSize.square(300),
),


                  builder: (context,snapshot){



                    if (!snapshot.hasData) {


                      return const Card(

                        child: Center(

                          child: CircularProgressIndicator(),

                        ),

                      );

                    }



                    return Card(

                      clipBehavior:
                          Clip.antiAlias,


                      child: Stack(

                        fit: StackFit.expand,


                        children: [



                          Image.memory(

                            snapshot.data!,

                            fit: BoxFit.cover,

                          ),




                          if(media.isVideo)

                            const Align(

                              alignment:
                                  Alignment.center,


                              child: Icon(

                                Icons.play_circle_fill,


                                color: Colors.white,


                                size: 45,

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

}
