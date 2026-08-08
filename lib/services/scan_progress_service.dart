import 'dart:async';


class ScanProgressService {


  double _progress = 0.0;


  int _imagesFound = 0;


  int _videosFound = 0;


  int _documentsFound = 0;


  bool _isScanning = false;


  Timer? _timer;




  double get progress => _progress;


  int get imagesFound => _imagesFound;


  int get videosFound => _videosFound;


  int get documentsFound => _documentsFound;


  bool get isScanning => _isScanning;





  Stream<Map<String, dynamic>> startScan() async* {


    _reset();


    _isScanning = true;



    while (_progress < 1.0 && _isScanning) {


      await Future.delayed(

        const Duration(milliseconds: 500),

      );



      _progress = (_progress + 0.05)

          .clamp(0.0, 1.0);



      yield {


        "progress": _progress,


        "images": _imagesFound,


        "videos": _videosFound,


        "documents": _documentsFound,


        "isScanning": _isScanning,


      };


    }





    _isScanning = false;



    yield {


      "progress": _progress,


      "images": _imagesFound,


      "videos": _videosFound,


      "documents": _documentsFound,


      "isScanning": false,


    };


  }







  void updateImageCount(int count) {


    _imagesFound = count;


  }





  void updateVideoCount(int count) {


    _videosFound = count;


  }





  void updateDocumentCount(int count) {


    _documentsFound = count;


  }





  void updateProgress(double value) {


    _progress = value.clamp(0.0, 1.0);


  }






  void cancelScan() {


    _isScanning = false;


    _timer?.cancel();


  }







  void _reset() {


    _progress = 0.0;


    _imagesFound = 0;


    _videosFound = 0;


    _documentsFound = 0;


  }






  void dispose() {


    _timer?.cancel();


  }


}
