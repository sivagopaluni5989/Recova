import 'package:flutter/material.dart';

class RecoverySummaryDialog extends StatelessWidget {
  final int images;
  final int videos;
  final int documents;

  const RecoverySummaryDialog({
    super.key,
    required this.images,
    required this.videos,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    final total = images + videos + documents;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          SizedBox(width: 10),
          Text("Recovery Complete"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Text(
            "$total Files Recovered",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _row(Icons.photo, "Photos", images),

          const SizedBox(height: 8),

          _row(Icons.video_collection, "Videos", videos),

          const SizedBox(height: 8),

          _row(Icons.description, "Documents", documents),

          const SizedBox(height: 25),

          const Text(
            "Saved to",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "/Recova/Recovered/",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [

        FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),

      ],
    );
  }

  static Widget _row(
    IconData icon,
    String title,
    int value,
  ) {
    return Row(
      children: [

        Icon(icon),

        const SizedBox(width: 10),

        Expanded(
          child: Text(title),
        ),

        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
