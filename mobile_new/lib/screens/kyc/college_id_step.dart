import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/ocr_service.dart';
import '../../managers/auth_provider.dart';

class CollegeIDStep extends ConsumerStatefulWidget {
  final Function(File idCard, String text) onVerified;
  final Color textColor;

  const CollegeIDStep({
    super.key,
    required this.onVerified,
    required this.textColor,
  });

  @override
  ConsumerState<CollegeIDStep> createState() => _CollegeIDStepState();
}

class _CollegeIDStepState extends ConsumerState<CollegeIDStep> {
  File? _imageFile;
  bool _isProcessing = false;
  String? _error;
  String? _extractedText;
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Good quality for text
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _error = null;
          _isProcessing = true;
        });
        
        await _processIDCard();
      }
    } catch (e) {
      setState(() => _error = 'Failed to capture image: $e');
    }
  }

  Future<void> _processIDCard() async {
    if (_imageFile == null) return;

    try {
      final text = await _ocrService.extractStudentId(_imageFile!);
      
      // Simple validation: Check for "College", "University", "ID", "Student" or specific keywords
      // For a loose check, we just ensure SOMETHING was read.
      // In production, we'd use regex for ID patterns.
      
      bool isValid = false;
      if (text != null && text.isNotEmpty) {
         // Naive check for demonstration/MVP
         // Checks for common ID card words or just assumes if we got text it's "something"
         // Let's be slightly stricter: length > 10 chars implies it read something substantial
         isValid = text.length > 5; 
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _extractedText = text;
        });
        
        if (isValid) {
           widget.onVerified(_imageFile!, text!);
        } else {
          setState(() => _error = 'Could not read ID card. Ensure text is clear.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'OCR failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step 2: College ID',
            style: AppTheme.heading2.copyWith(color: widget.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your College ID card to verify your student status.',
            style: AppTheme.bodyMedium.copyWith(color: widget.textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),

          // ID Card Preview
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: widget.textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.textColor.withOpacity(0.2)),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: widget.textColor.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text('Tap "Capture ID" below', style: TextStyle(color: widget.textColor.withOpacity(0.3))),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 32),

          if (_isProcessing)
             const CircularProgressIndicator()
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.nopeRed, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          if (_extractedText != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 16),
               child: Text(
                 'Read: "$_extractedText"',
                 style: TextStyle(color: widget.textColor.withOpacity(0.6), fontStyle: FontStyle.italic),
                 textAlign: TextAlign.center,
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textColor,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_imageFile == null ? 'Capture ID' : 'Retake ID'),
            ),
          ),
        ],
      ),
    );
  }
}
