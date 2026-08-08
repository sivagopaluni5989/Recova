
import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/backup_restore/backup_restore_screen.dart';
import '../screens/history/history_screen.dart';



class AppRoutes {


  static const String home = '/';


  static const String scanner = '/scanner';


  static const String backupRestore = '/backupRestore';


  static const String history = '/history';



  static Map<String, WidgetBuilder> routes = {


    home: (context) =>
        const HomeScreen(),



    scanner: (context) =>
        const ScannerScreen(),



    backupRestore: (context) =>
        const BackupRestoreScreen(),



    history: (context) =>
        const HistoryScreen(),



  };


}
