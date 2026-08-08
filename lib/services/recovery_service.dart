import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/media_file.dart';



class RecoveryService {



  Future<int> recoverFiles(
      List<MediaFile> files,
      ) async {



    int recovered = 0;



    Directory? baseDirectory;



    if (Platform.isAndroid) {



      final pictures =
          Directory(
            "/storage/emulated/0/Pictures",
          );



      if (await pictures.exists()) {

        baseDirectory = pictures;

      }



    }



    baseDirectory ??=
        await getApplicationDocumentsDirectory();





    final recoveryFolder =
        Directory(
          "${baseDirectory.path}/Smart Media Recovery",
        );





    final imagesFolder =
        Directory(
          "${recoveryFolder.path}/Images",
        );



    final videosFolder =
        Directory(
          "${recoveryFolder.path}/Videos",
        );



    final documentsFolder =
        Directory(
          "${recoveryFolder.path}/Documents",
        );






    await imagesFolder.create(
      recursive: true,
    );



    await videosFolder.create(
      recursive: true,
    );



    await documentsFolder.create(
      recursive: true,
    );






    for (final media in files) {



      try {



        File? sourceFile;


if (media.asset != null) {


  sourceFile =
      await media.asset!.file;


} else {


  final localFile =
      File(media.filePath);


  if (await localFile.exists()) {

    sourceFile = localFile;

  }


}



if (sourceFile == null) {

  continue;

}





        String fileName =
            media.fileName;






        if (fileName.isEmpty ||
            fileName == "unknown") {



          final time =
              DateTime.now()
                  .millisecondsSinceEpoch;



          if (media.isVideo) {

            fileName =
                "recovered_video_$time.mp4";

          } else if (media.isDocument) {

            fileName =
                "recovered_document_$time.pdf";

          } else {

            fileName =
                "recovered_image_$time.jpg";

          }



        }








        Directory targetFolder;



        if (media.isVideo) {


          targetFolder =
              videosFolder;



        } else if (media.isDocument) {


          targetFolder =
              documentsFolder;



        } else {


          targetFolder =
              imagesFolder;



        }








        File destination =
            File(
              "${targetFolder.path}/$fileName",
            );





        int counter = 1;



        while (await destination.exists()) {



          final name =
              fileName.substring(
                0,
                fileName.lastIndexOf('.'),
              );



          final extension =
              fileName.substring(
                fileName.lastIndexOf('.'),
              );



          destination =
              File(
                "${targetFolder.path}/${name}_$counter$extension",
              );



          counter++;



        }







        await sourceFile.copy(
          destination.path,
        );



        recovered++;




      } catch (e) {



        continue;



      }



    }





    return recovered;



  }



}
