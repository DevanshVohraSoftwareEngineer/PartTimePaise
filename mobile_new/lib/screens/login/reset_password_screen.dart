import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).updatePassword(_passwordController.text.trim());
      
      if (mounted) {
        // Show immediate snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Navigate to professional success screen
        context.go('/auth-success', extra: {
          'title': 'Reset Successful!',
          'message': 'Your password has been reset successfully. You can now login with your new password.',
          'buttonText': 'GO TO LOGIN',
          'targetRoute': '/login',
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.nopeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : AppTheme.navyDark, size: 18),
          onPressed: () {
            ref.read(authProvider.notifier).clearRecoveryFlag();
            context.go('/login');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Heading
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.electricMedium.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: AppTheme.electricMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Set New Password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.navyDark,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure it\'s at least 6 characters and unique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Password Input
                _buildInputField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Enter strong password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscure: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Confirm Password Input
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Repeat new password',
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricMedium,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: AppTheme.electricMedium.withOpacity(0.5),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'RESET PASSWORD',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Secured by Supabase Encryption',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppTheme.navyDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.electricMedium, size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: onToggleObscure,
                  color: Colors.grey,
                )
              : null,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.electricMedium, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
