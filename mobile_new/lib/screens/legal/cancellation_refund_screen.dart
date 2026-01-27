import 'package:flutter/material.dart';

class CancellationRefundScreen extends StatelessWidget {
  const CancellationRefundScreen({Key? key}) : super(key: key);

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
        title: const Text('Cancellation & Refund Policies'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Cancellation & Refund Policies',
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
              '1. Overview',
              'PartTimePaise Technologies Pvt. Ltd. is committed to providing fair and transparent cancellation and refund policies. This policy outlines the terms under which users can cancel services and request refunds for our platform.',
            ),

            _buildSection(
              '2. Service Cancellation',
              'Users may cancel their accounts or specific services subject to the following conditions:',
            ),

            _buildSubSection(
              '2.1 Account Cancellation',
              'You may cancel your account at any time through the app settings. Upon cancellation:',
            ),

            _buildBulletList([
              'Your account will be deactivated immediately',
              'Access to premium features will be revoked',
              'Your profile will be hidden from search results',
              'Pending tasks and applications will be cancelled',
              'Data retention follows our Privacy Policy',
            ]),

            _buildSubSection(
              '2.2 Task Cancellation',
              'Task cancellation depends on the current status:',
            ),

            _buildBulletList([
              'Posted tasks can be cancelled before acceptance',
              'Accepted tasks can be cancelled with mutual agreement',
              'In-progress tasks require 24-hour notice',
              'Completed tasks cannot be cancelled',
            ]),

            _buildSection(
              '3. Refund Eligibility',
              'Refunds are available under specific circumstances as outlined below:',
            ),

            _buildSubSection(
              '3.1 Premium Subscription Refunds',
              '• Full refund within 7 days of purchase if unused\n• Pro-rated refund after 7 days\n• No refund after 30 days\n• Technical issues preventing service use',
            ),

            _buildSubSection(
              '3.2 Task Payment Refunds',
              '• Full refund if task is not completed as agreed\n• Partial refund for unsatisfactory work\n• No refund for completed tasks meeting requirements\n• Refund for cancelled tasks before work begins',
            ),

            _buildSubSection(
              '3.3 Payment Processing Refunds',
              '• Failed transaction refunds within 3-5 business days\n• Duplicate charge refunds upon verification\n• Currency conversion error corrections',
            ),

            _buildSection(
              '4. Refund Process',
              'To request a refund, follow these steps:',
            ),

            _buildBulletList([
              'Contact our support team within the refund window',
              'Provide transaction details and reason for refund',
              'Submit supporting documentation if required',
              'Allow 7-14 business days for processing',
              'Refunds will be processed to the original payment method',
            ]),

            _buildSection(
              '5. Non-Refundable Items',
              'The following are not eligible for refunds:',
            ),

            _buildBulletList([
              'Successfully completed tasks',
              'Consumed premium features',
              'Account verification fees',
              'Third-party service charges',
              'Dispute resolution fees',
            ]),

            _buildSection(
              '6. Refund Timeframes',
              'Refund processing times vary by payment method:',
            ),

            _buildBulletList([
              'Credit/Debit Cards: 5-7 business days',
              'UPI Payments: 1-3 business days',
              'Net Banking: 3-5 business days',
              'Wallet Payments: Instant to 1 business day',
            ]),

            _buildSection(
              '7. Cancellation of Premium Services',
              'Premium subscription cancellation terms:',
            ),

            _buildBulletList([
              'Monthly subscriptions: Cancel anytime, effective end of billing period',
              'Annual subscriptions: Cancel anytime, no prorated refunds',
              'Auto-renewal: Must cancel before renewal date',
              'Downgrades: Immediate effect, no refunds for unused premium time',
            ]),

            _buildSection(
              '8. Dispute Resolution',
              'If you disagree with a refund decision:',
            ),

            _buildBulletList([
              'Contact customer support for review',
              'Provide additional evidence or documentation',
              'Escalation to management within 30 days',
              'Final decisions are binding',
            ]),

            _buildSection(
              '9. Changes to Policy',
              'We reserve the right to modify this policy with reasonable notice. Changes will be communicated through the app or email.',
            ),

            _buildSection(
              '10. Contact Information',
              'For cancellation or refund requests, contact us at:',
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
                  Text('Email: refunds@parttimepaise.com'),
                  Text('Phone: +91-1800-XXX-XXXX'),
                  Text('Support Hours: Mon-Fri 9:00 AM - 6:00 PM IST'),
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