import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../managers/auth_provider.dart';

class GoogleSignInTestScreen extends ConsumerWidget {
  const GoogleSignInTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.isLoading)
              const CircularProgressIndicator()
            else if (authState.error != null)
              Text(
                'Error: ${authState.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              )
            else if (authState.user != null)
              Column(
                children: [
                  Text('Signed in as: ${authState.user!.email}'),
                  Text('Role: ${authState.user!.role}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('Logout'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _signInWithRole(ref, 'student'),
                    child: const Text('Sign In as Student'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _signInWithRole(ref, 'worker'),
                    child: const Text('Sign In as Worker'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _signInWithRole(WidgetRef ref, String role) async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle(role);
    } catch (e) {
      // Error is handled by the provider
      print('Sign in failed: $e');
    }
  }
}
