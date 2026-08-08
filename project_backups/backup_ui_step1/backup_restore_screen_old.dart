import 'package:flutter/material.dart';

import '../../models/backup_file.dart';
import '../../services/backup_service.dart';



class BackupRestoreScreen extends StatefulWidget {


  const BackupRestoreScreen({
    super.key,
  });



  @override
  State<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();


}





class _BackupRestoreScreenState
    extends State<BackupRestoreScreen> {



  final BackupService _backupService =
      BackupService();



  List<BackupFile> backupFiles = [];

  bool loading = false;



  String message =
      "No backup files found";







  @override
  void initState() {

    super.initState();

    loadBackupFiles();

  }








  Future<void> loadBackupFiles() async {


    final files =
        await _backupService.getBackupFiles();



    if(!mounted) return;



    setState(() {


      backupFiles = files;


      message =
          files.isEmpty
          ? "No backup files found"
          : "${files.length} backup file(s) found";


    });



  }









  Future<void> createBackup() async {


    setState(() {

      loading = true;

    });



    await _backupService.createBackup();



    await loadBackupFiles();



    if(!mounted) return;



    setState(() {

      loading = false;

    });



  }








  Future<void> restoreBackup() async {


    setState(() {

      loading = true;

    });



    final count =
        await _backupService.restoreBackup();




    if(!mounted) return;



    setState(() {


      loading = false;



      message =
          "Restore completed\nFiles restored: $count";


    });


  }









  @override
  Widget build(BuildContext context) {


    return Scaffold(



      appBar: AppBar(


        title:
            const Text(
              "Backup & Restore",
            ),


        actions: [


          IconButton(

            icon:
                const Icon(
                  Icons.refresh,
                ),


            onPressed:
                loadBackupFiles,


          ),


        ],


      ),






      body: Padding(


        padding:
            const EdgeInsets.all(16),



        child: Column(


          children: [





            Card(


              child: ListTile(


                leading:
                    const Icon(
                      Icons.backup,
                      size:40,
                      color:Colors.green,
                    ),


                title:
                    const Text(
                      "Create Backup",
                    ),


                subtitle:
                    const Text(
                      "Create backup folder",
                    ),



                onTap:
                    loading
                    ? null
                    : createBackup,


              ),


            ),








            Card(


              child: ListTile(


                leading:
                    const Icon(
                      Icons.restore,
                      size:40,
                      color:Colors.blue,
                    ),


                title:
                    const Text(
                      "Restore Files",
                    ),



                subtitle:
                    const Text(
                      "Restore backup files",
                    ),



                onTap:
                    loading
                    ? null
                    : restoreBackup,


              ),


            ),






            const SizedBox(
              height:20,
            ),






            Text(

              message,

              style:
                  const TextStyle(

                    fontSize:16,

                    fontWeight:
                        FontWeight.bold,

                  ),

            ),






            const SizedBox(
              height:15,
            ),








            Expanded(


              child: backupFiles.isEmpty


              ? const Center(

                  child:
                      Text(
                        "Backup list is empty",
                      ),

                )



              : ListView.builder(


                  itemCount:
                      backupFiles.length,



                  itemBuilder:
                      (context,index) {


                    final file =
                        backupFiles[index];



                    return Card(


                      child: ListTile(


                        leading:
                            const Icon(
                              Icons.insert_drive_file,
                            ),



                        title:
                            Text(
                              file.name,
                            ),



                        subtitle:
                            Text(
                              file.sizeText,
                            ),


                      ),


                    );


                  },


                ),


            ),




          ],


        ),


      ),


    );


  }



}
