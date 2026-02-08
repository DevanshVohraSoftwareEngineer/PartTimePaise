import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../helpers/content_filter.dart';

class PostTaskScreen extends ConsumerStatefulWidget {
  const PostTaskScreen({super.key});

  @override
  ConsumerState<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends ConsumerState<PostTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'General Help';
  DateTime? _selectedDeadline;
  String _urgency = 'Flexible';
  String _budgetType = 'Fixed Price';
  bool _remoteWork = false;
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'General Help',
    'Delivery',
    'Cleaning',
    'Tutoring',
    'Tech Support',
    'Moving',
    'Shopping',
    'Pet Care',
    'Gardening',
    'Event Help',
    'Other'
  ];

  final List<String> _urgencyLevels = [
    'ASAP (60 Mins)',
    'Today (10 Hours)',
  ];

  final List<String> _budgetTypes = [
    'Fixed Price',
    'Hourly Rate',
    'Negotiable'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- CHANGED: Deadline is no longer manually selectable for ASAP/Today flow as primary 
  // but we keep the date picker for "Today" just in case they mean a specific time, 
  // though for simplicity requested by user we stick to ASAP vs Today.
  // Actually, user said "remove other time frame".
  // So we probably don't need _selectDeadline unless "Today" implies a specific time?
  // Let's keep it simple: ASAP = +1 hr, Today = End of today (23:59).

  void _updateDeadlineFromUrgency() {
    final now = DateTime.now();
    if (_urgency == 'ASAP (60 Mins)') {
      _selectedDeadline = now.add(const Duration(minutes: 60));
    } else {
      // Today (10 Hours)
      _selectedDeadline = now.add(const Duration(hours: 10));
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        (!_remoteWork && _locationController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // --- Content Safety Check ---
    if (!ContentFilter.isSafe(_titleController.text) || 
        !ContentFilter.isSafe(_descriptionController.text)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Prohibited Content Detected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'Your task title or description contains prohibited language (sexual, abusive, or illegal words).\n\n'
            'Please remove these words to post your task. We maintain a safe environment for all users.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('EDIT TASK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // ✨ Magic: Capture GPS for Proximity Dispatch
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
      } catch (e) {
        print('Location error: $e');
        // Fallback or alert user
      }

      // Map UI urgency labels to DB-internal strings
      final dbUrgency = _urgency.startsWith('ASAP') ? 'asap' : 'today';

      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'budget': double.parse(_budgetController.text.trim()),
        'budget_type': _budgetType,
        'deadline': _selectedDeadline?.toIso8601String(),
        'urgency': dbUrgency,
        'location': _remoteWork ? null : _locationController.text.trim(),
        'pickup_lat': _remoteWork ? null : position?.latitude,
        'pickup_lng': _remoteWork ? null : position?.longitude,
        'remote_work': _remoteWork,
        'images': _selectedImages.map((file) => file.path).toList(),
      };

      await ref.read(tasksProvider.notifier).createTask(taskData);

      // Refresh my tasks to show the newly created task
      await ref.read(myTasksProvider.notifier).loadMyTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task posted successfully!')),
        );
        context.go('/swipe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post task: ${e.toString()}')),
        );
      }
    }
  }

  final Map<String, IconData> _categoryIcons = {
    'General Help': Icons.volunteer_activism,
    'Delivery': Icons.directions_bike,
    'Cleaning': Icons.cleaning_services,
    'Tutoring': Icons.menu_book,
    'Tech Support': Icons.computer,
    'Moving': Icons.local_shipping,
    'Shopping': Icons.shopping_cart,
    'Pet Care': Icons.pets,
    'Gardening': Icons.yard,
    'Event Help': Icons.celebration,
    'Other': Icons.more_horiz,
  };

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categories.map((category) {
        final isSelected = category == _selectedCategory;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.electricMedium : AppTheme.grey100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.electricMedium.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcons[category] ?? Icons.help,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.grey700,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.grey700,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && _selectedImages.length < 5) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && _selectedImages.length < 5) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  Widget _buildUrgencyChips() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _urgencyLevels.map((urgency) {
        final isSelected = urgency == _urgency;
        return ChoiceChip(
          label: Text(urgency),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _urgency = urgency;
                _updateDeadlineFromUrgency();
              });
            }
          },
          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          selectedColor: primaryColor.withOpacity(0.1),
          checkmarkColor: primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetTypeChips() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      children: _budgetTypes.map((type) {
        final isSelected = type == _budgetType;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _budgetType = type;
                  });
                }
              },
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              selectedColor: primaryColor.withOpacity(0.1),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskPreviewCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and urgency
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedCategory,
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _urgency.startsWith('ASAP') ? Colors.red.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _urgency.startsWith('ASAP') ? Colors.red.withOpacity(0.3) : primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _urgency,
                    style: TextStyle(
                      color: _urgency.startsWith('ASAP') ? Colors.red : primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty ? 'Your task title will appear here' : _titleController.text,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _descriptionController.text.isEmpty ? 'Your task description will appear here...' : _descriptionController.text,
                  style: TextStyle(color: primaryColor.withOpacity(0.6), fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Budget and location
                Row(
                  children: [
                    Icon(Icons.currency_rupee, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _budgetController.text.isEmpty ? '₹0' : '₹${_budgetController.text}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_budgetType.toLowerCase()})',
                      style: TextStyle(color: primaryColor.withOpacity(0.4), fontSize: 11),
                    ),
                    const Spacer(),
                    Icon(
                      _remoteWork ? Icons.computer : Icons.location_on,
                      size: 16,
                      color: primaryColor.withOpacity(0.4)
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _remoteWork ? 'Remote work' :
                        _locationController.text.isEmpty ? 'Location not set' : _locationController.text,
                        style: TextStyle(color: primaryColor.withOpacity(0.4), fontSize: 11),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task Card'),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live preview card
            _buildTaskPreviewCard(),

            // Form sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Text(
                    'Task Title',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'What do you need help with?',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                    onChanged: (value) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Category section
                  Text(
                    'Category',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),

                  const SizedBox(height: 24),

                  // Description section
                  Text(
                    'Description',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Describe your task in detail...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (value) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Budget section
                  Text(
                    'Budget',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetTypeChips(),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _budgetController,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Urgency section
                  Text(
                    'When do you need this done?',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  _buildUrgencyChips(),

                  // Auto-calculated deadline display
                  if (_selectedDeadline != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.likeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppTheme.likeGreen),
                          const SizedBox(width: 8),
                          Text(
                            _urgency.startsWith('ASAP') 
                                ? 'Task expires in 60 minutes' 
                                : 'Task expires in 10 hours',
                            style: AppTheme.caption.copyWith(color: AppTheme.likeGreen),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Location section
                  Text(
                    'Location',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _remoteWork,
                        onChanged: (value) {
                          setState(() {
                            _remoteWork = value ?? false;
                          });
                        },
                      ),
                      const Text('This can be done remotely'),
                    ],
                  ),

                  if (!_remoteWork) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Enter location',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Photos section
                  Text(
                    'Photos (Optional)',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add photos to help workers understand your task better',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedImages.isEmpty) ...[
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.grey300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_camera, size: 48, color: AppTheme.grey400),
                          const SizedBox(height: 8),
                          Text(
                            'No photos added yet',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey500),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Post button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.likeGreen,
                      ),
                      child: const Text(
                        'Post Task Card',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
