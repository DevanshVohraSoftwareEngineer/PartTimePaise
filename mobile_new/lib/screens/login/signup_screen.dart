import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../managers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../managers/theme_settings_provider.dart';
import '../../widgets/futuristic_background.dart';
import '../../utils/haptics.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collegeController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = AppConstants.roleWorker;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _collegeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
            college: _collegeController.text.trim().isEmpty
                ? null
                : _collegeController.text.trim(),
          );
      
      if (mounted) {
        // ✨ Magic: Celebrate the signup!
        _confettiController.play();
        
        // Brief delay for user to see the "magic"
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          context.go('/kyc-verification');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.nopeRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
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
          const SizedBox(width: 8),
        ],
      ),
      body: FuturisticBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Create Account',
                  style: AppTheme.heading1.copyWith(
                    color: AppTheme.navyDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join PartTimePaise today',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.grey700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Role selection
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    'I am a:',
                    style: AppTheme.heading3,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Wrap in a ScrollView or ensure constrained for small screens
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.43,
                        child: RadioListTile<String>(
                          title: const Text('Worker', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Find tasks', style: TextStyle(fontSize: 11)),
                          value: AppConstants.roleWorker,
                          groupValue: _selectedRole,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.43,
                        child: RadioListTile<String>(
                          title: const Text('Client', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Post tasks', style: TextStyle(fontSize: 11)),
                          value: AppConstants.roleClient,
                          groupValue: _selectedRole,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Note: You can post tasks and find opportunities regardless of your selection',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.grey500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: Validators.validateName,
                ),
                
                const SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                ),
                
                const SizedBox(height: 16),
                
                // College field (optional)
                TextFormField(
                  controller: _collegeController,
                  decoration: const InputDecoration(
                    labelText: 'College (Optional)',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                
                const SizedBox(height: 32),
                
                // Sign up button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignup,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign Up'),
                ),
                
                const SizedBox(height: 24),
                
                const SizedBox(height: 16),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Login'),
                    ),
                  ],
                ),

                ],
              ),
            ),
          ),
        ),
          
          // ✨ Magic Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.navyMedium,
                Colors.orange,
                Colors.green,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
