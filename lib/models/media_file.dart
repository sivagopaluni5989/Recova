import 'package:photo_manager/photo_manager.dart';


enum MediaType {

  image,

  video,

  document,

}



class MediaFile {


  final AssetEntity? asset;


  final String filePath;


  final String fileName;


  final MediaType mediaType;

final String source;

bool selected;


  MediaFile({

  this.asset,

  required this.filePath,

  required this.fileName,

  required this.mediaType,

  this.source = "Gallery",

  this.selected = false,

});


  bool get isVideo =>

      mediaType == MediaType.video;



  bool get isImage =>

      mediaType == MediaType.image;



  bool get isDocument =>

      mediaType == MediaType.document;



  String get type {


    switch(mediaType) {


      case MediaType.image:

        return "Image";


      case MediaType.video:

        return "Video";


      case MediaType.document:

        return "Document";

    }


  }



}
