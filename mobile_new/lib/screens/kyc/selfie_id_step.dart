import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/face_detection_service.dart';

class SelfieIDStep extends ConsumerStatefulWidget {
  final Function(File selfieWithId) onVerified;
  final Color textColor;

  const SelfieIDStep({
    super.key,
    required this.onVerified,
    required this.textColor,
  });

  @override
  ConsumerState<SelfieIDStep> createState() => _SelfieIDStepState();
}

class _SelfieIDStepState extends ConsumerState<SelfieIDStep> {
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
          _isVerifying = true; 
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
      // For Selfie holding ID, we still want to detect a face.
      final isGenuine = await _faceService.containsGenuineFace(_imageFile!);
      
      if (mounted) {
        setState(() => _isVerifying = false);
        
        if (isGenuine) {
          widget.onVerified(_imageFile!);
        } else {
          setState(() => _error = 'Face not detected. Ensure your face and ID card are clearly visible.');
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
            'Step 3: Selfie with ID',
            style: AppTheme.heading2.copyWith(color: widget.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hold your ID card next to your face and take a clear selfie.',
            style: AppTheme.bodyMedium.copyWith(color: widget.textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Illustration/Guide area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.textColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: widget.textColor.withOpacity(0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure both your face and the ID photo/text are clearly visible in the frame.',
                    style: TextStyle(color: widget.textColor.withOpacity(0.6), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Image Preview area
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: widget.textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.textColor.withOpacity(0.2)),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Icon(Icons.perm_contact_calendar, size: 80, color: widget.textColor.withOpacity(0.3))
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _takeSelfie,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textColor,
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_imageFile == null ? 'Take Selfie with ID' : 'Retake Photo'),
            ),
          ),
        ],
      ),
    );
  }
}
