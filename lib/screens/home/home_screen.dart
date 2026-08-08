import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/media_provider.dart';
import '../../providers/dashboard_provider.dart';

import '../../widgets/dashboard_stat_card.dart';

import '../../routes/app_routes.dart';

import '../hidden_media/hidden_media_screen.dart';
import '../backup_restore/backup_restore_screen.dart';


class HomeScreen extends StatefulWidget {

  const HomeScreen({
    super.key,
  });


  @override
  State<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {


  @override
  void initState() {

    super.initState();


    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      Provider.of<DashboardProvider>(
        context,
        listen:false,
      ).loadStats();

    });

  }




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
          const Color(0xffF5F9FF),


      appBar: AppBar(

        elevation:0,

        backgroundColor:
            Colors.transparent,

        centerTitle:true,


        title: const Text(
          "Recova",
          style: TextStyle(
            color:Colors.black87,
            fontWeight:FontWeight.bold,
            fontSize:22,
          ),
        ),

      ),



      body: ListView(

        padding:
            const EdgeInsets.all(16),


        children:[



          Container(

            padding:
                const EdgeInsets.all(18),


            decoration:BoxDecoration(

              borderRadius:
                  BorderRadius.circular(24),


              gradient:
                  const LinearGradient(

                colors:[

                  Color(0xff1565FF),
                  Color(0xff4DA3FF),

                ],

              ),

            ),



            child:const Row(

              children:[


                Icon(
                  Icons.restore_rounded,
                  color:Colors.white,
                  size:55,
                ),


                SizedBox(width:15),


                Expanded(

                  child:Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,


                    children:[


                      Text(

                        "Recover Memories",

                        style:TextStyle(

                          color:Colors.white,

                          fontSize:20,

                          fontWeight:
                              FontWeight.bold,

                        ),

                      ),


                      SizedBox(height:5),


                      Text(

                        "Photos • Videos • Documents",

                        style:TextStyle(

                          color:Colors.white70,

                          fontSize:14,

                        ),

                      ),


                    ],

                  ),

                ),


              ],

            ),

          ),




          const SizedBox(height:20),




          Consumer2<MediaProvider, DashboardProvider>(

            builder:(context,media,dashboard,child){


              return SingleChildScrollView(

                scrollDirection:
                    Axis.horizontal,


                child:Row(

                  children:[


                    DashboardStatCard(

                      icon:Icons.image,

                      title:"Photos",

                      value:
                          media.imageCount.toString(),

                      color:Colors.blue,

                    ),



                    const SizedBox(width:10),



                    DashboardStatCard(

                      icon:Icons.video_library,

                      title:"Videos",

                      value:
                          media.videoCount.toString(),

                      color:Colors.orange,

                    ),



                    const SizedBox(width:10),



                    DashboardStatCard(

                      icon:Icons.description,

                      title:"Docs",

                      value:
                          media.documentCount.toString(),

                      color:Colors.purple,

                    ),



                    const SizedBox(width:10),



                    DashboardStatCard(

                      icon:Icons.restore,

                      title:"Recovered",

                      value:
                          dashboard.recoveredCount.toString(),

                      color:Colors.green,

                    ),


                  ],

                ),

              );

            },

          ),




          const SizedBox(height:25),




          _featureCard(

            context,

            Icons.folder_open,

            Colors.blue,

            "Hidden Media Finder",

            "Find hidden photos and videos",

            (){

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder:(_)=>
                      const HiddenMediaScreen(),

                ),

              );

            },

          ),




          _featureCard(

            context,

            Icons.search,

            Colors.orange,

            "Recoverable Scanner",

            "Scan deleted media",

            (){


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

            "Protect recovered files",

            (){


              Navigator.push(

                context,

                MaterialPageRoute(

                  builder:(_)=>
                      const BackupRestoreScreen(),

                ),

              );


            },

          ),





          _featureCard(

            context,

            Icons.history,

            Colors.teal,

            "Recovery History",

            "View recovered files history",

            (){


              Navigator.pushNamed(

                context,

                AppRoutes.history,

              );


            },

          ),



        ],

      ),

    );

  }






  Widget _featureCard(

      BuildContext context,

      IconData icon,

      Color color,

      String title,

      String subtitle,

      VoidCallback tap,

      ){



    return Card(

      elevation:3,

      margin:
          const EdgeInsets.only(bottom:15),


      shape:
          RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(20),

      ),



      child:ListTile(

        onTap:tap,


        leading:CircleAvatar(

          backgroundColor:
              color.withValues(alpha:0.15),


          child:Icon(

            icon,

            color:color,

          ),

        ),



        title:Text(

          title,

          style:
              const TextStyle(

            fontWeight:
                FontWeight.bold,

          ),

        ),



        subtitle:
            Text(subtitle),



        trailing:
            const Icon(

              Icons.arrow_forward_ios,

              size:16,

            ),

      ),

    );

  }


}
