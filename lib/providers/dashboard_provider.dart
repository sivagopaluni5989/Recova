import 'package:flutter/material.dart';

import '../services/recovery_history_service.dart';



class DashboardProvider extends ChangeNotifier {


  final RecoveryHistoryService _historyService =
      RecoveryHistoryService();




  int _recoveredCount = 0;




  int get recoveredCount =>
      _recoveredCount;






  DashboardProvider() {

    loadStats();

  }







  Future<void> loadStats() async {


    _recoveredCount =
        await _historyService.getTotalRecovered();




    notifyListeners();


  }




}
