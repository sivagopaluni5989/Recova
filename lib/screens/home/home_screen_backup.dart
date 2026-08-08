import '../../widgets/dashboard_stat_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/media_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/app_routes.dart';

import '../hidden_media/hidden_media_screen.dart';
import '../backup_restore/backup_restore_screen.dart';


class HomeScreen extends StatefulWidget {

  const HomeScreen({
    super.key,
  });


  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {


  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {

    if (!mounted) return;

    Provider.of<DashboardProvider>(
      context,
      listen: false,
    ).loadStats();

  });
}




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor: const Color(0xffF2F7FD),


      appBar: AppBar(

        elevation: 0,

        backgroundColor: Colors.transparent,

        centerTitle: true,

        title: const Text(

          "Smart Media Recovery",

          style: TextStyle(

            fontWeight: FontWeight.bold,

            color: Colors.black87,

          ),

        ),

      ),




      body: Container(


        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [

              Color(0xffDCEEFF),

              Color(0xffF7FBFF),

            ],

          ),

        ),




        child: ListView(

          padding: const EdgeInsets.all(18),


          children: [



            Container(

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                borderRadius:
                    BorderRadius.circular(28),


                gradient: const LinearGradient(

                  colors: [

                    Color(0xff0D6EFD),

                    Color(0xff4FA3FF),

                  ],

                ),

              ),



              child: const Row(

                children: [

                  Icon(

                    Icons.security_rounded,

                    color: Colors.white,

                    size: 40,

                  ),


                  SizedBox(
                    width: 20,
                  ),



                  Expanded(

                    child: Text(

                      "Recover Lost Media\n\nScan photos, videos and restore deleted memories.",

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 16,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                ],

              ),

            ),




            const SizedBox(
              height: 30,
            ),




            Consumer2<MediaProvider, DashboardProvider>(

  builder: (

    context,

    media,

    dashboard,

    child,

  ) {


    return Container(

      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),


        boxShadow: const [

          BoxShadow(

            blurRadius: 15,

            offset: Offset(0, 5),

            color: Colors.black12,

          ),

        ],

      ),



      child: Column(

        children: [


          const Text(

            "Recova Recovery Dashboard",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),



          const SizedBox(
            height: 18,
          ),



          Row(

            mainAxisAlignment:
                MainAxisAlignment.spaceAround,


            children: [


              DashboardStatCard(
  icon: Icons.image_rounded,
  title: "Photos",
  value: media.imageCount.toString(),
  color: Colors.blue,
),


             DashboardStatCard(
  icon: Icons.video_library_rounded,
  title: "Videos",
  value: media.videoCount.toString(),
  color: Colors.orange,
),


              DashboardStatCard(
  icon: Icons.description_rounded,
  title: "Documents",
  value: media.documentCount.toString(),
  color: Colors.purple,
),


            ],

          ),



          const SizedBox(
            height: 18,
          ),



          SizedBox(

            width: double.infinity,


          child: ElevatedButton.icon(

  icon: const Icon(
    Icons.search_rounded,
    size: 26,
  ),


  label: const Text(

    "Scan Now",

    style: TextStyle(

      fontSize: 17,

      fontWeight: FontWeight.bold,

    ),

  ),


  style: ElevatedButton.styleFrom(

    backgroundColor:
        const Color(0xff0D6EFD),

    foregroundColor:
        Colors.white,

    elevation: 5,


    shape: RoundedRectangleBorder(

      borderRadius:
          BorderRadius.circular(18),

    ),

  ),



  onPressed: () {


    Navigator.pushNamed(

      context,

      AppRoutes.scanner,

    );


  },

),
          ),


        ],

      ),

    );

  },

),



            const SizedBox(
              height: 20,
            ),



            Consumer<DashboardProvider>(

              builder: (

                context,

                dashboard,

                child,

              ) {


                return Container(

                  padding:
                      const EdgeInsets.all(18),


                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(22),


                    boxShadow: const [

                      BoxShadow(

                        blurRadius: 12,

                        offset: Offset(0, 5),

                        color: Colors.black12,

                      ),

                    ],

                  ),


                  child: Row(

                    children: [


                      const Icon(

                        Icons.restore_rounded,

                        size: 42,

                        color: Colors.green,

                      ),



                      const SizedBox(

                        width: 15,

                      ),



                      Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,


                        children: [


                          const Text(

                            "Recovered Files",

                            style: TextStyle(

                              fontSize: 16,

                              fontWeight:
                                  FontWeight.bold,

                            ),

                          ),



                          Text(

                            dashboard.recoveredCount.toString(),


                            style: const TextStyle(

                              fontSize: 28,

                              fontWeight:
                                  FontWeight.bold,

                            ),

                          ),


                        ],

                      ),


                    ],

                  ),

                );


              },

            ),



            const SizedBox(
              height: 30,
            ),




            _featureCard(

              context,

              Icons.folder_open,

              Colors.blue,

              "Hidden Media Finder",

              "Find hidden photos and videos",

              () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const HiddenMediaScreen(),

                  ),

                );

              },

            ),




            _featureCard(

              context,

              Icons.search,

              Colors.orange,

              "Recoverable Media Scanner",

              "Scan device media",

              () {


                Navigator.pushNamed(

                  context,

                  AppRoutes.scanner,

                );


              },

            ),





            _featureCard(

              context,

              Icons.backup,

              Colors.green,

              "Backup & Restore",

              "Backup recovered files",

              () {


                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const BackupRestoreScreen(),

                  ),

                );


              },

            ),




          ],

        ),

      ),

    );

  }






 
  Widget _featureCard(

    BuildContext context,

    IconData icon,

    Color color,

    String title,

    String subtitle,

    VoidCallback onTap,

  ) {


    return Padding(

      padding:
          const EdgeInsets.only(bottom:18),


      child: InkWell(

        onTap:onTap,


        borderRadius:
            BorderRadius.circular(24),



        child: Container(

          padding:
              const EdgeInsets.all(20),


          decoration: BoxDecoration(

            color:
                Colors.white.withValues(alpha:0.4),


            borderRadius:
                BorderRadius.circular(24),


          ),



          child: Row(

            children: [


              Icon(

                icon,

                color:color,

                size:36,

              ),


              const SizedBox(
                width:18,
              ),



              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,


                  children: [


                    Text(

                      title,

                      style: const TextStyle(

                        fontSize:20,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),


                    Text(subtitle),


                  ],

                ),

              ),



              const Icon(
                Icons.arrow_forward_ios,
              ),


            ],

          ),

        ),

      ),

    );

  }


}
