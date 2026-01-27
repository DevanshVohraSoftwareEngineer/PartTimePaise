import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../data_types/task.dart';
import '../../data_types/bid.dart';
import '../../managers/tasks_provider.dart';
import '../../managers/bids_provider.dart';
import '../../managers/auth_provider.dart';
import '../../utils/validators.dart';
import 'package:flutter/foundation.dart'; // Added

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  final _bidAmountController = TextEditingController();
  final _bidMessageController = TextEditingController();
  bool _isSubmittingBid = false;

  @override
  void dispose() {
    _bidAmountController.dispose();
    _bidMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final bidsState = ref.watch(bidsProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);

    final task = tasksState.tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => Task.empty(),
    );

    if (task.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isTaskOwner = currentUser?.id == task.clientId;
    final hasUserBid = bidsState.bids.any((bid) => bid.workerId == currentUser?.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isTaskOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.go('/edit-task/${task.id}');
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, task);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Task')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Task')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Images
            if (task.images != null && task.images!.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: task.images!.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      task.images![index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppTheme.grey200),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTheme.heading1,
                        ),
                      ),
                      _buildStatusChip(task.status),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category and Posted Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.likeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.category,
                          style: AppTheme.caption.copyWith(color: AppTheme.likeGreen),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatPostedTime(task.createdAt),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.getAdaptiveGrey600(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Budget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.boostGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.boostGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.currency_rupee, color: AppTheme.boostGold),
                        const SizedBox(width: 8),
                        Text(
                          '${task.budget} ${task.budgetType}',
                          style: AppTheme.heading2.copyWith(color: AppTheme.boostGold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: AppTheme.bodyLarge,
                  ),

                  const SizedBox(height: 16),

                  // Deadline and Urgency
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Deadline',
                          task.deadline != null
                              ? _formatDate(task.deadline!)
                              : 'No deadline',
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Urgency',
                          task.urgency ?? 'Not specified',
                          Icons.priority_high,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location
                  if (task.location != null && task.location!.isNotEmpty)
                    _buildInfoCard(
                      'Location',
                      task.location!,
                      Icons.location_on,
                    ),

                  const SizedBox(height: 24),

                  // Bids Section
                  if (!isTaskOwner) ...[
                    Text(
                      'Place Your Bid',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: 16),
                    if (!hasUserBid) ...[
                      TextFormField(
                        controller: _bidAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Your Bid Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (value) => Validators.validateRequired(value, 'Bid amount'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bidMessageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Why should they choose you?',
                          hintText: 'Tell the client about your experience and why you\'re the best fit...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmittingBid ? null : () => _submitBid(task),
                          child: _isSubmittingBid
                              ? const CircularProgressIndicator()
                              : const Text('Submit Bid'),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.likeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.likeGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.likeGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'ve already bid on this task',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.likeGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Show bids for task owner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bids Received (${bidsState.bids.length})',
                          style: AppTheme.heading2,
                        ),
                        if (kDebugMode && bidsState.bids.isEmpty)
                          TextButton.icon(
                            onPressed: () {
                              ref.read(bidsProvider(widget.taskId).notifier).mockApplicants();
                            },
                            icon: const Icon(Icons.bug_report, color: Colors.purple),
                            label: const Text('MOCK 10 CANDIDATES', style: TextStyle(color: Colors.purple, fontSize: 10)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (bidsState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (bidsState.bids.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty, size: 48, color: AppTheme.grey400),
                            const SizedBox(height: 16),
                            Text(
                              'No bids yet',
                              style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bids will appear here once workers show interest',
                              style: AppTheme.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bidsState.bids.length,
                        itemBuilder: (context, index) {
                          final bid = bidsState.bids[index];
                          return _buildBidCard(bid, task);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'open':
        color = AppTheme.likeGreen;
        text = 'Open';
        break;
      case 'in_progress':
        color = AppTheme.superLikeBlue;
        text = 'In Progress';
        break;
      case 'completed':
        color = AppTheme.boostGold;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppTheme.nopeRed;
        text = 'Cancelled';
        break;
      default:
        color = AppTheme.grey500;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grey600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.getAdaptiveGrey600(context),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidCard(Bid bid, Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.likeGreen.withOpacity(0.2),
                  child: Text(
                    bid.workerName.isNotEmpty ? bid.workerName[0].toUpperCase() : 'W',
                    style: TextStyle(color: AppTheme.likeGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.workerName,
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatBidTime(bid.createdAt),
                        style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.boostGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₹${bid.amount}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.boostGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (bid.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bid.message,
                style: AppTheme.bodyMedium,
              ),
            ],

            // ✨ KYC Trust Card (Identity Verification)
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Verified Identity',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Face Photo
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: bid.workerFaceUrl != null 
                                  ? Image.network(bid.workerFaceUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.face, color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Live Photo', style: TextStyle(fontSize: 10, color: AppTheme.grey600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ID Card Photo
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: bid.workerIdCardUrl != null
                                  ? Image.network(bid.workerIdCardUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.badge, color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('College ID', style: TextStyle(fontSize: 10, color: AppTheme.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Matched based on college and location trust',
                      style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _acceptBid(bid, task),
                    child: const Text('Accept Bid'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectBid(bid),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.nopeRed),
                    ),
                    child: Text(
                      'Reject',
                      style: TextStyle(color: AppTheme.nopeRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBid(Task task) async {
    if (_bidAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a bid amount'),
          backgroundColor: AppTheme.nopeRed,
        ),
      );
      return;
    }

    setState(() => _isSubmittingBid = true);

    try {
      await ref.read(bidsProvider(widget.taskId).notifier).submitBid(
        amount: double.parse(_bidAmountController.text),
        message: _bidMessageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid submitted successfully!'),
            backgroundColor: AppTheme.likeGreen,
          ),
        );
        _bidAmountController.clear();
        _bidMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting bid: ${e.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingBid = false);
      }
    }
  }

  Future<void> _acceptBid(Bid bid, Task task) async {
    try {
      final matchId = await ref.read(bidsProvider(widget.taskId).notifier).acceptBid(bid.id, bid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid accepted! Worker will be notified.'),
            backgroundColor: AppTheme.likeGreen,
          ),
        );
        // Navigate to chat if catch success
        if (matchId != null) {
          context.go('/matches/$matchId/chat');
        } else {
          context.go('/matches'); // Fallback to list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting bid: ${e.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectBid(Bid bid) async {
    try {
      await ref.read(bidsProvider(widget.taskId).notifier).rejectBid(bid.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid rejected'),
            backgroundColor: AppTheme.grey700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting bid: ${e.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTask(task);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.nopeRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: AppTheme.grey700,
          ),
        );
        context.go('/my-tasks');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: ${e.toString()}'),
            backgroundColor: AppTheme.nopeRed,
          ),
        );
      }
    }
  }

  String _formatPostedTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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