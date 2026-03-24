import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DualCameraResult {
  const DualCameraResult({
    this.backPhotoPath,
    this.frontPhotoPath,
  });

  final String? backPhotoPath;
  final String? frontPhotoPath;
}

/// Service to handle manual camera capture, used seamlessly after QR detection.
class CameraCaptureService {
  /// Takes a photo with the back camera, then immediately with the front camera.
  /// Disposes cameras afterwards to avoid conflicts with other plugins.
  Future<DualCameraResult> captureDualPhoto() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return const DualCameraResult(); // No cameras available
    }

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    String? backPath;
    String? frontPath;

    // 1. Capture back photo
    try {
      backPath = await _capturePhotoWithLens(backCamera);
    } catch (e) {
      // Ignore if back camera fails, we still try front
    }

    // 2. Capture front photo
    try {
      frontPath = await _capturePhotoWithLens(frontCamera);
    } catch (e) {
      // Ignore if front camera fails
    }

    return DualCameraResult(
      backPhotoPath: backPath,
      frontPhotoPath: frontPath,
    );
  }

  Future<String> _capturePhotoWithLens(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    // Prepare temp file path
    final dir = await getTemporaryDirectory();
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${camera.lensDirection.name}.jpg';
    final path = p.join(dir.path, filename);

    // Capture the photo
    final xFile = await controller.takePicture();

    // Move to our temp dir explicitly
    final file = File(xFile.path);
    await file.copy(path);
    await file.delete(); // Delete original temp file from camera package

    // Always dispose eagerly
    await controller.dispose();

    return path;
  }
}
