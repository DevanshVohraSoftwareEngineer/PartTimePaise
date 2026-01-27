import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<bool> containsGenuineFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    
    // We expect exactly one face for a genuine selfie
    if (faces.isEmpty) return false;
    
    // Additional "genuine" checks could be added here (e.g. eye opening, smiling)
    // For now, we just check if a face is detected.
    return faces.isNotEmpty;
  }

  void dispose() {
    _faceDetector.close();
  }
}
