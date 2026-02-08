import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import '../../managers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account', primaryColor),
          ListTile(
            leading: Icon(Icons.person_rounded, color: primaryColor),
            title: const Text('Profile Information'),
            subtitle: Text(currentUser?.email ?? 'Not available'),
            onTap: () {
              context.push('/profile/edit');
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on_rounded, color: primaryColor),
            title: const Text('Distance Preferences'),
            onTap: () {
              context.push('/profile/distance-preferences');
            },
          ),
          ListTile(
            leading: Icon(Icons.verified_user_rounded, color: primaryColor),
            title: const Text('KYC Verification'),
            onTap: () {
              context.push('/kyc-verification');
            },
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications', primaryColor),
          SwitchListTile(
            secondary: Icon(Icons.notifications_rounded, color: primaryColor),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications for matches and messages'),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Update notification settings
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.task_rounded, color: primaryColor),
            title: const Text('Task Updates'),
            subtitle: const Text('Get notified about task status changes'),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Update task notification settings
            },
          ),

          const Divider(),

          // Privacy Section
          _buildSectionHeader('Privacy', primaryColor),
          ListTile(
            leading: Icon(Icons.visibility_off_rounded, color: primaryColor),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who can see your profile'),
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          ListTile(
            leading: Icon(Icons.block_rounded, color: primaryColor),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage blocked users'),
            onTap: () {
              // TODO: Navigate to blocked users
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance', primaryColor),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_rounded, color: primaryColor),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use a dark and light grey color scheme'),
            value: ref.watch(themeProvider) == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          const Divider(),

          // Support Section
          _buildSectionHeader('Support', primaryColor),
          ListTile(
            leading: Icon(Icons.help_rounded, color: primaryColor),
            title: const Text('Help & Support'),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback_rounded, color: primaryColor),
            title: const Text('Send Feedback'),
            onTap: () {
              // TODO: Open feedback form
            },
          ),
          ListTile(
            leading: Icon(Icons.info_rounded, color: primaryColor),
            title: const Text('About'),
            onTap: () {
              context.push('/about-us');
            },
          ),

          const Divider(),

          // Account Actions
          _buildSectionHeader('Logout', primaryColor),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.nopeRed),
            title: const Text('Sign Out'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.5),
        ),
      ),
    );
  }
}
