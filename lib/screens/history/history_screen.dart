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
  elevation: 0,
  centerTitle: true,
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  title: const Text(
    "Recovery History",
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    if (history.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: "Clear History",
        onPressed: clearHistory,
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


                  ? Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [

      Icon(
        Icons.history,
        size: 80,
        color: Colors.grey,
      ),

      SizedBox(height: 20),

      Text(
        "No Recovery History",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      SizedBox(height: 8),

      Text(
        "Recovered files will appear here.",
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    ],
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
