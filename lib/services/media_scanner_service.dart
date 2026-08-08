import 'package:photo_manager/photo_manager.dart';

import '../models/media_file.dart';



class MediaScannerService {



  Future<List<MediaFile>> scanMedia({

    Function(
      double percent,
      String folder,
      int current,
      int total,
      int images,
      int videos,
      int documents,
    )? onProgress,

  }) async {



    final List<MediaFile> mediaFiles = [];



    final permission =
        await PhotoManager.requestPermissionExtend();



    if (!permission.isAuth) {

      return mediaFiles;

    }





    final albums =
        await PhotoManager.getAssetPathList(

          type: RequestType.common,

        );





    int totalFiles = 0;



    for (final album in albums) {

      totalFiles += await album.assetCountAsync;

    }





    int currentFile = 0;

    int imageCount = 0;

    int videoCount = 0;

    int documentCount = 0;





    for (final album in albums) {



      final assets =
          await album.getAssetListRange(

            start: 0,

            end: await album.assetCountAsync,

          );





      for (final asset in assets) {



        currentFile++;





        final file =
            await asset.file;





        if (file != null) {



          final extension =
              file.path.split('.').last.toLowerCase();



          MediaType type;



          if ([

            'jpg',
            'jpeg',
            'png',
            'webp',
            'gif'

          ].contains(extension)) {



            type = MediaType.image;

            imageCount++;



          }



          else if ([

            'mp4',
            'mkv',
            'avi',
            'mov',
            '3gp'

          ].contains(extension)) {



            type = MediaType.video;

            videoCount++;



          }



          else if ([

            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'ppt',
            'pptx',
            'txt',
            'zip'

          ].contains(extension)) {



            type = MediaType.document;

            documentCount++;



          }



          else {



            continue;



          }





          mediaFiles.add(

            MediaFile(

              asset: asset,

              filePath: file.path,

              fileName: file.uri.pathSegments.last,

              mediaType: type,

            ),

          );



        }





        final percent =

            totalFiles == 0

                ? 0.0

                : currentFile / totalFiles;





        onProgress?.call(

          percent,

          album.name,

          currentFile,

          totalFiles,

          imageCount,

          videoCount,

          documentCount,

        );



      }


    }





    return mediaFiles;



  }



}
