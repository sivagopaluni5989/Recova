import 'dart:io';

import '../models/media_file.dart';



class HiddenFolderScannerService {


  final List<String> hiddenLocations = [


    "/DCIM/.thumbnails",


    "/Pictures/.thumbnails",


    "/WhatsApp/Media/.Statuses",


    "/Android/media",


  ];





  Future<List<MediaFile>> scanHiddenFolders({

    Function(
      double progress,
      String folder,
      int current,
      int total,
      int images,
      int videos,
    )? onProgress,


  }) async {


    List<MediaFile> hiddenFiles = [];



    int imageCount = 0;

    int videoCount = 0;



    List<Directory> folders = [];





    for (String path in hiddenLocations) {


      Directory dir = Directory(path);



      if (await dir.exists()) {


        folders.add(dir);


      }


    }





    int totalFolders = folders.length;


    int currentFolder = 0;





    for (Directory folder in folders) {


      currentFolder++;



      await _scanDirectory(

        folder,

        hiddenFiles,

        onFileFound: (file, isVideo) {


          if (isVideo) {

            videoCount++;

          } else {

            imageCount++;

          }



          onProgress?.call(

            currentFolder / totalFolders,

            folder.path,

            currentFolder,

            totalFolders,

            imageCount,

            videoCount,

          );


        },


      );


    }




    return hiddenFiles;


  }








  Future<void> _scanDirectory(

    Directory directory,

    List<MediaFile> result, {

    required Function(
      MediaFile file,
      bool isVideo,
    ) onFileFound,


  }) async {



    try {



      await for (FileSystemEntity entity

          in directory.list(

            recursive: true,

            followLinks: false,

          )) {



        if (entity is File) {



          String extension =

              entity.path
                  .split(".")
                  .last
                  .toLowerCase();





          bool isImage =

              [

                "jpg",

                "jpeg",

                "png",

                "webp",

                "gif",

              ].contains(extension);






          bool isVideo =

              [

                "mp4",

                "mkv",

                "avi",

                "mov",

                "3gp",

              ].contains(extension);



          bool isDocument =
    [
      "pdf",
      "doc",
      "docx",
    ].contains(extension);







          if (isImage || isVideo || isDocument) {



            MediaFile media = MediaFile(

  filePath: entity.path,

  fileName:
      entity.uri.pathSegments.last,

  mediaType:
    isVideo
        ? MediaType.video
        : isDocument
            ? MediaType.document
            : MediaType.image,

  source:
      directory.path,

);


            result.add(media);



            onFileFound(

              media,

              isVideo,

            );


          }


        }



      }





    } catch (e) {


      // Ignore inaccessible folders

    }



  }



}
