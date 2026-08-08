import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  static Future<bool> requestMediaPermission() async {

    final statuses = await [
      Permission.photos,
      Permission.videos,
    ].request();

    final photos =
        statuses[Permission.photos]?.isGranted ?? false;

    final videos =
        statuses[Permission.videos]?.isGranted ?? false;

    return photos || videos;
  }
}
