import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/media_file.dart';



class MediaGridItem extends StatefulWidget {


  final MediaFile mediaFile;


  final VoidCallback onTap;



  const MediaGridItem({

    super.key,

    required this.mediaFile,

    required this.onTap,

  });



  @override
  State<MediaGridItem> createState() =>
      _MediaGridItemState();

}




class _MediaGridItemState extends State<MediaGridItem> {


  Uint8List? thumbnail;


  bool loading = true;




  @override
  void initState() {


    super.initState();



    if (!widget.mediaFile.isDocument) {


      loadThumbnail();


    } else {


      loading = false;


    }


  }





  Future<void> loadThumbnail() async {


    try {


      Uint8List? data;




      // PhotoManager media

      if (widget.mediaFile.asset != null) {


        data = await widget.mediaFile.asset!

            .thumbnailDataWithSize(

          const ThumbnailSize(
            400,
            400,
          ),

        );


      }



      // Direct file scanner media

      else {


        final file =
        File(widget.mediaFile.filePath);



        if (await file.exists()) {


          data =
          await file.readAsBytes();


        }


      }





      if (mounted) {


        setState(() {


          thumbnail = data;


          loading = false;


        });


      }




    } catch (e) {


      if (mounted) {


        setState(() {


          loading = false;


        });


      }


    }



  }





  @override
  Widget build(BuildContext context) {


    return GestureDetector(


      onTap: widget.onTap,



      child: AnimatedContainer(


        duration:
        const Duration(milliseconds:250),



        decoration: BoxDecoration(


          borderRadius:
          BorderRadius.circular(14),



          border: Border.all(


            color:

            widget.mediaFile.selected

                ? Colors.blue

                : Colors.transparent,


            width:3,


          ),




          boxShadow:[


            BoxShadow(

              color:
              Colors.black.withValues(alpha:0.15),


              blurRadius:8,


            )


          ],



        ),





        child: ClipRRect(


          borderRadius:
          BorderRadius.circular(11),




          child: Stack(


            fit: StackFit.expand,



            children:[



              _buildPreview(),




              Positioned(


                left:6,


                top:6,


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
                    BorderRadius.circular(12),


                  ),



                  child:
                  Text(


                    widget.mediaFile.type
                        .toUpperCase(),



                    style:
                    const TextStyle(


                      color:
                      Colors.white,


                      fontSize:10,


                      fontWeight:
                      FontWeight.bold,


                    ),


                  ),



                ),


              ),





              if(widget.mediaFile.isVideo)

                Positioned(


                  right:8,


                  bottom:8,


                  child:Container(


                    padding:
                    const EdgeInsets.all(5),



                    decoration:
                    BoxDecoration(


                      color:
                      Colors.black54,


                      borderRadius:
                      BorderRadius.circular(20),


                    ),



                    child:
                    const Icon(


                      Icons.play_arrow,


                      color:
                      Colors.white,


                      size:26,


                    ),



                  ),


                ),





              if(widget.mediaFile.selected)

                const Positioned(


                  right:8,


                  top:8,


                  child:
                  Icon(


                    Icons.check_circle,


                    color:
                    Colors.blue,


                    size:30,


                  ),


                ),



            ],


          ),


        ),


      ),


    );


  }






  Widget _buildPreview(){


    if(widget.mediaFile.isDocument){


      return Container(


        color:
        Colors.grey.shade100,



        child:Column(


          mainAxisAlignment:
          MainAxisAlignment.center,



          children:[



            const Icon(


              Icons.description_rounded,


              size:55,


              color:
              Colors.deepPurple,


            ),




            const SizedBox(height:8),





            Text(


              widget.mediaFile.fileName

                  .split('.')

                  .last

                  .toUpperCase(),



              style:
              const TextStyle(


                fontWeight:
                FontWeight.bold,


              ),


            ),


          ],


        ),


      );


    }






    if(thumbnail != null){



      return Image.memory(


        thumbnail!,


        fit:
        BoxFit.cover,


      );


    }






    return Container(


      color:
      Colors.grey.shade200,



      child:
      loading


          ? const Center(

        child:
        CircularProgressIndicator(),

      )


          :

      const Icon(

        Icons.broken_image,

        size:40,

      ),



    );


  }



}
