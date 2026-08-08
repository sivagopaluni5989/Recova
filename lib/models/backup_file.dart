class BackupFile {


  final String name;

  final String path;

  final int size;



  BackupFile({

    required this.name,

    required this.path,

    required this.size,

  });



  String get sizeText {


    if(size < 1024) {

      return "$size bytes";

    }


    if(size < 1024 * 1024) {

      return "${(size / 1024).toStringAsFixed(1)} KB";

    }


    return "${(size / (1024 * 1024)).toStringAsFixed(1)} MB";


  }


}
