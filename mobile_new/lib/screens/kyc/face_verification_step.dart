import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/face_detection_service.dart';

class FaceVerificationStep extends ConsumerStatefulWidget {
  final Function(File selfie) onVerified;
  final Color textColor;

  const FaceVerificationStep({
    super.key,
    required this.onVerified,
    required this.textColor,
  });

  @override
  ConsumerState<FaceVerificationStep> createState() => _FaceVerificationStepState();
}

class _FaceVerificationStepState extends ConsumerState<FaceVerificationStep> {
  File? _imageFile;
  bool _isVerifying = false;
  String? _error;
  final FaceDetectionService _faceService = FaceDetectionService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50, // Optimize size
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _error = null;
          _isVerifying = true; // Start verification immediately
        });
        
        await _verifyFace();
      }
    } catch (e) {
      setState(() => _error = 'Failed to capture image: $e');
    }
  }

  Future<void> _verifyFace() async {
    if (_imageFile == null) return;

    try {
      final isGenuine = await _faceService.containsGenuineFace(_imageFile!);
      
      if (mounted) {
        setState(() => _isVerifying = false);
        
        if (isGenuine) {
          // Success!
          widget.onVerified(_imageFile!);
        } else {
          setState(() => _error = 'No face detected or face not clear. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = 'Verification failed: $e';
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
            'Step 1: Face Verification',
            style: AppTheme.heading2.copyWith(color: widget.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please take a clear selfie to verify your identity.',
            style: AppTheme.bodyMedium.copyWith(color: widget.textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Image Preview area
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: widget.textColor.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: widget.textColor.withOpacity(0.2)),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Icon(Icons.face_retouching_natural, size: 80, color: widget.textColor.withOpacity(0.3))
                : null,
          ),
          
          const SizedBox(height: 32),

          if (_isVerifying)
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

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _takeSelfie,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textColor, // High contrast button
                foregroundColor: Theme.of(context).scaffoldBackgroundColor, // Text color inverse of bg
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_imageFile == null ? 'Take Selfie' : 'Retake Selfie'),
            ),
          ),
        ],
      ),
    );
  }
}
