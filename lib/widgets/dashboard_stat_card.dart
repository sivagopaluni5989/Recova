import 'package:flutter/material.dart';


class DashboardStatCard extends StatelessWidget {


  final IconData icon;
  final String title;
  final String value;
  final Color color;



  const DashboardStatCard({

    super.key,

    required this.icon,

    required this.title,

    required this.value,

    required this.color,

  });



  @override
  Widget build(BuildContext context) {


    return Container(


      width: 88,


      padding:
          const EdgeInsets.all(8),



      decoration: BoxDecoration(


        color: Colors.white,


        borderRadius:
            BorderRadius.circular(16),



        boxShadow:[


          BoxShadow(

            color: Colors.black12,

            blurRadius:6,

            offset:
            const Offset(0,3),

          ),


        ],


      ),





      child: Column(


        mainAxisSize:
            MainAxisSize.min,



        children:[



          CircleAvatar(


            radius:18,


            backgroundColor:

            color.withValues(alpha:0.15),



            child:

            Icon(

              icon,

              size:20,

              color:color,

            ),


          ),




          const SizedBox(
            height:6,
          ),




          Text(


            value,


            style:
            const TextStyle(

              fontSize:16,

              fontWeight:
              FontWeight.bold,

            ),


          ),




          const SizedBox(
            height:2,
          ),




          Text(


            title,


            maxLines:1,


            overflow:
            TextOverflow.ellipsis,


            style:

            TextStyle(

              color:
              Colors.grey.shade700,


              fontSize:11,


            ),


          ),



        ],


      ),


    );


  }


}
