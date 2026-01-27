import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../services/supabase_service.dart';
import '../../widgets/futuristic_background.dart';
import '../../widgets/glass_card.dart';
import '../../managers/theme_settings_provider.dart';
import '../../utils/haptics.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSocialLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        context.go('/swipe');
      }
    } catch (e) {
      if (mounted) {
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
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading || _isSocialLoading;

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // ✨ Magic: Theme Toggle
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
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(4),
                      child: TextButton.icon(
                        onPressed: () {
                          ref.read(authProvider.notifier).bypass();
                          context.go('/swipe');
                        },
                        icon: const Icon(Icons.bolt, color: Colors.purple),
                        label: const Text(
                          'DEBUG ONLY: DIRECT ACCESS TO APP',
                          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  
                  // Futuristic Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.electric_bolt,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                
                if (authState.sessionUser != null) ...[
                  // Personalized Welcome
                  Text(
                    'Welcome back, ${authState.user?.name.split(' ').first ?? authState.sessionUser!.email!.split('@').first}!',
                    style: AppTheme.heading1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verification Status',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.grey500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // KYC Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (authState.user?.verified ?? false)
                        ? Colors.green.withOpacity(0.05) 
                        : Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (authState.user?.verified ?? false) ? Colors.green : Colors.orange,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          (authState.user?.verified ?? false) ? Icons.verified : Icons.warning_amber_rounded,
                          color: (authState.user?.verified ?? false) ? Colors.green : Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (authState.user?.verified ?? false) ? 'ACCOUNT VERIFIED' : 'KYC PENDING',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: (authState.user?.verified ?? false) ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (authState.user?.verified ?? false)
                            ? 'Your student identity is confirmed. You have full access to the marketplace.' 
                            : 'To ensure campus safety, please upload your College ID and a Real-time Photo.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey700),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (authState.user?.verified ?? false) {
                                context.go('/swipe');
                              } else {
                                context.go('/kyc-verification');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (authState.user?.verified ?? false) ? AppTheme.navyMedium : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              (authState.user?.verified ?? false) ? 'ENTER MARKETPLACE' : 'COMPLETE KYC NOW',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (kDebugMode && !(authState.user?.verified ?? false)) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              final supabase = ref.read(supabaseServiceProvider);
                              await supabase.updateProfile({
                                'verified': true,
                                'name': authState.sessionUser?.email?.split('@').first ?? 'Debug User',
                                'role': authState.user?.role ?? 'worker',
                              });
                              if (mounted) {
                                context.go('/swipe');
                              }
                            },
                            child: const Text('DEBUG: SKIP KYC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Logout/Switch Account option
                  Center(
                    child: TextButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout, color: AppTheme.nopeRed),
                      label: const Text(
                        'Sign out / Switch Account',
                        style: TextStyle(color: AppTheme.nopeRed),
                      ),
                    ),
                  ),
                ] else ...[
                  // Standard Login Header
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: AppTheme.heading1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  GlassCard(
                    child: Column(
                      children: [
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
                          validator: (value) =>
                              Validators.validateRequired(value, 'Password'),
                        ),

                        const SizedBox(height: 12),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Forgot Password?'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (kDebugMode) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).bypass();
                          context.go('/swipe');
                        },
                        icon: const Icon(Icons.flash_on),
                        label: const Text('DEBUG: BYPASS ALL (JUMP TO HOME)', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
