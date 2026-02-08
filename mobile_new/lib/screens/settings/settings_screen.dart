import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../managers/location_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification settings
  bool _bidNotifications = true;
  bool _taskNotifications = true;
  bool _paymentNotifications = true;
  bool _messageNotifications = true;
  bool _marketingNotifications = false;

  // Privacy settings
  bool _profileVisible = true;
  bool _showOnlineStatus = true;

  // App settings
  String _theme = 'System';
  String _language = 'English';
  bool _biometricAuth = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load settings from local storage or backend
    // For now, using default values
  }

  @override
  Widget build(BuildContext context) {
    final isLocationTracking = ref.watch(locationTrackingProvider);
    final locationManager = ref.watch(locationTrackingManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingItem(
              'Profile Information',
              'Update your personal details and preferences',
              Icons.person,
              () => _navigateToProfile(),
            ),
            _buildSettingItem(
              'Verification',
              'Verify your identity for better trust',
              Icons.verified,
              () => _showVerificationDialog(),
            ),
            _buildSettingItem(
              'Payment Methods',
              'Manage your payment options',
              Icons.payment,
              () => _navigateToPaymentMethods(),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchItem(
              'Bid Notifications',
              'Get notified when someone bids on your tasks',
              Icons.notifications,
              _bidNotifications,
              (value) => setState(() => _bidNotifications = value),
            ),
            _buildSwitchItem(
              'Task Updates',
              'Updates about task progress and completion',
              Icons.task,
              _taskNotifications,
              (value) => setState(() => _taskNotifications = value),
            ),
            _buildSwitchItem(
              'Payment Notifications',
              'Payment received and pending payment alerts',
              Icons.currency_rupee,
              _paymentNotifications,
              (value) => setState(() => _paymentNotifications = value),
            ),
            _buildSwitchItem(
              'Messages',
              'New messages from workers and clients',
              Icons.message,
              _messageNotifications,
              (value) => setState(() => _messageNotifications = value),
            ),
            _buildSwitchItem(
              'Marketing',
              'Tips, promotions, and platform updates',
              Icons.campaign,
              _marketingNotifications,
              (value) => setState(() => _marketingNotifications = value),
            ),

            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionHeader('Privacy & Security'),
            _buildSwitchItem(
              'Profile Visibility',
              'Make your profile visible to other users',
              Icons.visibility,
              _profileVisible,
              (value) => setState(() => _profileVisible = value),
            ),
            _buildSwitchItem(
              'Online Status',
              'Show when you\'re online',
              Icons.circle,
              _showOnlineStatus,
              (value) => setState(() => _showOnlineStatus = value),
            ),
            _buildSwitchItem(
              'Location Access',
              'Allow access to your location for better matches',
              Icons.location_on,
              isLocationTracking,
              (value) async {
                if (value) {
                  await locationManager.startLocationTracking();
                } else {
                  await locationManager.stopLocationTracking();
                }
              },
            ),
            _buildSettingItem(
              'Blocked Users',
              'Manage users you\'ve blocked',
              Icons.block,
              () => _showBlockedUsers(),
            ),
            _buildSettingItem(
              'Data & Privacy',
              'Control how your data is used',
              Icons.privacy_tip,
              () => _showPrivacyPolicy(),
            ),

            const SizedBox(height: 24),

            // App Preferences Section
            _buildSectionHeader('App Preferences'),
            _buildDropdownItem(
              'Theme',
              'Choose your preferred theme',
              Icons.palette,
              _theme,
              ['System', 'Light', 'Dark'],
              (value) => setState(() => _theme = value!),
            ),
            _buildDropdownItem(
              'Language',
              'Select your language',
              Icons.language,
              _language,
              ['English', 'Hindi', 'Spanish', 'French'],
              (value) => setState(() => _language = value!),
            ),
            _buildSwitchItem(
              'Biometric Authentication',
              'Use fingerprint or face unlock',
              Icons.fingerprint,
              _biometricAuth,
              (value) => setState(() => _biometricAuth = value),
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support & Help'),
            _buildSettingItem(
              'Help Center',
              'Find answers to common questions',
              Icons.help,
              () => _showHelpCenter(),
            ),
            _buildSettingItem(
              'Contact Support',
              'Get help from our support team',
              Icons.support,
              () => _showContactSupport(),
            ),
            _buildSettingItem(
              'Report a Problem',
              'Report bugs or issues',
              Icons.report,
              () => _showReportProblem(),
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingItem(
              'App Version',
              '1.0.0',
              Icons.info,
              null,
            ),
            _buildSettingItem(
              'Terms of Service',
              'Read our terms and conditions',
              Icons.description,
              () => _showTermsOfService(),
            ),
            _buildSettingItem(
              'Privacy Policy',
              'Learn how we protect your data',
              Icons.privacy_tip,
              () => _showPrivacyPolicy(),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('Account Actions'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.nopeRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.nopeRed.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildDangerItem(
                    'Deactivate Account',
                    'Temporarily disable your account',
                    () => _showDeactivateDialog(),
                  ),
                  const Divider(color: AppTheme.nopeRed, height: 24),
                  _buildDangerItem(
                    'Delete Account',
                    'Permanently delete your account and data',
                    () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Settings'),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTheme.heading2.copyWith(
          color: AppTheme.navyDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.navyMedium),
      title: Text(title, style: AppTheme.bodyMedium),
      subtitle: Text(subtitle, style: AppTheme.caption.copyWith(color: AppTheme.grey600)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.navyMedium),
      title: Text(title, style: AppTheme.bodyMedium),
      subtitle: Text(subtitle, style: AppTheme.caption.copyWith(color: AppTheme.grey600)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.superLikeBlue,
    );
  }

  Widget _buildDropdownItem(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.navyMedium),
      title: Text(title, style: AppTheme.bodyMedium),
      subtitle: Text(subtitle, style: AppTheme.caption.copyWith(color: AppTheme.grey600)),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDangerItem(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.nopeRed,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.caption.copyWith(color: AppTheme.nopeRed.withOpacity(0.8)),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.nopeRed),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _navigateToProfile() {
    // TODO: Navigate to profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to profile')),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Identity Verification'),
        content: const Text(
          'Verify your identity to build trust with other users. '
          'This helps you get more responses and better opportunities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Start verification process
            },
            child: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentMethods() {
    // TODO: Navigate to payment methods screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to payment methods')),
    );
  }

  void _showBlockedUsers() {
    // TODO: Show blocked users screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked users - Coming soon!')),
    );
  }

  void _showPrivacyPolicy() {
    // TODO: Show privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy - Coming soon!')),
    );
  }

  void _showHelpCenter() {
    // TODO: Show help center
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help center - Coming soon!')),
    );
  }

  void _showContactSupport() {
    // TODO: Show contact support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support - Coming soon!')),
    );
  }

  void _showReportProblem() {
    // TODO: Show report problem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report problem - Coming soon!')),
    );
  }

  void _showTermsOfService() {
    // TODO: Show terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service - Coming soon!')),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Your account will be temporarily disabled. You can reactivate it anytime by logging back in. '
          'Your data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Deactivate account
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.nopeRed,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data, tasks, and bids will be permanently deleted.',
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete account
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.nopeRed,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to local storage and backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }
}