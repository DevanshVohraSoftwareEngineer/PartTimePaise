import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/images/logo.png', // You'll need to add this asset
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.work,
                    size: 100,
                    color: Colors.blue,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to PartTimePaise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connecting People, Creating Opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'At PartTimePaise, we believe that everyone has skills and talents that can benefit others. Our platform connects individuals seeking flexible work opportunities with people who need reliable help for various tasks. We strive to create a community where part-time work meets real needs, fostering economic growth and personal development.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What We Do',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PartTimePaise is a comprehensive platform that facilitates connections between service providers and clients for various tasks including:',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Delivery services'),
                Text('• Cleaning and household help'),
                Text('• Tutoring and educational support'),
                Text('• Tech support and assistance'),
                Text('• Moving and transportation help'),
                Text('• Shopping and errands'),
                Text('• Pet care services'),
                Text('• Gardening and outdoor work'),
                Text('• Event assistance'),
                Text('• And many more services'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Values',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Trust & Safety: We prioritize the safety and security of all our users',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
                Text(
                  '• Fairness: Equal opportunities for all users regardless of background',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
                Text(
                  '• Community: Building strong connections between service providers and clients',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
                Text(
                  '• Innovation: Continuously improving our platform to better serve users',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
                Text(
                  '• Transparency: Clear communication and honest business practices',
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Story',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Founded with the vision to revolutionize the gig economy in India, PartTimePaise was created to address the growing need for flexible, reliable, and accessible service solutions. We recognized that many people have valuable skills but lack consistent work opportunities, while others need help with daily tasks but struggle to find trustworthy assistance.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Today, PartTimePaise serves thousands of users across India, helping them achieve their goals through meaningful connections and economic opportunities.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'For support or inquiries, please visit our Contact Us page or reach out to our customer service team.',
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