import 'package:flutter/material.dart';


class RecovaFeatureCard extends StatelessWidget {


  final IconData icon;

  final String title;

  final String subtitle;

  final List<Color> colors;

  final String buttonText;

  final VoidCallback? onPressed;



  const RecovaFeatureCard({


    super.key,


    required this.icon,


    required this.title,


    required this.subtitle,


    required this.colors,


    required this.buttonText,


    this.onPressed,


  });




  @override
  Widget build(BuildContext context) {


    return Container(


      margin:

      const EdgeInsets.symmetric(

        horizontal:16,

        vertical:8,

      ),



      padding:

      const EdgeInsets.all(12),




      decoration: BoxDecoration(


        borderRadius:

        BorderRadius.circular(22),




        gradient:

        LinearGradient(


          colors: colors,


          begin:

          Alignment.topLeft,



          end:

          Alignment.bottomRight,


        ),





        boxShadow: const [


          BoxShadow(


            color:

            Colors.black26,


            blurRadius:

            12,


            offset:

            Offset(0,6),


          ),


        ],


      ),




      child: SizedBox(


        height:145,



        child: Column(


          mainAxisAlignment:

          MainAxisAlignment.center,



          children: [



            Icon(


              icon,


              color:

              Colors.white,


              size:

              36,


            ),




            const SizedBox(

              height:6,

            ),




            Text(


              title,


              textAlign:

              TextAlign.center,



              style:

              const TextStyle(


                color:

                Colors.white,



                fontSize:

                18,



                fontWeight:

                FontWeight.bold,


              ),


            ),



            const SizedBox(

              height:4,

            ),



            Text(


              subtitle,


              textAlign:

              TextAlign.center,


              maxLines:1,


              overflow:

              TextOverflow.ellipsis,



              style:

              const TextStyle(


                color:

                Colors.white70,


                fontSize:

                11,


              ),


            ),



            const SizedBox(

              height:8,

            ),

            SizedBox(


              height:38,


              width:

              double.infinity,



              child:

              ElevatedButton.icon(




                onPressed:

                onPressed,




                icon:

                const Icon(


                  Icons.play_arrow,


                  size:18,


                ),




                label:

                Text(


                  buttonText,


                ),




                style:

                ElevatedButton.styleFrom(



                  foregroundColor:

                  colors.first,



                  backgroundColor:

                  Colors.white,



                  padding:

                  const EdgeInsets.symmetric(

                    horizontal:12,

                  ),




                  shape:

                  RoundedRectangleBorder(



                    borderRadius:

                    BorderRadius.circular(12),



                  ),



                ),




              ),



            ),



          ],


        ),


      ),


    );


  }


}
