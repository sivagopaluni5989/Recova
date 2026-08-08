
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
}



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


  final HiddenFolderScannerService hiddenScanner =
      HiddenFolderScannerService();


  final RecoveryService recoveryService =
    RecoveryService();



  HiddenCategory selectedCategory =
      HiddenCategory.all;



  List<MediaFile> files = [];

  List<MediaFile> imageFiles = [];

  List<MediaFile> videoFiles = [];



  bool loading = false;


  double progress = 0;



  int images = 0;

  int videos = 0;

  int hiddenFolders = 0;



  Set<String> hiddenFolderPaths = {};



  String folder = "Ready";




  Future<void> scan() async {


    setState(() {


      loading = true;

      progress = 0;

      images = 0;

      videos = 0;

      hiddenFolders = 0;

      hiddenFolderPaths.clear();

      files.clear();

      imageFiles.clear();

      videoFiles.clear();

      folder = "Scanning hidden media...";


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


        });


      },


    );





    final hiddenFiles =
        await hiddenScanner.scanHiddenFolders(


      onProgress: (

        percent,

        currentFolder,

        current,

        total,

        imageCount,

        videoCount,

      ) {


        setState(() {


          progress = percent;


          folder =
              "Hidden: $currentFolder";


          hiddenFolderPaths.add(
              currentFolder
          );


        });


      },


    );



    files.addAll(hiddenFiles);



    files = removeDuplicates(files);



    imageFiles = files
        .where(
          (file) =>
              file.mediaType == MediaType.image,
        )
        .toList();



    videoFiles = files
        .where(
          (file) =>
              file.mediaType == MediaType.video,
        )
        .toList();




    setState(() {


      loading = false;


      progress = 1;


      folder = "Scan Completed";


      hiddenFolders =
          hiddenFolderPaths.length;



    });



    if (mounted) {


      ScaffoldMessenger.of(context)
          .showSnackBar(


        SnackBar(

          content: Text(

            "Hidden Scan Complete\n\n"
            "Images: ${imageFiles.length}\n"
            "Videos: ${videoFiles.length}\n"
            "Folders: $hiddenFolders\n"
            "Total: ${files.length}",

          ),

          behavior:
              SnackBarBehavior.floating,


        ),


      );


    }


  }

Future<void> recoverSelected() async {

  final selectedFiles =
      files.where(
        (file) => file.selected,
      ).toList();


  if(selectedFiles.isEmpty){

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content:
        Text("Select files first"),
      ),

    );

    return;

  }



  final count =
      await recoveryService.recoverFiles(
        selectedFiles,
      );



  if(mounted){

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
        Text(
          "$count files recovered successfully",
        ),

      ),

    );

  }

}


  @override
  Widget build(BuildContext context) {


    List<MediaFile> visibleFiles;


    switch(selectedCategory) {


      case HiddenCategory.images:

        visibleFiles = imageFiles;

        break;



      case HiddenCategory.videos:

        visibleFiles = videoFiles;

        break;



      case HiddenCategory.folders:

      case HiddenCategory.all:

        visibleFiles = files;

        break;


    }



    return Scaffold(


      appBar: AppBar(


        title:
            const Text(
              "Hidden Media Finder",
            ),


        centerTitle:true,


      ),




      body:Column(


        children:[




          Container(


            margin:
                const EdgeInsets.all(12),


            padding:
                const EdgeInsets.all(18),



            decoration:BoxDecoration(


              borderRadius:
                  BorderRadius.circular(22),



              gradient:
                  const LinearGradient(


                colors:[


                  Color(0xff512DA8),

                  Color(0xff9C27B0),


                ],


              ),


            ),




            child:Column(


              children:[




                Row(


                  children:[




                    const Icon(


                      Icons.folder_off,


                      color:Colors.white,


                      size:42,


                    ),





                    const SizedBox(
                      width:12,
                    ),





                    Expanded(


                      child:Column(


                        crossAxisAlignment:
                            CrossAxisAlignment.start,



                        children:[



                          Text(


                            loading
                                ? "Searching Hidden Files"
                                : "Find Hidden Media",



                            style:
                                const TextStyle(


                              color:
                                  Colors.white,


                              fontSize:20,


                              fontWeight:
                                  FontWeight.bold,


                            ),



                          ),





                          const SizedBox(
                            height:4,
                          ),





                          const Text(


                            "Scan hidden folders and recover media",



                            style:
                                TextStyle(


                              color:
                                  Colors.white70,


                              fontSize:12,


                            ),



                          ),



                        ],


                      ),



                    ),




                  ],



                ),




                const SizedBox(
                  height:18,
                ),





                LinearProgressIndicator(


                  value:progress,


                  minHeight:8,


                  borderRadius:
                      BorderRadius.circular(20),



                ),




                const SizedBox(
                  height:8,
                ),





                Text(


                  folder,


                  maxLines:1,


                  overflow:
                      TextOverflow.ellipsis,



                  style:
                      const TextStyle(


                    color:
                        Colors.white,


                    fontSize:12,


                  ),



                ),




              ],


            ),



          ),






          Padding(


            padding:
                const EdgeInsets.symmetric(
                  horizontal:12,
                ),




            child:Row(


              children:[



                Expanded(


                  child:_categoryCardButton(


                    Icons.folder_off,


                    "Folders",


                    hiddenFolders,


                    Colors.deepPurple,


                    HiddenCategory.folders,


                  ),



                ),




                const SizedBox(
                  width:10,
                ),





                Expanded(


                  child:_categoryCardButton(


                    Icons.photo_library,


                    "Images",


                    images,


                    Colors.blue,


                    HiddenCategory.images,


                  ),


                ),





                const SizedBox(
                  width:10,
                ),





                Expanded(


                  child:_categoryCardButton(


                    Icons.video_collection,


                    "Videos",


                    videos,


                    Colors.orange,


                    HiddenCategory.videos,


                  ),



                ),




              ],



            ),



          ),





          const SizedBox(
            height:14,
          ),






          Padding(


            padding:
                const EdgeInsets.symmetric(
                  horizontal:12,
                ),



            child:SizedBox(


              width:double.infinity,



              child:ElevatedButton.icon(


                onPressed:
    loading
        ? null
        : scan,


                icon:
                    const Icon(
                      Icons.search,
                    ),



                label:Text(


                  loading
                      ? "Scanning..."
                      : "Scan Hidden Media",


                ),



              ),



            ),



          ),





          const SizedBox(
            height:10,
          ),

        Padding(

padding:
const EdgeInsets.symmetric(
horizontal:12,
),

child:SizedBox(

width:double.infinity,

child:ElevatedButton.icon(

onPressed:
    loading
        ? null
        : recoverSelected,


icon:
const Icon(
Icons.restore,
),


label:
const Text(
"Recover Selected",
),


),

),

),


          Expanded(


            child:


                visibleFiles.isEmpty && !loading


                    ? _emptyState()



                    : GridView.builder(



                        padding:
                            const EdgeInsets.all(10),




                        itemCount:
                            visibleFiles.length,





                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(



                          crossAxisCount:2,



                          crossAxisSpacing:8,



                          mainAxisSpacing:8,



                        ),






                        itemBuilder:
                            (context,index){



                          final media =
                              visibleFiles[index];





                          return FutureBuilder(



                            future:


                                media.asset!
                                    .thumbnailDataWithSize(



                              const ThumbnailSize.square(
                                400,
                              ),



                            ),






                            builder:
                                (context,snapshot){





                              if(!snapshot.hasData){



                                return Container(



                                  decoration:
                                      BoxDecoration(



                                    color:
                                        Colors.grey.shade200,



                                    borderRadius:
                                        BorderRadius.circular(16),



                                  ),





                                  child:
                                      const Center(



                                    child:
                                        CircularProgressIndicator(),



                                  ),



                                );



                              }







                              return GestureDetector(



                                onTap:(){



                                  setState((){



                                    media.selected =
                                        !media.selected;



                                  });



                                },






                                child:Stack(



                                  children:[




                                    ClipRRect(



                                      borderRadius:
                                          BorderRadius.circular(16),




                                      child:Image.memory(



                                        snapshot.data!,



                                        fit:
                                            BoxFit.cover,



                                      ),



                                    ),






                                    if(media.selected)



                                      Positioned(



                                        top:8,



                                        right:8,



                                        child:Container(



                                          padding:
                                              const EdgeInsets.all(5),




                                          decoration:
                                              const BoxDecoration(



                                            color:
                                                Colors.green,



                                            shape:
                                                BoxShape.circle,



                                          ),




                                          child:
                                              const Icon(



                                            Icons.check,



                                            color:
                                                Colors.white,



                                            size:18,



                                          ),



                                        ),



                                      ),






                                    Positioned(



                                      bottom:6,



                                      left:6,



                                      right:6,



                                      child:Container(



                                        padding:
                                            const EdgeInsets.symmetric(



                                          horizontal:8,



                                          vertical:4,



                                        ),






                                        decoration:
                                            BoxDecoration(



                                          color:
                                              Colors.black54,



                                          borderRadius:
                                              BorderRadius.circular(8),



                                        ),





                                        child:Text(



                                          media.fileName,



                                          maxLines:1,



                                          overflow:
                                              TextOverflow.ellipsis,



                                          style:
                                              const TextStyle(



                                            color:
                                                Colors.white,



                                            fontSize:11,



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

  Widget _categoryCardButton(

    IconData icon,

    String title,

    int count,

    Color color,

    HiddenCategory category,

  ) {



    return GestureDetector(



      onTap:(){


        setState((){


          selectedCategory =
              category;


        });


      },



      child:_countCard(

        icon,

        title,

        count,

        color,

      ),



    );



  }







  List<MediaFile> removeDuplicates(

    List<MediaFile> mediaList,

  ){



    final Map<String,MediaFile> unique = {};



    for(var media in mediaList){



      String key =
          "${media.fileName}_${media.filePath.length}";




      if(!unique.containsKey(key)){



        unique[key] = media;



      }



    }



    return unique.values.toList();



  }







  Widget _emptyState(){



    return Center(



      child:Column(



        mainAxisAlignment:
            MainAxisAlignment.center,



        children:[



          Icon(



            Icons.folder_off,



            size:80,



            color:
                Colors.grey.shade400,



          ),




          const SizedBox(
            height:16,
          ),





          const Text(



            "No hidden files found",



            style:
                TextStyle(



              fontSize:18,



              fontWeight:
                  FontWeight.bold,



            ),



          ),




          const SizedBox(
            height:6,
          ),




          const Text(



            "Run scan to search hidden media folders",



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
            vertical:14,
          ),




      decoration:
          BoxDecoration(



        color:
            Colors.white,



        borderRadius:
            BorderRadius.circular(18),



      ),




      child:Column(



        children:[



          Icon(



            icon,



            color:
                color,



            size:32,



          ),





          const SizedBox(
            height:6,
          ),






          Text(



            count.toString(),



            style:
                const TextStyle(



              fontSize:22,



              fontWeight:
                  FontWeight.bold,



            ),



          ),






          Text(title),





        ],



      ),



    );



  }



}

