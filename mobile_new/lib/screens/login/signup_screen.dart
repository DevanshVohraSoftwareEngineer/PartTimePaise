import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../managers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../helpers/content_filter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

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

    if (!ContentFilter.isSafe(_nameController.text) || 
        !ContentFilter.isSafe(_collegeController.text)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Prohibited Language', style: TextStyle(color: AppTheme.nopeRed, fontWeight: FontWeight.bold)),
          content: const Text(
            'Your name or college details contain words that are not allowed on this platform.\n\n'
            'Please use professional language to continue.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('EDIT DETAILS'),
            ),
          ],
        ),
      );
      return;
    }

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
        _confettiController.play();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/swipe');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the campus marketplace',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Clean Role Selection
                    Row(
                      children: [
                        _buildRoleButton('Worker', AppConstants.roleWorker),
                        const SizedBox(width: 12),
                        _buildRoleButton('Client', AppConstants.roleClient),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Name
                    _buildTextField(_nameController, 'Full Name', Icons.person_outlined, Validators.validateName),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(_emailController, 'Email', Icons.email_outlined, Validators.validateEmail, TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    // College
                    _buildTextField(_collegeController, 'College (Optional)', Icons.school_outlined, null),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Login', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.black, Colors.grey],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String label, String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, String? Function(String?)? validator, [TextInputType? type]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
