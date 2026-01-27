import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';
import '../../managers/theme_provider.dart';
import '../../services/gig_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Information'),
            subtitle: Text(currentUser?.email ?? 'Not available'),
            onTap: () {
              context.push('/profile/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Distance Preferences'),
            onTap: () {
              context.push('/profile/distance-preferences');
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('KYC Verification'),
            onTap: () {
              context.push('/kyc-verification');
            },
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications for matches and messages'),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Update notification settings
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.task),
            title: const Text('Task Updates'),
            subtitle: const Text('Get notified about task status changes'),
            value: true, // TODO: Connect to actual setting
            onChanged: (value) {
              // TODO: Update task notification settings
            },
          ),

          const Divider(),

          // Privacy Section
          _buildSectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('Privacy Settings'),
            subtitle: const Text('Control who can see your profile'),
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage blocked users'),
            onTap: () {
              // TODO: Navigate to blocked users
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Status & Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.bolt, color: Colors.green),
            title: const Text('Online Status (ASAP Mode)'),
            subtitle: const Text('Appear on the radar and receive urgent gig alarms'),
            value: currentUser?.isOnline ?? false,
            onChanged: (val) {
              final gigService = ref.read(gigServiceProvider);
              if (val) {
                gigService.goOnline(context);
              } else {
                gigService.goOffline();
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use a dark and light grey color scheme'),
            value: ref.watch(themeProvider) == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          const Divider(),

          // Support Section
          _buildSectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            onTap: () {
              // TODO: Open feedback form
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              context.push('/about-us');
            },
          ),

          const Divider(),

          // Account Actions
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.navyMedium,
        ),
      ),
    );
  }
}