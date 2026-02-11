import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../managers/auth_provider.dart';
import '../../helpers/content_filter.dart';
import '../../services/meal_ai_service.dart';
import '../../services/supabase_service.dart';
import '../../data_types/task.dart';

class PostTaskScreen extends ConsumerStatefulWidget {
  final String? taskIdToEdit;
  const PostTaskScreen({super.key, this.taskIdToEdit});

  @override
  ConsumerState<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends ConsumerState<PostTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Other Campus Help';
  DateTime? _selectedDeadline;
  String _urgency = 'Flexible';
  String _budgetType = 'Negotiable';
  bool _requireWorkerSelfie = false; // Disabled by default 
  File? _posterSelfie; // Mandatory live selfie
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  final List<String> _categories = [
    'Tutoring & Doubt Clearing',
    'Food & Item Delivery',
    'Dorm/Room Cleaning',
    'Tech & Laptop Support',
    'Society & Event Help',
    'Moving & Luggage Help',
    'Stationary & Prints',
    'Buy/Sell (Campus OLX)',
    'Document & Writing Help',
    'Quick Campus Errands',
    'Other Campus Help'
  ];

  final List<String> _urgencyLevels = [
    'ASAP (60 Mins)',
    'Freelance',
  ];

  final List<String> _budgetTypes = [
    'Negotiable'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskIdToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateTaskData();
      });
    }
  }

  void _populateTaskData() {
    final tasks = ref.read(tasksProvider).tasks;
    final taskToEdit = tasks.firstWhere((t) => t.id == widget.taskIdToEdit, orElse: () => Task.empty());
    
    if (taskToEdit.id.isNotEmpty) {
      setState(() {
        _titleController.text = taskToEdit.title;
        _descriptionController.text = taskToEdit.description;
        _budgetController.text = taskToEdit.budget.toInt().toString();
        _locationController.text = taskToEdit.location ?? '';
        _selectedCategory = taskToEdit.category;
        _budgetType = taskToEdit.budgetType ?? 'Fixed Price';
        _urgency = taskToEdit.urgency == 'asap' ? 'ASAP (60 Mins)' : 'Freelance';
        _selectedDeadline = taskToEdit.deadline;
        _requireWorkerSelfie = taskToEdit.requireSelfie ?? true;
        // Note: For editing, we might not require a new live selfie if one already exists,
        // but for now, we'll stick to the existing logic if provided.
      });
    }
  }

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
      // Freelance (10 Hours)
      _selectedDeadline = now.add(const Duration(hours: 10));
    }
  }

  Future<void> _handleSubmit() async {
    // Check for KYC photo fallback
    final kycSelfie = ref.read(authProvider).user?.selfieUrl;

    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty 
        // || _posterSelfie == null // Disabled mandatory poster selfie
        ) {
      
      String error = 'Please fill in all mandatory fields.';
      // if (_posterSelfie == null) {
      //   error = 'A live selfie is mandatory to post a task for safety.';
      // }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // --- Rate Limiting Check ---
    // 10h Freelance/Buy-Sell, 1h ASAP
    final userId = ref.read(authProvider).user?.id;
    if (
      userId != null) {
      final dbUrgency = _urgency.startsWith('ASAP') ? 'asap' : 'today';
      final cooldownResult = await ref.read(supabaseServiceProvider).checkCooldown(userId, dbUrgency, _selectedCategory);
      
      if (cooldownResult['can_post'] == false) {
         showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('⏳ ${cooldownResult['type_label']} Limit', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              'To reduce spam, you can only post one ${cooldownResult['type_label']} every few hours.\n\n'
              'Please wait ${cooldownResult['wait_time']} before posting another.\n'
              'You can edit your existing task in the "My Tasks" section.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }


    // --- AI Content Moderation (Server-side / API) ---
    setState(() => _isPosting = true);
    
    try {
      final String toAnalyze = "${_titleController.text} . ${_descriptionController.text}";
      final moderationResult = await ref.read(mealAiServiceProvider).moderateText(toAnalyze);
      
      if (moderationResult['is_safe'] == false) {
        setState(() => _isPosting = false);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.luxeDarkGrey : Colors.white,
              title: const Text('🚫 Post Blocked', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Text(
                'Your post was flagged by our safety system.\n\n'
                'Reason: ${moderationResult['reason']}\n'
                'Flagged Content: "${moderationResult['flagged_content']}"\n\n'
                'Please remove any inappropriate content and try again.',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {
      // Optional: Show error or allow to proceed. 
      print("Moderation UI Error: $e");
    }
    
    // Moderation complete, proceeding to task creation

    try {
      // Map UI urgency labels to DB-internal strings
      final dbUrgency = _urgency.startsWith('ASAP') ? 'asap' : 'today';

      // Capture GPS with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final taskData = {
         'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'budget': double.parse(_budgetController.text.trim()),
        'budget_type': _budgetType,
        'deadline': _selectedDeadline?.toIso8601String(),
        'urgency': dbUrgency,
        'location': _locationController.text.trim(),
        'pickup_lat': position.latitude,
        'pickup_lng': position.longitude,
        'require_selfie': _requireWorkerSelfie,
        'images': _selectedImages.map((file) => file.path).toList(),
      };

      if (widget.taskIdToEdit != null) {
        await ref.read(tasksProvider.notifier).updateTask(
          widget.taskIdToEdit!,
          taskData,
        );
      } else {
        await ref.read(tasksProvider.notifier).createTask(
          taskData, 
          verificationImage: _posterSelfie
        );
      }

      // Refresh my tasks to show the changes
      await ref.read(myTasksProvider.notifier).loadMyTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.taskIdToEdit != null ? 'Task updated successfully!' : 'Task posted successfully!')),
        );
        context.go('/swipe');
      }
    } catch (e) {
      setState(() => _isPosting = false);
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
    'Buy/Sell (Student OLX)': Icons.shopping_bag,
    'Other': Icons.more_horiz,
  };

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 120, // Constrain height to approx 2 rows
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          direction: Axis.vertical, // Fill vertically first (columns)
          spacing: 12, // Vertical spacing between items in a column
          runSpacing: 12, // Horizontal spacing between columns
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
        ),
      ),
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
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.electricMedium
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


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
                        decoration: InputDecoration(
                          hintText: 'What do you need help with?',
                          border: const OutlineInputBorder(),
                          errorText: !ContentFilter.isSafe(_titleController.text) ? 'Prohibited content detected' : null,
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
                        decoration: InputDecoration(
                          hintText: 'Describe your task in detail...',
                          border: const OutlineInputBorder(),
                          errorText: !ContentFilter.isSafe(_descriptionController.text) ? 'Prohibited content detected' : null,
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
                                    : 'Flexible timeframe',
                                style: AppTheme.caption.copyWith(color: AppTheme.likeGreen),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Text(
                        'Task Location (Physical Only)',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Enter specific location (e.g. Block A Cafeteria)',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),

                      const SizedBox(height: 24),



                      const SizedBox(height: 24),



                      const SizedBox(height: 32),

                      // Photos section (Optional/Additional)
                      Text(
                        'Task Photos (Additional)',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add photos of the work area or items involved',
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
                          onPressed: (ContentFilter.isSafe(_titleController.text) && 
                                    ContentFilter.isSafe(_descriptionController.text) && 
                                    ContentFilter.isSafe(_locationController.text) &&
                                    !_isPosting) 
                                    ? _handleSubmit : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.likeGreen,
                            disabledBackgroundColor: AppTheme.grey300,
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
                // Live preview card
                _buildTaskPreviewCard(),
              ],
            ),
          ),
          if (_isPosting)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing and Posting...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
