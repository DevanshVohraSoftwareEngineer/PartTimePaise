import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parttimepaise/config/theme.dart';
import 'package:parttimepaise/services/supabase_service.dart';
import 'package:parttimepaise/managers/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  File? _idCardImage;
  File? _selfieImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isIdCard) async {
    final XFile? image = await _picker.pickImage(
      source: isIdCard ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (isIdCard) {
          _idCardImage = File(image.path);
        } else {
          _selfieImage = File(image.path);
        }
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_idCardImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both ID Card and Selfie')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final userId = ref.read(currentUserProvider)?.id;

      if (userId == null) throw 'User not logged in';

      // 1. Upload Images (Mocking storage path for now or assuming bucket exists)
      // In real app: supabase.client.storage.from('verification').upload(...)
      // Using mock URLs for demo if storage not set up, or try generic upload if bucket 'images' exists
      
      final idCardUrl = await _uploadFile(_idCardImage!, 'id_cards/$userId');
      final selfieUrl = await _uploadFile(_selfieImage!, 'selfies/$userId');

      // 2. Insert into verification table
      await supabase.client.from('id_verifications').insert({
        'user_id': userId,
        'id_card_url': idCardUrl,
        'selfie_url': selfieUrl,
        'status': 'verified', // Auto-verify for demo
        'extracted_data': {'college': 'IIT Delhi', 'name': 'Verified Student'}, // Mock OCR
      });

      // 3. Update Profile
      await supabase.client.from('profiles').update({
         'verified': true,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Verification Successful! Welcome.')),
        );
        context.go('/swipe');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    // Mock upload for stability if no storage bucket
    // In production: await Supabase.instance.client.storage.from('avatars').upload(path, file);
    return 'https://via.placeholder.com/150'; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verify your Student Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'To ensure a safe community, we need to verify your identity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // ID Card Upload
            _buildUploadCard(
              title: '1. Upload Student ID',
              icon: Icons.credit_card,
              image: _idCardImage,
              onTap: () => _pickImage(true),
            ),

            const SizedBox(height: 24),

            // Selfie Upload
            _buildUploadCard(
              title: '2. Take a Selfie',
              icon: Icons.camera_alt,
              image: _selfieImage,
              onTap: () => _pickImage(false),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isUploading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('VERIFY & CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Tap to upload', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
    );
  }
}
