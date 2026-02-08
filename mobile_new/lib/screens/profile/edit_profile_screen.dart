import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import '../../helpers/location_service.dart';
import '../../helpers/content_filter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _collegeController;
  
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _collegeController = TextEditingController(text: user?.college ?? '');
    _latitude = user?.latitude;
    _longitude = user?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: AppTheme.likeGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services.'),
              backgroundColor: AppTheme.nopeRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // --- Content Safety Check ---
    if (!ContentFilter.isSafe(_nameController.text) || 
        !ContentFilter.isSafe(_bioController.text) ||
        !ContentFilter.isSafe(_cityController.text) ||
        !ContentFilter.isSafe(_collegeController.text)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Prohibited Content', style: TextStyle(color: AppTheme.nopeRed, fontWeight: FontWeight.bold)),
          content: const Text(
            'One or more fields in your profile contain prohibited language or illegal keywords.\n\n'
            'Please remove them to save your changes.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BACK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        college: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      // Update user in provider
      await ref.read(authProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.likeGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // College field
                TextFormField(
                  controller: _collegeController,
                  decoration: const InputDecoration(
                    labelText: 'College',
                    prefixIcon: Icon(Icons.school_outlined),
                    hintText: 'Enter your college name',
                  ),
                ),

                const SizedBox(height: 16),

                // City field
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    hintText: 'Enter your city',
                  ),
                ),

                const SizedBox(height: 16),

                // Location card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppTheme.navyMedium),
                            const SizedBox(width: 8),
                            Text(
                              'Current Location',
                              style: AppTheme.heading3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_latitude != null && _longitude != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.likeGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.likeGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.navyDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.grey200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.grey500,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No location set. Add location to see distances to tasks.',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.grey500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(_isFetchingLocation ? 'Getting location...' : 'Update Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bio field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline),
                    hintText: 'Tell us about yourself',
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.boostGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.boostGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.boostGold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Setting your location helps show accurate distances to nearby tasks.',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.navyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
