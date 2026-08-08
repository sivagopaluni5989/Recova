import 'package:flutter/material.dart';

class ScanProgressCard extends StatelessWidget {

  final double progress;
  final int imagesFound;
  final int videosFound;
  final int documentsFound;
  final bool isScanning;
  final VoidCallback? onCancel;


  const ScanProgressCard({

    super.key,

    required this.progress,

    required this.imagesFound,

    required this.videosFound,

    required this.documentsFound,

    required this.isScanning,

    this.onCancel,

  });

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.only(bottom: 20),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(24),

        gradient: const LinearGradient(
          colors: [
            Color(0xff667EEA),
            Color(0xff764BA2),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),


        boxShadow: const [

          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0,8),
          )

        ],

      ),


      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [


          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text(
                "Media Scanner",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),


              Icon(

                isScanning
                    ? Icons.search
                    : Icons.check_circle,

                color: Colors.white,

                size: 30,

              ),

            ],

          ),



          const SizedBox(height: 15),



          Text(

            isScanning
                ? "Scanning device storage..."
                : "Scan completed",

            style: const TextStyle(

              color: Colors.white70,

              fontSize: 15,

            ),

          ),



          const SizedBox(height: 20),



          ClipRRect(

            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(

              value: progress,

              minHeight: 12,

              backgroundColor: Colors.white30,

              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),

            ),

          ),



          const SizedBox(height: 10),



          Text(

            "${(progress * 100).toInt()}%",

            style: const TextStyle(

              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),



          const SizedBox(height: 20),



          Row(

  mainAxisAlignment: MainAxisAlignment.spaceAround,

  children: [

    _countItem(
      Icons.photo,
      "Photos",
      imagesFound.toString(),
    ),


    _countItem(
      Icons.video_collection,
      "Videos",
      videosFound.toString(),
    ),


    _countItem(
      Icons.description,
      "Documents",
      documentsFound.toString(),
    ),

  ],

),


          const SizedBox(height: 20),



          if(isScanning)

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed: onCancel,

                icon: const Icon(Icons.stop),

                label: const Text(
                  "Cancel Scan",
                ),

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.white,

                  foregroundColor: Colors.deepPurple,

                  shape: RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(15),

                  ),

                ),

              ),

            )

        ],

      ),

    );

  }



  Widget _countItem(

    IconData icon,

    String title,

    String value,

  ){

    return Column(

      children: [


        Icon(

          icon,

          color: Colors.white,

          size: 32,

        ),


        const SizedBox(height:8),


        Text(

          value,

          style: const TextStyle(

            color: Colors.white,

            fontSize:22,

            fontWeight:FontWeight.bold,

          ),

        ),


        Text(

          title,

          style: const TextStyle(

            color: Colors.white70,

            fontSize:14,

          ),

        ),


      ],

    );

  }

}
