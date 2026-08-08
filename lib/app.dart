import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';

import 'routes/app_routes.dart';

import 'providers/media_provider.dart';
import 'providers/dashboard_provider.dart';



class SmartMediaRecoveryApp extends StatelessWidget {


  const SmartMediaRecoveryApp({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return MultiProvider(


      providers: [


        ChangeNotifierProvider(

          create: (_) =>
              MediaProvider(),

        ),



        ChangeNotifierProvider(

          create: (_) =>
              DashboardProvider(),

        ),


      ],




      child: MaterialApp(


        debugShowCheckedModeBanner: false,


        title: 'Recova',



        theme:
            AppTheme.lightTheme,



        initialRoute:
            AppRoutes.home,



        routes:
            AppRoutes.routes,



      ),



    );


  }


}
