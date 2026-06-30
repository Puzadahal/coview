import 'package:permission_handler/permission_handler.dart';

class CallPermissionException implements Exception {
  final String message;
  final bool permanentlyDenied;

  const CallPermissionException(
    this.message, {
    this.permanentlyDenied = false,
  });

  @override
  String toString() => message;
}

class CallPermissions {
  CallPermissions._();

  static Future<void> ensureCameraAndMicrophone() async {
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();

    if (camera.isGranted && microphone.isGranted) return;

    final cameraBlocked = camera.isPermanentlyDenied;
    final micBlocked = microphone.isPermanentlyDenied;
    if (cameraBlocked || micBlocked) {
      throw CallPermissionException(
        'Camera and microphone are blocked. Open Settings and allow them for SyncView.',
        permanentlyDenied: true,
      );
    }

    throw CallPermissionException(
      'Camera and microphone permission is required for video calls.',
    );
  }
}
