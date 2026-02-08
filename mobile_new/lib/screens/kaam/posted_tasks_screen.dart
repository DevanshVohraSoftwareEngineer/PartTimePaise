import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../data_types/task.dart';
import '../../services/supabase_service.dart';
import '../../widgets/countdown_timer.dart';

class PostedTasksScreen extends ConsumerStatefulWidget {
  const PostedTasksScreen({super.key});

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
        child: (myTasksState.isLoading && myTasksState.tasks.isEmpty)
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
                      final primaryColor = Theme.of(context).primaryColor;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                        ),
                                      ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(task.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getStatusColor(task.status).withOpacity(0.3), width: 0.5),
                                    ),
                                    child: Text(
                                      task.status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(task.status),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
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
                                        color: primaryColor.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${task.budget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
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
                                          color: primaryColor.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(task.deadline!),
                                          style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                      child: Text(
                                        task.category,
                                        style: TextStyle(
                                          color: primaryColor.withOpacity(0.8),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ),
                                ],
                              ),
  
                              const SizedBox(height: 12),
  
                              // Insights / Analytics
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]!.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primaryColor.withOpacity(0.05)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(context, Icons.visibility_outlined, '${task.reachCount ?? 0}', 'REACH'),
                                    _buildStatColumn(context, Icons.remove_red_eye, '${task.realtimeViewersCount ?? 0}', 'VIEWING', isActive: (task.realtimeViewersCount ?? 0) > 0),
                                    _buildStatColumn(context, Icons.people_outline, '${task.bidsCount ?? 0}', 'BIDS'),
                                    Column(
                                      children: [
                                        CountdownTimer(
                                          expiresAt: task.effectiveExpiresAt,
                                          textStyle: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'TIME LEFT',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: primaryColor.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
  
                              // Secure Handshake OTPs
                              if ((task.status == 'assigned' && task.startOtp != null) ||
                                  (task.status == 'in_progress' && task.endOtp != null))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        task.status == 'assigned' ? 'START OTP' : 'END OTP',
                                        style: TextStyle(
                                          color: primaryColor.withOpacity(0.4),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.status == 'assigned'
                                            ? (task.startOtp ?? '....')
                                            : (task.endOtp ?? '....'),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Share this with the worker ONLY when they ${task.status == 'assigned' ? 'arrive' : 'finish'}.',
                                        style: TextStyle(
                                          color: primaryColor.withOpacity(0.4),
                                          fontSize: 10,
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
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('EDIT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primaryColor,
                                          side: BorderSide(color: primaryColor.withOpacity(0.2)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  if (task.status == 'open') const SizedBox(width: 8),
                                  if (task.status == 'open')
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _closeTask(task),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red.withOpacity(0.2)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  if (task.status != 'open')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _viewTaskDetails(task),
                                        icon: Icon(Icons.visibility, size: 16, color: isDark ? Colors.black : Colors.white),
                                        label: Text('VIEW DETAILS', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
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
          const Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppTheme.grey300,
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 32),
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

  Widget _buildStatColumn(BuildContext context, IconData icon, String value, String label, {bool isActive = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
