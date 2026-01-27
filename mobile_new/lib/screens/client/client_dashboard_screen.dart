import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../data_types/task.dart';
import '../../managers/tasks_provider.dart';
import '../../managers/auth_provider.dart';
import '../../services/navigation_service.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final myTasksState = ref.watch(myTasksProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Calculate stats
    final totalTasks = myTasksState.tasks.length;
    final openTasks = myTasksState.tasks.where((task) => task.status == 'open').length;
    final inProgressTasks = myTasksState.tasks.where((task) => task.status == 'in_progress').length;
    final completedTasks = myTasksState.tasks.where((task) => task.status == 'completed').length;

    // Calculate total spent (simplified)
    final totalSpent = myTasksState.tasks
        .where((task) => task.status == 'completed')
        .fold<double>(0, (sum, task) => sum + (task.budget ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/post-task'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myTasksProvider.notifier).loadMyTasks();
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
                    gradient: LinearGradient(
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
                        currentUser?.name ?? 'Client',
                        style: AppTheme.heading1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Cards
                Text(
                  'Your Tasks',
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Tasks',
                        totalTasks.toString(),
                        Icons.assignment,
                        AppTheme.navyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Open',
                        openTasks.toString(),
                        Icons.hourglass_top,
                        AppTheme.superLikeBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'In Progress',
                        inProgressTasks.toString(),
                        Icons.work,
                        AppTheme.boostGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        completedTasks.toString(),
                        Icons.check_circle,
                        AppTheme.likeGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Spending Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.likeGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.likeGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, color: AppTheme.likeGreen, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Total Spent',
                            style: AppTheme.heading2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalSpent.toStringAsFixed(0)}',
                        style: AppTheme.heading1.copyWith(
                          color: AppTheme.likeGreen,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On completed tasks',
                        style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Tasks',
                      style: AppTheme.heading2,
                    ),
                    TextButton(
                      onPressed: () => context.go('/my-tasks'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (myTasksState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (myTasksState.tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: AppTheme.grey400),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks posted yet',
                          style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Post your first task to get started',
                          style: AppTheme.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/post-task'),
                          child: const Text('Post a Task'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myTasksState.tasks.take(5).length,
                    itemBuilder: (context, index) {
                      final task = myTasksState.tasks[index];
                      return _buildTaskCard(task);
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
                        'Post Task',
                        'Create a new task',
                        Icons.add,
                        () async {
                          final navigationService = NavigationService();
                          final isAuthenticated = ref.read(isAuthenticatedProvider);
                          await navigationService.navigateToPostTaskWithAuth(context, isAuthenticated);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Browse Workers',
                        'Find available workers',
                        Icons.search,
                        () => context.go('/browse-workers'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Messages',
                        'Chat with workers',
                        Icons.message,
                        () => context.go('/matches'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Analytics',
                        'View insights',
                        Icons.analytics,
                        () => context.go('/analytics'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tips Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.superLikeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.superLikeBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppTheme.superLikeBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Pro Tips',
                            style: AppTheme.heading2.copyWith(color: AppTheme.superLikeBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip(
                        '💰 Higher budgets attract better workers',
                        'Consider increasing your budget for urgent or complex tasks',
                      ),
                      const SizedBox(height: 8),
                      _buildTip(
                        '📸 Add photos to your tasks',
                        'Tasks with photos get 3x more bids',
                      ),
                      const SizedBox(height: 8),
                      _buildTip(
                        '⚡ Set realistic deadlines',
                        'Flexible deadlines get more responses',
                      ),
                    ],
                  ),
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

  Widget _buildTaskCard(Task task) {
    Color statusColor;
    String statusText;

    switch (task.status.toLowerCase()) {
      case 'open':
        statusColor = AppTheme.superLikeBlue;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = AppTheme.boostGold;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = AppTheme.likeGreen;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = AppTheme.nopeRed;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = AppTheme.grey500;
        statusText = task.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/task/${task.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                '₹${task.budget} • ${task.category}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.boostGold),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTaskTime(task.createdAt),
                style: AppTheme.caption.copyWith(color: AppTheme.grey600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback
          Feedback.forTap(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.navyMedium.withOpacity(0.1),
        highlightColor: AppTheme.navyMedium.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.grey200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.navyMedium.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.navyMedium,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.grey600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.superLikeBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTheme.caption.copyWith(color: AppTheme.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTaskTime(DateTime createdAt) {
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