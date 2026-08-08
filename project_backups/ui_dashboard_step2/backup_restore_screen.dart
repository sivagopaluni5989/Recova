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
      "No backup available";





  int totalSize = 0;





  @override
  void initState() {


    super.initState();


    loadBackupFiles();


  }







  Future<void> loadBackupFiles() async {



    final files =
        await _backupService.getBackupFiles();




    int size = 0;



    for(final file in files) {

      size += file.size;

    }




    if(!mounted) return;



    setState(() {


      backupFiles = files;


      totalSize = size;



      message = files.isEmpty

          ? "No backup files found"

          : "${files.length} backup file(s) ready";


    });



  }









  Future<void> createBackup() async {


    setState(() {


      loading = true;


      message =
          "Creating backup...";


    });





    final count =
        await _backupService.createBackup();





    await loadBackupFiles();





    if(!mounted) return;



    setState(() {


      loading = false;



      message =
          "Backup completed\nFiles copied: $count";


    });



  }









  Future<void> restoreBackup() async {


    setState(() {


      loading = true;


      message =
          "Restoring files...";


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








  String formatSize(int bytes) {



    if(bytes < 1024) {


      return "$bytes Bytes";


    }


    if(bytes < 1024 * 1024) {


      return
          "${(bytes / 1024).toStringAsFixed(1)} KB";


    }




    return
        "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";


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


              elevation:4,


              shape:
                  RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(20),

                  ),



              child: Padding(


                padding:
                    const EdgeInsets.all(20),




                child: Column(


                  children: [



                    const Icon(

                      Icons.cloud_done,

                      size:60,

                      color:Colors.green,

                    ),





                    const SizedBox(
                      height:10,
                    ),





                    const Text(

                      "Recova Backup",

                      style:
                          TextStyle(

                        fontSize:22,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),




                    const SizedBox(
                      height:15,
                    ),





                    Row(

                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,


                      children: [



                        _infoBox(

                          Icons.folder,

                          "Files",

                          backupFiles.length.toString(),

                        ),





                        _infoBox(

                          Icons.storage,

                          "Size",

                          formatSize(totalSize),

                        ),




                      ],


                    ),



                  ],


                ),


              ),


            ),







            const SizedBox(
              height:20,
            ),







            SizedBox(

              width:
                  double.infinity,


              child:
              ElevatedButton.icon(



                onPressed:
                    loading
                    ? null
                    : createBackup,



                icon:
                    loading

                    ? const SizedBox(

                        width:20,

                        height:20,

                        child:
                        CircularProgressIndicator(

                          strokeWidth:2,

                        ),

                      )


                    : const Icon(
                        Icons.backup,
                      ),




                label:
                    const Text(
                      "Create Backup",
                    ),



              ),


            ),







            const SizedBox(
              height:10,
            ),






            SizedBox(

              width:
                  double.infinity,


              child:
              ElevatedButton.icon(



                onPressed:
                    loading
                    ? null
                    : restoreBackup,



                icon:
                    const Icon(
                      Icons.restore,
                    ),




                label:
                    const Text(
                      "Restore Files",
                    ),



              ),


            ),







            const SizedBox(
              height:20,
            ),







            Text(

              message,


              textAlign:
                  TextAlign.center,


              style:
                  const TextStyle(

                fontWeight:
                    FontWeight.bold,

                fontSize:16,

              ),


            ),








            const SizedBox(
              height:15,
            ),








            Expanded(



              child:

              backupFiles.isEmpty



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



                      child:
                      ListTile(



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








  Widget _infoBox(

      IconData icon,

      String title,

      String value,

      ) {



    return Column(


      children: [



        Icon(
          icon,
          size:30,
        ),




        const SizedBox(
          height:5,
        ),




        Text(

          value,

          style:
              const TextStyle(

            fontWeight:
                FontWeight.bold,

            fontSize:18,

          ),

        ),




        Text(title),



      ],


    );


  }



}
