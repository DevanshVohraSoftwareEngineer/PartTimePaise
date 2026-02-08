import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import '../../managers/theme_settings_provider.dart';
import '../../widgets/futuristic_background.dart';
import '../../utils/haptics.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to PartTimePaise',
      subtitle: 'Connect with local opportunities and earn money doing what you love',
      image: 'assets/images/onboarding_1.png',
      color: AppTheme.superLikeBlue,
    ),
    const OnboardingPage(
      title: 'Find Perfect Tasks',
      subtitle: 'Browse through verified tasks that match your skills and schedule',
      image: 'assets/images/onboarding_2.png',
      color: AppTheme.likeGreen,
    ),
    const OnboardingPage(
      title: 'Bid & Get Hired',
      subtitle: 'Submit competitive bids and get hired for tasks that excite you',
      image: 'assets/images/onboarding_3.png',
      color: AppTheme.boostGold,
    ),
    const OnboardingPage(
      title: 'Safe Payments',
      subtitle: 'Secure payments with escrow protection and easy withdrawals',
      image: 'assets/images/onboarding_4.png',
      color: AppTheme.navyMedium,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FuturisticBackground(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
            
            // ✨ Magic: Theme Toggle
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () {
                  ref.read(themeSettingsProvider.notifier).toggleTheme();
                  AppHaptics.light();
                },
                icon: Icon(
                  ref.watch(themeSettingsProvider).backgroundTheme == BackgroundTheme.thunder 
                      ? Icons.bolt 
                      : Icons.attach_money,
                  color: AppTheme.boostGold,
                ),
              ),
            ),

          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),

          // Page indicators
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index),
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _completeOnboarding
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color,
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Image placeholder (you can replace with actual images)
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(140),
                ),
                child: Icon(
                  _getPageIcon(_currentPage),
                  size: 120,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 48),

              Text(
                page.title,
                style: AppTheme.heading1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                page.subtitle,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.5),
      ),
    );
  }

  IconData _getPageIcon(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Icons.waving_hand;
      case 1:
        return Icons.search;
      case 2:
        return Icons.gavel;
      case 3:
        return Icons.security;
      default:
        return Icons.star;
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _showUserTypeSelection();
  }

  void _completeOnboarding() {
    _showUserTypeSelection();
  }

  void _showUserTypeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserTypeSelectionSheet(),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String image;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
  });
}

class UserTypeSelectionSheet extends ConsumerStatefulWidget {
  const UserTypeSelectionSheet({super.key});

  @override
  ConsumerState<UserTypeSelectionSheet> createState() => _UserTypeSelectionSheetState();
}

class _UserTypeSelectionSheetState extends ConsumerState<UserTypeSelectionSheet> {
  String? _selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How do you want to use PartTimePaise?',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Choose your role to get personalized recommendations',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Client Option
          _buildUserTypeOption(
            'client',
            'I need work done',
            'Post tasks and hire freelancers',
            Icons.business_center,
            AppTheme.superLikeBlue,
          ),

          const SizedBox(height: 16),

          // Worker Option
          _buildUserTypeOption(
            'worker',
            'I want to work',
            'Find tasks and earn money',
            Icons.work,
            AppTheme.likeGreen,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedUserType != null ? _continueToProfileSetup : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _selectedUserType != null
                    ? AppTheme.superLikeBlue
                    : AppTheme.grey400,
              ),
              child: const Text('Continue'),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => _continueAsGuest(),
            child: Text(
              'Continue as Guest',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(
    String type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedUserType == type;

    return InkWell(
      onTap: () => setState(() => _selectedUserType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : AppTheme.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? color : AppTheme.navyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _continueToProfileSetup() {
    // Update user type in auth provider
    ref.read(authProvider.notifier).updateUserType(_selectedUserType!);

    Navigator.pop(context); // Close bottom sheet

    // Navigate to profile setup
    if (_selectedUserType == 'worker') {
      context.push('/profile-setup-worker');
    } else {
      context.push('/profile-setup-client');
    }
  }

  void _continueAsGuest() {
    Navigator.pop(context); // Close bottom sheet
    // Navigate to main app
    context.go('/home');
  }
}

// Worker Profile Setup Screen
class WorkerProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  ConsumerState<WorkerProfileSetupScreen> createState() => _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends ConsumerState<WorkerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  final List<String> _selectedSkills = [];
  String _experienceLevel = 'Beginner';

  final List<String> _availableSkills = [
    'Mobile Development',
    'Web Development',
    'UI/UX Design',
    'Graphic Design',
    'Writing',
    'Marketing',
    'Data Entry',
    'Virtual Assistant',
    'Photography',
    'Video Editing',
    'Translation',
    'Other',
  ];

  @override
  void dispose() {
    _skillsController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your skills',
                style: AppTheme.heading2,
              ),

              const SizedBox(height: 8),

              Text(
                'This helps us find the perfect tasks for you',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
              ),

              const SizedBox(height: 32),

              // Your Skills
              Text(
                'Your Skills',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    backgroundColor: AppTheme.grey100,
                    selectedColor: AppTheme.superLikeBlue.withOpacity(0.1),
                    checkmarkColor: AppTheme.superLikeBlue,
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Experience Level
              Text(
                'Experience Level',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _experienceLevel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ['Beginner', 'Intermediate', 'Expert'].map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _experienceLevel = value!);
                },
              ),

              const SizedBox(height: 32),

              // Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your hourly rate';
                  final rate = int.tryParse(value!);
                  if (rate == null || rate < 50) return 'Rate must be at least ₹50';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Brief Description
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Brief Description',
                  hintText: 'Tell clients about your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a brief description';
                  return null;
                },
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeProfileSetup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Complete Setup'),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip for now',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeProfileSetup() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill')),
      );
      return;
    }

    // Update user profile
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        bio: _experienceController.text,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);
    }

    // Navigate to home
    context.go('/home');
  }
}

// Client Profile Setup Screen (simplified)
class ClientProfileSetupScreen extends ConsumerWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to PartTimePaise'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business_center,
              size: 80,
              color: AppTheme.superLikeBlue,
            ),

            const SizedBox(height: 32),

            Text(
              'Ready to post your first task?',
              style: AppTheme.heading2,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Create tasks, receive bids, and hire the perfect freelancer for your project.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}