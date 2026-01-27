import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../managers/auth_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = '7d'; // 7d, 30d, 90d

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isClient = currentUser?.role == 'client';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 days')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _getPeriodText(_selectedPeriod),
                style: AppTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            if (isClient) ...[
              _buildOverviewCards(_getClientMetrics()),
              const SizedBox(height: 24),
              _buildClientAnalytics(),
            ] else ...[
              _buildOverviewCards(_getWorkerMetrics()),
              const SizedBox(height: 24),
              _buildWorkerAnalytics(),
            ],

            const SizedBox(height: 24),

            // Performance Insights
            Text(
              'Performance Insights',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildInsightsCards(isClient),

            const SizedBox(height: 24),

            // Trends Chart (Placeholder)
            Text(
              'Activity Trends',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildTrendsChart(),

            const SizedBox(height: 24),

            // Recommendations
            Text(
              'Recommendations',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            _buildRecommendations(isClient),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(List<Map<String, dynamic>> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          metric['title'] as String,
          metric['value'] as String,
          metric['change'] as String,
          metric['icon'] as IconData,
          metric['color'] as Color,
          metric['isPositive'] as bool,
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? AppTheme.likeGreen : AppTheme.nopeRed,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: AppTheme.caption.copyWith(
                  color: isPositive ? AppTheme.likeGreen : AppTheme.nopeRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Performance',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),

        // Task Status Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Open Tasks', style: AppTheme.bodyMedium),
                  Text('12', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.4,
                backgroundColor: AppTheme.grey300,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.superLikeBlue),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completed Tasks', style: AppTheme.bodyMedium),
                  Text('8', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.27,
                backgroundColor: AppTheme.grey300,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.likeGreen),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Average Response Time
        Text(
          'Response Analytics',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Avg. Response Time',
                '2.3 hours',
                Icons.timer,
                AppTheme.boostGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Bid Rate',
                '68%',
                Icons.show_chart,
                AppTheme.likeGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkerAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earning Performance',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),

        // Earnings Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This Month', style: AppTheme.bodyMedium),
                  Text('₹12,450', style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.likeGreen,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.83,
                backgroundColor: AppTheme.grey300,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.likeGreen),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pending Payments', style: AppTheme.bodyMedium),
                  Text('₹2,300', style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.boostGold,
                  )),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Success Metrics
        Text(
          'Success Metrics',
          style: AppTheme.heading2,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Acceptance Rate',
                '74%',
                Icons.thumb_up,
                AppTheme.likeGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Avg. Rating',
                '4.8 ⭐',
                Icons.star,
                AppTheme.boostGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCards(bool isClient) {
    final insights = isClient ? _getClientInsights() : _getWorkerInsights();

    return Column(
      children: insights.map((insight) => _buildInsightCard(insight)).toList(),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (insight['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight['icon'] as IconData,
                color: insight['color'] as Color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight['description'] as String,
                    style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart() {
    // Placeholder for chart - in real app, use charts_flutter or similar
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            'Activity Chart',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            'Chart visualization would be implemented here',
            style: AppTheme.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(bool isClient) {
    final recommendations = isClient ? _getClientRecommendations() : _getWorkerRecommendations();

    return Column(
      children: recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: AppTheme.superLikeBlue,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation['title'] as String,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.superLikeBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation['description'] as String,
                    style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getClientMetrics() {
    return [
      {
        'title': 'Tasks Posted',
        'value': '20',
        'change': '+15%',
        'icon': Icons.assignment,
        'color': AppTheme.navyMedium,
        'isPositive': true,
      },
      {
        'title': 'Tasks Completed',
        'value': '8',
        'change': '+25%',
        'icon': Icons.check_circle,
        'color': AppTheme.likeGreen,
        'isPositive': true,
      },
      {
        'title': 'Avg. Bid Count',
        'value': '4.2',
        'change': '+8%',
        'icon': Icons.people,
        'color': AppTheme.superLikeBlue,
        'isPositive': true,
      },
      {
        'title': 'Total Spent',
        'value': '₹15.2k',
        'change': '+12%',
        'icon': Icons.currency_rupee,
        'color': AppTheme.boostGold,
        'isPositive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getWorkerMetrics() {
    return [
      {
        'title': 'Bids Submitted',
        'value': '45',
        'change': '+22%',
        'icon': Icons.work,
        'color': AppTheme.navyMedium,
        'isPositive': true,
      },
      {
        'title': 'Bids Accepted',
        'value': '18',
        'change': '+35%',
        'icon': Icons.thumb_up,
        'color': AppTheme.likeGreen,
        'isPositive': true,
      },
      {
        'title': 'Success Rate',
        'value': '74%',
        'change': '+5%',
        'icon': Icons.trending_up,
        'color': AppTheme.superLikeBlue,
        'isPositive': true,
      },
      {
        'title': 'Earnings',
        'value': '₹12.4k',
        'change': '+28%',
        'icon': Icons.currency_rupee,
        'color': AppTheme.boostGold,
        'isPositive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getClientInsights() {
    return [
      {
        'title': 'High Response Rate',
        'description': 'Tasks with photos get 3x more bids on average',
        'icon': Icons.photo_camera,
        'color': AppTheme.likeGreen,
      },
      {
        'title': 'Optimal Budget Range',
        'description': 'Tasks priced ₹500-2000 get the most responses',
        'icon': Icons.currency_rupee,
        'color': AppTheme.boostGold,
      },
      {
        'title': 'Best Posting Times',
        'description': 'Post between 10 AM - 2 PM for maximum visibility',
        'icon': Icons.schedule,
        'color': AppTheme.superLikeBlue,
      },
    ];
  }

  List<Map<String, dynamic>> _getWorkerInsights() {
    return [
      {
        'title': 'Profile Completion',
        'description': 'Complete profiles get 40% more bid acceptances',
        'icon': Icons.person,
        'color': AppTheme.likeGreen,
      },
      {
        'title': 'Response Time Matters',
        'description': 'Respond within 2 hours to increase acceptance rate',
        'icon': Icons.timer,
        'color': AppTheme.boostGold,
      },
      {
        'title': 'Rating Impact',
        'description': 'Maintain 4.5+ rating for premium opportunities',
        'icon': Icons.star,
        'color': AppTheme.superLikeBlue,
      },
    ];
  }

  List<Map<String, dynamic>> _getClientRecommendations() {
    return [
      {
        'title': 'Increase Task Budget',
        'description': 'Consider raising budgets by 15-20% for complex tasks to attract skilled workers',
      },
      {
        'title': 'Add More Photos',
        'description': 'Tasks with multiple photos receive 2.5x more bids',
      },
      {
        'title': 'Post During Peak Hours',
        'description': 'Schedule task posts between 10 AM - 4 PM for maximum worker visibility',
      },
    ];
  }

  List<Map<String, dynamic>> _getWorkerRecommendations() {
    return [
      {
        'title': 'Complete Your Profile',
        'description': 'Add skills, experience, and portfolio to increase bid acceptance rates',
      },
      {
        'title': 'Improve Response Time',
        'description': 'Respond to inquiries within 1 hour to stay competitive',
      },
      {
        'title': 'Specialize in High-Demand Skills',
        'description': 'Focus on trending skills like mobile development and digital marketing',
      },
    ];
  }

  String _getPeriodText(String period) {
    switch (period) {
      case '7d':
        return '7 days';
      case '30d':
        return '30 days';
      case '90d':
        return '90 days';
      default:
        return '7 days';
    }
  }
}