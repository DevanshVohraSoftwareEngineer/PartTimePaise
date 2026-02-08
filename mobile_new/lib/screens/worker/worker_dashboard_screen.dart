import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../data_types/bid.dart';
import '../../managers/bids_provider.dart';
import '../../managers/auth_provider.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final myBidsState = ref.watch(myBidsProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Calculate stats
    final totalBids = myBidsState.bids.length;
    final acceptedBids = myBidsState.bids.where((bid) => bid.status == 'accepted').length;
    final pendingBids = myBidsState.bids.where((bid) => bid.status == 'pending').length;
    final rejectedBids = myBidsState.bids.where((bid) => bid.status == 'rejected').length;

    // Calculate earnings (simplified - in real app, this would come from completed tasks)
    final estimatedEarnings = myBidsState.bids
        .where((bid) => bid.status == 'accepted')
        .fold<double>(0, (sum, bid) => sum + bid.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myBidsProvider.notifier).loadMyBids();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.navyMedium, AppTheme.navyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.name ?? 'Worker',
                        style: AppTheme.heading1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Cards
                Text(
                  'Your Stats',
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Bids',
                        totalBids.toString(),
                        Icons.work,
                        AppTheme.navyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Accepted',
                        acceptedBids.toString(),
                        Icons.check_circle,
                        AppTheme.likeGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingBids.toString(),
                        Icons.hourglass_top,
                        AppTheme.superLikeBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Rejected',
                        rejectedBids.toString(),
                        Icons.cancel,
                        AppTheme.nopeRed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Earnings Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.boostGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.boostGold.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: AppTheme.boostGold, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Earnings',
                            style: AppTheme.heading2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${estimatedEarnings.toStringAsFixed(0)}',
                        style: AppTheme.heading1.copyWith(
                          color: AppTheme.boostGold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From accepted bids',
                        style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Bids
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Bids',
                      style: AppTheme.heading2,
                    ),
                    TextButton(
                      onPressed: () => context.go('/my-bids'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (myBidsState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (myBidsState.bids.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.work_outline, size: 48, color: AppTheme.grey400),
                        const SizedBox(height: 16),
                        Text(
                          'No bids yet',
                          style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start swiping on tasks to submit bids',
                          style: AppTheme.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/swipe'),
                          child: const Text('Start Swiping'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myBidsState.bids.take(5).length,
                    itemBuilder: (context, index) {
                      final bid = myBidsState.bids[index];
                      return _buildBidCard(bid);
                    },
                  ),

                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Find Tasks',
                        'Browse available tasks',
                        Icons.search,
                        () => context.go('/swipe'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'My Profile',
                        'Update your information',
                        Icons.person,
                        () => context.go('/profile'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Earnings',
                        'View payment history',
                        Icons.account_balance_wallet,
                        () => context.go('/earnings'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Support',
                        'Get help',
                        Icons.help,
                        () => context.go('/support'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            style: AppTheme.heading2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.caption.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBidCard(Bid bid) {
    Color statusColor;
    String statusText;

    switch (bid.status) {
      case 'accepted':
        statusColor = AppTheme.likeGreen;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = AppTheme.nopeRed;
        statusText = 'Rejected';
        break;
      default:
        statusColor = AppTheme.superLikeBlue;
        statusText = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bid for Task',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: AppTheme.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${bid.amount}',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.boostGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatBidTime(bid.createdAt),
              style: AppTheme.caption.copyWith(color: AppTheme.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.navyMedium, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.caption.copyWith(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBidTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
