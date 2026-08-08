class RecoveryHistory {


  final String id;


  final DateTime dateTime;


  final int filesRecovered;


  final int totalSize;


  final String folderPath;



  RecoveryHistory({

    required this.id,

    required this.dateTime,

    required this.filesRecovered,

    required this.totalSize,

    required this.folderPath,

  });



  Map<String, dynamic> toJson() {

    return {

      "id": id,

      "dateTime": dateTime.toIso8601String(),

      "filesRecovered": filesRecovered,

      "totalSize": totalSize,

      "folderPath": folderPath,

    };

  }



  factory RecoveryHistory.fromJson(
      Map<String, dynamic> json) {

    return RecoveryHistory(

      id: json["id"],

      dateTime:
          DateTime.parse(
            json["dateTime"],
          ),

      filesRecovered:
          json["filesRecovered"],

      totalSize:
          json["totalSize"],

      folderPath:
          json["folderPath"],

    );

  }


}
