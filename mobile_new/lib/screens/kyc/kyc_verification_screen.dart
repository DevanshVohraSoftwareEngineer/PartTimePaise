import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import 'face_verification_step.dart';
import 'college_id_step.dart';
import 'selfie_id_step.dart';

class KYCVerificationScreen extends ConsumerStatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  ConsumerState<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends ConsumerState<KYCVerificationScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  File? _selfieFile;
  File? _idCardFile;
  File? _selfieWithIdFile;
  String? _idText;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFaceVerified(File selfie) {
    setState(() => _selfieFile = selfie);
    _nextStep();
  }

  void _onIDVerified(File idCard, String text) {
    setState(() {
      _idCardFile = idCard;
      _idText = text;
    });
    _nextStep();
  }

  void _onSelfieIDVerified(File selfieWithId) {
    setState(() => _selfieWithIdFile = selfieWithId);
    _nextStep();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeKYC();
    }
  }

  Future<void> _completeKYC() async {
    if (_selfieFile == null || _idCardFile == null || _selfieWithIdFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification documents missing. Please try again.')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).submitKYC(
        selfie: _selfieFile!,
        idCard: _idCardFile!,
        selfieWithId: _selfieWithIdFile!,
        extractedText: _idText ?? "No text extracted",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC Submitted & Documents Uploaded!')),
        );
        
        // Final refresh and let router handle the rest
        await ref.read(authProvider.notifier).refreshUser();

        // FAIL-SAFE: Explicitly navigate to feed if router doesn't catch up instantly
        if (mounted) {
           context.go('/swipe');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit KYC: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // BW Theme usage
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.luxeBlack : AppTheme.luxeWhite;
    final textColor = isDark ? AppTheme.luxeWhite : AppTheme.luxeBlack;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mandatory Verification',
          style: AppTheme.heading3.copyWith(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // Custom Stepper/Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Face', textColor, isDark),
                Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                _buildStepIndicator(1, 'College ID', textColor, isDark),
                Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                _buildStepIndicator(2, 'Handheld ID', textColor, isDark),
              ],
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce steps
              children: [
                FaceVerificationStep(
                  onVerified: _onFaceVerified,
                  textColor: textColor,
                ),
                CollegeIDStep(
                  onVerified: _onIDVerified, 
                  textColor: textColor,
                ),
                SelfieIDStep(
                  onVerified: _onSelfieIDVerified,
                  textColor: textColor,
                ),
              ],
            ),
          ),
          
          if (ref.watch(authProvider).isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label, Color textColor, bool isDark) {
    final bool isActive = _currentStep >= stepIndex;
    final bool isCompleted = _currentStep > stepIndex;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? (isDark ? AppTheme.luxeWhite : AppTheme.luxeBlack) : Colors.transparent,
            border: Border.all(
              color: isActive ? (isDark ? AppTheme.luxeWhite : AppTheme.luxeBlack) : textColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted 
              ? Icon(Icons.check, size: 16, color: isDark ? AppTheme.luxeBlack : AppTheme.luxeWhite)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? (isDark ? AppTheme.luxeBlack : AppTheme.luxeWhite) : textColor.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? textColor : textColor.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
