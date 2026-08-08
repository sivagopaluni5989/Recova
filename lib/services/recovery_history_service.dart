import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recovery_history.dart';


class RecoveryHistoryService {


  static const String key = "recovery_history";



  Future<List<RecoveryHistory>> getHistory() async {


    final prefs =
        await SharedPreferences.getInstance();



    final data =
        prefs.getStringList(key) ?? [];



    return data.map((item) {


      return RecoveryHistory.fromJson(

        jsonDecode(item),

      );


    }).toList();


  }





  Future<void> saveHistory({

    required DateTime dateTime,

    required int filesRecovered,

    required int totalSize,

    required String folderPath,

  }) async {


    final history = RecoveryHistory(


      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),


      dateTime: dateTime,


      filesRecovered: filesRecovered,


      totalSize: totalSize,


      folderPath: folderPath,


    );



    await addHistory(history);


  }







  Future<int> getTotalRecovered() async {


    final histories =
        await getHistory();



    int total = 0;



    for (final item in histories) {


      total += item.filesRecovered;


    }



    return total;


  }







  Future<void> addHistory(
    RecoveryHistory history,
  ) async {


    final prefs =
        await SharedPreferences.getInstance();



    final histories =
        await getHistory();



    histories.insert(

      0,

      history,

    );



    await prefs.setStringList(


      key,


      histories.map((item) {


        return jsonEncode(

          item.toJson(),

        );


      }).toList(),


    );


  }







  Future<void> clearHistory() async {


    final prefs =
        await SharedPreferences.getInstance();



    await prefs.remove(key);


  }







  String formatSize(int bytes) {


    if (bytes < 1024) {


      return "$bytes B";


    }



    if (bytes < 1024 * 1024) {


      return
          "${(bytes / 1024).toStringAsFixed(2)} KB";


    }



    if (bytes < 1024 * 1024 * 1024) {


      return
          "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";


    }



    return
        "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";


  }


}
