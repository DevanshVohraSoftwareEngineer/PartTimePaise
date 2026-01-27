import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

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
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Terms & Conditions',
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
              '1. Acceptance of Terms',
              'By accessing and using the PartTimePaise mobile application ("App") and related services provided by PartTimePaise Technologies Pvt. Ltd. ("we," "our," or "us"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),

            _buildSection(
              '2. Description of Service',
              'PartTimePaise is a platform that connects individuals seeking part-time work opportunities with potential employers and service providers. Our services include job posting, task management, payment processing, and communication tools.',
            ),

            _buildSection(
              '3. User Accounts',
              'To use certain features of our service, you must register for an account. When you register, you agree to:',
            ),

            _buildBulletList([
              'Provide accurate and complete information',
              'Maintain and update your information',
              'Keep your password secure and confidential',
              'Accept responsibility for all activities under your account',
              'Notify us immediately of any unauthorized use',
            ]),

            _buildSection(
              '4. User Conduct',
              'You agree not to use the service to:',
            ),

            _buildBulletList([
              'Violate any applicable laws or regulations',
              'Infringe on intellectual property rights',
              'Harass, abuse, or harm others',
              'Transmit harmful or malicious code',
              'Attempt to gain unauthorized access',
              'Post false, misleading, or inappropriate content',
              'Use the service for commercial purposes without authorization',
            ]),

            _buildSection(
              '5. Content and Intellectual Property',
              'All content, features, and functionality of the App are owned by PartTimePaise Technologies Pvt. Ltd. and are protected by copyright, trademark, and other intellectual property laws.',
            ),

            _buildSubSection(
              '5.1 User Content',
              'By posting content on our platform, you grant us a non-exclusive, royalty-free, perpetual license to use, modify, and distribute your content in connection with our services.',
            ),

            _buildSection(
              '6. Payment Terms',
              'For paid services, you agree to pay all fees associated with your account. Payment terms include:',
            ),

            _buildBulletList([
              'Fees are charged in advance for premium services',
              'All payments are non-refundable unless otherwise stated',
              'We reserve the right to change pricing with notice',
              'Late payments may result in service suspension',
              'You are responsible for all applicable taxes',
            ]),

            _buildSection(
              '7. Service Availability',
              'We strive to provide continuous service but do not guarantee uninterrupted access. We reserve the right to modify, suspend, or discontinue the service at any time without notice.',
            ),

            _buildSection(
              '8. Disclaimers',
              'The service is provided "as is" without warranties of any kind. We disclaim all warranties, express or implied, including but not limited to merchantability and fitness for a particular purpose.',
            ),

            _buildSection(
              '9. Limitation of Liability',
              'In no event shall PartTimePaise Technologies Pvt. Ltd. be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the service.',
            ),

            _buildSection(
              '10. Indemnification',
              'You agree to indemnify and hold harmless PartTimePaise Technologies Pvt. Ltd. from any claims, damages, losses, or expenses arising from your use of the service or violation of these terms.',
            ),

            _buildSection(
              '11. Termination',
              'We may terminate or suspend your account immediately for violations of these terms. Upon termination, your right to use the service ceases immediately.',
            ),

            _buildSection(
              '12. Governing Law',
              'These terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be resolved in the courts of Gurugram, Haryana.',
            ),

            _buildSection(
              '13. Changes to Terms',
              'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),

            _buildSection(
              '14. Contact Information',
              'If you have questions about these Terms & Conditions, please contact us at:',
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
                  Text('Email: legal@parttimepaise.com'),
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