import 'package:flutter/material.dart';

import '../../models/recovery_history.dart';
import '../../services/recovery_history_service.dart';


class HistoryScreen extends StatefulWidget {

  const HistoryScreen({
    super.key,
  });


  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();

}



class _HistoryScreenState extends State<HistoryScreen> {


  final RecoveryHistoryService _service =
      RecoveryHistoryService();


  List<RecoveryHistory> history = [];


  bool loading = true;



  @override
  void initState() {

    super.initState();

    loadHistory();

  }



  Future<void> loadHistory() async {


    final result =
        await _service.getHistory();


    if (mounted) {

      setState(() {

        history = result;

        loading = false;

      });

    }

  }



  Future<void> clearHistory() async {


    await _service.clearHistory();


    await loadHistory();


  }



  String formatDate(DateTime date) {

    return "${date.day}-${date.month}-${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Recovery History",
        ),


        actions: [

          IconButton(

            icon: const Icon(
              Icons.delete,
            ),


            onPressed:

                history.isEmpty
                    ? null
                    : clearHistory,

          ),

        ],

      ),



      body:


          loading

              ? const Center(

                  child:
                      CircularProgressIndicator(),

                )



              : history.isEmpty


                  ? const Center(

                      child:
                          Text(
                            "No Recovery History",
                          ),

                    )



                  : ListView.builder(

                      padding:
                          const EdgeInsets.all(12),


                      itemCount:
                          history.length,


                      itemBuilder:
                          (context,index) {



                        final item =
                            history[index];



                        return Card(

                          child: Padding(

                            padding:
                                const EdgeInsets.all(12),


                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,


                              children: [


                                Text(

                                  "Date: "
                                  "${formatDate(item.dateTime)}",

                                ),



                                const SizedBox(
                                  height: 8,
                                ),



                                Text(

                                  "Files Recovered: "
                                  "${item.filesRecovered}",

                                ),



                                const SizedBox(
                                  height: 8,
                                ),



                                Text(

                                  "Recovery Size: "
                                  "${_service.formatSize(item.totalSize)}",

                                ),



                                const SizedBox(
                                  height: 8,
                                ),



                                Text(

                                  "Folder:"
                                  "\n${item.folderPath}",

                                ),



                                const SizedBox(
                                  height: 10,
                                ),



                                ElevatedButton.icon(

                                  icon:
                                      const Icon(
                                        Icons.folder_open,
                                      ),


                                  label:
                                      const Text(
                                        "Open Folder",
                                      ),


                                  onPressed: () {


                                    ScaffoldMessenger
                                        .of(context)
                                        .showSnackBar(

                                      SnackBar(

                                        content:
                                            Text(
                                              item.folderPath,
                                            ),

                                      ),

                                    );


                                  },

                                ),


                              ],


                            ),

                          ),


                        );


                      },

                    ),

    );


  }

}
