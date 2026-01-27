import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../data_types/task.dart';
import '../../managers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/navigation_service.dart';

class PostedTasksScreen extends ConsumerStatefulWidget {
  const PostedTasksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PostedTasksScreen> createState() => _PostedTasksScreenState();
}

class _PostedTasksScreenState extends ConsumerState<PostedTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myTasksProvider.notifier).loadMyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final myTasksState = ref.watch(myTasksProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posted Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myTasksProvider.notifier).loadMyTasks(),
        child: myTasksState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : myTasksState.tasks.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: myTasksState.tasks.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final task = myTasksState.tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and status
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Text(
                                        task.title,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(task.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task.status.toUpperCase(),
                                      style: AppTheme.caption.copyWith(
                                        color: _getStatusColor(task.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
  
                              const SizedBox(height: 8),
  
                              // Description
                              Text(
                                task.description,
                                style: AppTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
  
                              const SizedBox(height: 12),
  
                              // Budget, deadline, category
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: AppTheme.getAdaptiveGrey600(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${task.budget.toStringAsFixed(0)}',
                                        style: AppTheme.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task.deadline != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: AppTheme.getAdaptiveGrey600(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(task.deadline!),
                                          style: AppTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.navyLightest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                      child: Text(
                                        task.category,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isDark ? AppTheme.navyMedium : AppTheme.navyDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ),
                                ],
                              ),
  
                              const SizedBox(height: 12),
  
                              // Stats
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: AppTheme.grey500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${task.budget.toStringAsFixed(0)}',
                                        style: AppTheme.caption,
                                      ),
                                    ],
                                  ),
                                  if (task.bidsCount != null) ...[
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          size: 16,
                                          color: AppTheme.grey500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${task.bidsCount} bids',
                                          style: AppTheme.caption,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
  
                              // Secure Handshake OTPs
                              if ((task.status == 'assigned' && task.startOtp != null) ||
                                  (task.status == 'in_progress' && task.endOtp != null))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.navyLightest,
                                    border: Border.all(color: AppTheme.navyMedium),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        task.status == 'assigned' ? 'START OTP' : 'END OTP',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.navyMedium,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.status == 'assigned'
                                            ? (task.startOtp ?? '....')
                                            : (task.endOtp ?? '....'),
                                        style: AppTheme.heading2.copyWith(
                                          color: AppTheme.navyDark,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Share this with the worker ONLY when they ${task.status == 'assigned' ? 'arrive' : 'finish'}.',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.getAdaptiveGrey600(context),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
  
                              const SizedBox(height: 12),
  
                              // Actions
                              Row(
                                children: [
                                  if (task.status == 'open')
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _editTask(task),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.navyMedium,
                                        ),
                                      ),
                                    ),
                                  if (task.status == 'open') const SizedBox(width: 8),
                                  if (task.status == 'open')
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _closeTask(task),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Close'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.nopeRed,
                                        ),
                                      ),
                                    ),
                                  if (task.status != 'open')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _viewTaskDetails(task),
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View Details'),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                  },
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Changed to min for better alignment
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppTheme.grey300,
          ),
          SizedBox(height: 24),
          Text(
            'No posted tasks yet!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Post your first task to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.likeGreen;
      case 'in_progress':
        return AppTheme.boostGold;
      case 'completed':
        return AppTheme.navyMedium;
      case 'cancelled':
        return AppTheme.nopeRed;
      default:
        return AppTheme.grey500;
    }
  }

  void _editTask(Task task) {
    context.push('/post-task?edit=${task.id}');
  }

  void _closeTask(Task task) async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.updateTask(task.id, {'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task closed successfully'),
            backgroundColor: AppTheme.likeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing task: ${e.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    }
  }

  void _viewTaskDetails(Task task) {
    context.push('/task-details/${task.id}');
  }
}