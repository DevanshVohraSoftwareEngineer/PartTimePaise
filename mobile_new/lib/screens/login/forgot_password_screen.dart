import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../utils/validators.dart';
import '../../managers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.luxeDarkGrey : AppTheme.luxeLightGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 40,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
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
          
          const SizedBox(height: 32),
          
          // Submit button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.likeGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: AppTheme.likeGreen,
          ),
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Check Your Email',
          style: AppTheme.heading1.copyWith(
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}',
          style: AppTheme.bodyLarge.copyWith(
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
