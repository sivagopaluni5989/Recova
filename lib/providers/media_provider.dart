import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_file.dart';
import '../services/media_scanner_service.dart';
import '../services/scan_progress_service.dart';
import '../services/recovery_service.dart';
import '../services/recovery_history_service.dart';



class MediaProvider extends ChangeNotifier {



  final MediaScannerService _scanner =
      MediaScannerService();



  final ScanProgressService progressService =
      ScanProgressService();



  final RecoveryService _recoveryService =
      RecoveryService();



  final RecoveryHistoryService _historyService =
      RecoveryHistoryService();





  List<MediaFile> _mediaFiles = [];



  bool _isScanning = false;



  MediaType? _selectedFilter;





  List<MediaFile> get mediaFiles =>
      _mediaFiles;



  bool get isScanning =>
      _isScanning;



  MediaType? get selectedFilter =>
      _selectedFilter;





  List<MediaFile> get filteredFiles {


    if (_selectedFilter == null) {

      return _mediaFiles;

    }



    return _mediaFiles
        .where(

          (file) =>

              file.mediaType ==
                  _selectedFilter,

        )

        .toList();


  }





  int get imageCount =>


      _mediaFiles

          .where(

            (file) =>

                file.mediaType ==
                    MediaType.image,

          )

          .length;





  int get videoCount =>


      _mediaFiles

          .where(

            (file) =>

                file.mediaType ==
                    MediaType.video,

          )

          .length;





  int get documentCount =>


      _mediaFiles

          .where(

            (file) =>

                file.mediaType ==
                    MediaType.document,

          )

          .length;







  Future<void> startScan() async {



    _mediaFiles.clear();



    _selectedFilter = null;



    _isScanning = true;



    notifyListeners();







    _mediaFiles = await _scanner.scanMedia(



      onProgress: (

        percent,

        folder,

        current,

        total,

        images,

        videos,

        documents,

      ) {



        progressService.updateProgress(

          percent,

        );




        progressService.updateImageCount(

          images,

        );




        progressService.updateVideoCount(

          videos,

        );




        progressService.updateDocumentCount(

          documents,

        );




        notifyListeners();



      },


    );







    progressService.updateImageCount(

      imageCount,

    );





    progressService.updateVideoCount(

      videoCount,

    );





    progressService.updateDocumentCount(

      documentCount,

    );





    _isScanning = false;



    notifyListeners();



  }






  void changeFilter(MediaType? type) {


    _selectedFilter = type;



    notifyListeners();


  }






  void toggleSelection(MediaFile file) {


    file.selected =

        !file.selected;



    notifyListeners();


  }






  List<MediaFile> get selectedFiles {


    return _mediaFiles

        .where(

          (file) => file.selected,

        )

        .toList();


  }







  Future<int> recoverSelected() async {



    final files = selectedFiles;





    if (files.isEmpty) {


      return 0;


    }







    final RecoveryResult result =
    await _recoveryService.recoverFiles(
  files,
);

final int recovered = result.recoveredFiles;






    int totalSize = 0;







    for (final file in files) {



      if (file.asset != null) {



        final source =

            await file.asset!.file;





        if (source != null) {



          totalSize +=

              await source.length();



        }





      } else {





        final source =

            File(

              file.filePath,

            );





        if (await source.exists()) {



          totalSize +=

              await source.length();



        }



      }



    }









    await _historyService.saveHistory(



      dateTime:

          DateTime.now(),



      filesRecovered:

          recovered,



      totalSize:

          totalSize,



      folderPath:

          "Smart Media Recovery",



    );







    return recovered;



  }









  void clearFiles() {



    _mediaFiles.clear();



    notifyListeners();



  }






}
