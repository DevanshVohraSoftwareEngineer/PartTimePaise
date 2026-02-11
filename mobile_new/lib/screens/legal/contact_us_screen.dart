import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@happle.com',
      queryParameters: {
        'subject': 'Support Request - Happle App',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Handle error - could show a snackbar
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required String contactInfo,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contactInfo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We\'re here to help! Reach out to us through any of the channels below.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Customer Support
            _buildContactCard(
              icon: Icons.support_agent,
              title: 'Customer Support',
              subtitle: '24/7 Support for all your queries',
              onTap: _launchEmail,
              contactInfo: 'support@happle.com',
            ),

            const SizedBox(height: 16),

            // Business Inquiries
            _buildContactCard(
              icon: Icons.business,
              title: 'Business Inquiries',
              subtitle: 'Partnerships and business opportunities',
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'business@happle.com',
                  queryParameters: {
                    'subject': 'Business Inquiry - Happle',
                  },
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
              contactInfo: 'business@happle.com',
            ),

            const SizedBox(height: 16),

            // Phone Support
            _buildContactCard(
              icon: Icons.phone,
              title: 'Phone Support',
              subtitle: 'Call us for immediate assistance',
              onTap: () => _launchPhone('+91-1800-XXX-XXXX'),
              contactInfo: '+91-1800-XXX-XXXX',
            ),

            const SizedBox(height: 32),

            const Text(
              'Office Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Happle Technologies Pvt. Ltd.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '123 Business District',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Tech Park, Sector 15',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Gurugram, Haryana - 122001',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'India',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Response Time',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We strive to respond to all inquiries within 24 hours during business days. For urgent matters, please call our phone support line.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Before contacting us, you might find answers to common questions in our FAQ section. You can access it from the app menu or visit our website.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
