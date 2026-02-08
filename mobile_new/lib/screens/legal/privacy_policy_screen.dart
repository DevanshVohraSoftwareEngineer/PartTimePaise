import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Last updated: January 19, 2026',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '1. Introduction',
              'PartTimePaise Technologies Pvt. Ltd. ("we," "our," or "us") respects your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the "App") and related services.',
            ),

            _buildSection(
              '2. Information We Collect',
              'We collect information you provide directly to us, information we obtain automatically when you use our services, and information from third-party sources.',
            ),

            _buildSubSection(
              '2.1 Information You Provide',
              '• Account information (name, email, phone number)\n• Profile information (skills, experience, location)\n• Payment information\n• Communications with us\n• User-generated content and feedback',
            ),

            _buildSubSection(
              '2.2 Information We Collect Automatically',
              '• Device information (IP address, browser type, operating system)\n• Usage data (pages viewed, time spent, features used)\n• Location data (with your permission)\n• Cookies and similar technologies',
            ),

            _buildSection(
              '3. How We Use Your Information',
              'We use the information we collect for various purposes, including:',
            ),

            _buildBulletList([
              'Providing and maintaining our services',
              'Processing transactions and payments',
              'Communicating with you about our services',
              'Personalizing your experience',
              'Improving our services and developing new features',
              'Ensuring security and preventing fraud',
              'Complying with legal obligations',
              'Sending marketing communications (with your consent)',
            ]),

            _buildSection(
              '4. Information Sharing and Disclosure',
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
            ),

            _buildSubSection(
              '4.1 Service Providers',
              'We may share your information with third-party service providers who assist us in operating our services, such as payment processors, cloud storage providers, and analytics services.',
            ),

            _buildSubSection(
              '4.2 Business Transfers',
              'If we are involved in a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction.',
            ),

            _buildSubSection(
              '4.3 Legal Requirements',
              'We may disclose your information if required by law or if we believe such action is necessary to comply with legal obligations or protect our rights.',
            ),

            _buildSection(
              '5. Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),

            _buildSection(
              '6. Data Retention',
              'We retain your personal information for as long as necessary to provide our services, comply with legal obligations, resolve disputes, and enforce our agreements. When information is no longer needed, we securely delete or anonymize it.',
            ),

            _buildSection(
              '7. Your Rights and Choices',
              'Depending on your location, you may have certain rights regarding your personal information:',
            ),

            _buildBulletList([
              'Access: Request a copy of your personal information',
              'Correction: Update or correct inaccurate information',
              'Deletion: Request deletion of your personal information',
              'Portability: Request transfer of your data',
              'Opt-out: Unsubscribe from marketing communications',
              'Restriction: Limit how we process your information',
            ]),

            _buildSection(
              '8. Cookies and Tracking Technologies',
              'We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content. You can control cookie settings through your browser preferences.',
            ),

            _buildSection(
              '9. Third-Party Services',
              'Our App may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies.',
            ),

            _buildSection(
              '10. Children\'s Privacy',
              'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will delete it immediately.',
            ),

            _buildSection(
              '11. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during such transfers.',
            ),

            _buildSection(
              '12. Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              '13. Contact Us',
              'If you have any questions about this Privacy Policy or our privacy practices, please contact us at:',
            ),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PartTimePaise Technologies Pvt. Ltd.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Email: privacy@parttimepaise.com'),
                  Text('Phone: +91-1800-XXX-XXXX'),
                  Text('Address: 123 Business District, Tech Park, Sector 15, Gurugram, Haryana - 122001, India'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}