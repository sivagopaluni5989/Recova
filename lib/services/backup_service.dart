import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/backup_file.dart';



class BackupService {



  Future<Directory> _getBackupFolder() async {


    Directory folder;



    if (Platform.isAndroid) {


      folder = Directory(
        "/storage/emulated/0/Recova/Backup",
      );


    } else {


      final directory =
          await getApplicationDocumentsDirectory();


      folder = Directory(
        "${directory.path}/Recova/Backup",
      );


    }




    if(!await folder.exists()) {


      await folder.create(
        recursive:true,
      );


    }



    return folder;


  }






  Future<Directory?> _getRecoveredFolder() async {


    Directory folder;



    if (Platform.isAndroid) {


      folder = Directory(
        "/storage/emulated/0/Recova/Recovered",
      );


    } else {


      final directory =
          await getApplicationDocumentsDirectory();


      folder = Directory(
        "${directory.path}/Recova/Recovered",
      );


    }



    if(await folder.exists()) {


      return folder;


    }



    return null;


  }








  Future<int> createBackup() async {


    final backupFolder =
        await _getBackupFolder();



    final recoveredFolder =
        await _getRecoveredFolder();



    if(recoveredFolder == null) {


      return 0;


    }




    int copied = 0;




    final files =
        await recoveredFolder.list().toList();




    for(final entity in files) {



      if(entity is File) {



        final fileName =
            entity.path.split('/').last;



        final destination =
            File(
              "${backupFolder.path}/$fileName",
            );



        await entity.copy(
          destination.path,
        );



        copied++;



      }


    }



    return copied;


  }










  Future<List<BackupFile>> getBackupFiles() async {



    final folder =
        await _getBackupFolder();




    final List<BackupFile> result = [];




    final files =
        await folder.list().toList();





    for(final entity in files) {



      if(entity is File) {



        final stat =
            await entity.stat();




        result.add(

          BackupFile(

            name:
                entity.path.split('/').last,


            path:
                entity.path,


            size:
                stat.size,

          ),

        );


      }


    }




    return result;


  }




    Future<int> restoreBackup() async {


  final backupFolder =
      await _getBackupFolder();


  if(!await backupFolder.exists()) {

    return 0;

  }



  final files =
      await backupFolder.list().toList();



  final restoreFolder =
      Directory(
        "/storage/emulated/0/Recova/Restored",
      );



  if(!await restoreFolder.exists()) {

    await restoreFolder.create(
      recursive:true,
    );

  }



  int restored = 0;



  for(final entity in files) {


    if(entity is File) {


      String fileName =
          entity.path.split('/').last;



      File destination =
          File(
            "${restoreFolder.path}/$fileName",
          );



      int counter = 1;



      while(await destination.exists()) {


        final dot =
            fileName.lastIndexOf('.');


        String newName;


        if(dot != -1) {


          newName =
              "${fileName.substring(0,dot)}_copy_$counter${fileName.substring(dot)}";


        } else {


          newName =
              "${fileName}_copy_$counter";


        }



        destination =
            File(
              "${restoreFolder.path}/$newName",
            );


        counter++;


      }




      await entity.copy(
        destination.path,
      );



      restored++;


    }


  }



  return restored;


}


}


  
