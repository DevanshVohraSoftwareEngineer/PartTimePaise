import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractStudentId(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    // Common patterns for Student IDs (usually alphanumeric, 6-12 chars)
    // We search the entire text for something that matches or contains the expected ID.
    return recognizedText.text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
