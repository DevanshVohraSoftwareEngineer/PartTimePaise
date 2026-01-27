import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../data_types/task.dart';
import '../../managers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../helpers/location_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/supabase_service.dart';

class TaskFeedScreen extends ConsumerStatefulWidget {
  const TaskFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends ConsumerState<TaskFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  Position? _currentPosition;
  final Set<String> _expandedTaskIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks(refresh: true);
      _getCurrentLocation();
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService().getCurrentLocation();
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // For now, no pagination since real-time updates load all
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Task Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/kaam/post');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tasksProvider.notifier).loadTasks(refresh: true);
        },
        child: (() {
          final swipedTaskIds = ref.watch(swipedTaskIdsProvider);
          final filteredTasks = tasksState.tasks.where((task) {
            final hoursOld = DateTime.now().difference(task.createdAt).inHours;
            return hoursOld < 10 && 
                   task.clientId != currentUser?.id &&
                   !swipedTaskIds.contains(task.id);
          }).toList();

          if (tasksState.isLoading && filteredTasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (filteredTasks.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState(),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            itemCount: filteredTasks.length + (tasksState.hasMore ? 1 : 0),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              if (index == filteredTasks.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final task = filteredTasks[index];
              return _buildCollapsibleTaskBar(context, task, currentUser?.id);
            },
          );
        }()),
      )
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks will appear here in real-time',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleTaskBar(BuildContext context, Task task, String? currentUserId) {
    final isExpanded = _expandedTaskIds.contains(task.id);
    final distanceKm = (_currentPosition != null && task.latitude != null && task.longitude != null)
        ? (Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              task.latitude!,
              task.longitude!,
            ) / 1000)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // The "Bar" (Compact View - Zomato Style)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTaskIds.remove(task.id);
                } else {
                  _expandedTaskIds.add(task.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Indicators Container
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppTheme.navyDark,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (distanceKm != null)
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF34C759),
                                ),
                              ),
                            if (distanceKm != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('•', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                              ),
                            Text(
                              '₹${task.budget.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white70 : AppTheme.navyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick Actions (Tick/Cross Circles)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.close_rounded,
                        color: Colors.red,
                        onTap: () => _handleQuickAction(context, task, 'left'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        icon: Icons.check_rounded,
                        color: Colors.green,
                        onTap: () => _handleQuickAction(context, task, 'right'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details Card
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Poster Profile Snippet
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.grey200,
                        backgroundImage: task.clientAvatar != null 
                            ? CachedNetworkImageProvider(task.clientAvatar!) 
                            : null,
                        child: task.clientAvatar == null 
                            ? Text(task.clientName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 10)) 
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  task.clientName ?? 'Customer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (task.clientVerificationStatus == 'verified')
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.verified, size: 14, color: Color(0xFF0095F6)),
                                  ),
                              ],
                            ),
                            if (task.clientRating != null)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                  Text(
                                    ' ${task.clientRating!.toStringAsFixed(1)} Rating',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      _getCategoryBadge(task.category),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.location ?? 'See map in details',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _getTimeAgo(task.createdAt),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/task-details/${task.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : AppTheme.grey100,
                            foregroundColor: isDark ? Colors.white : AppTheme.navyDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleQuickAction(context, task, 'right'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navyDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('APPLY NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _getCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCategoryColor(category).withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: _getCategoryColor(category),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return Colors.blue;
      case 'delivery':
        return Colors.green;
      case 'cleaning':
        return Colors.purple;
      case 'tutoring':
        return Colors.orange;
      case 'tech support':
        return Colors.red;
      default:
        return AppTheme.navyMedium;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  Future<void> _handleQuickAction(BuildContext context, Task task, String direction) async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.createSwipe(task.id, direction);
      
      if (mounted) {
        if (direction == 'right') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Application sent! Check "Applied" section.'),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
           // Permanent Rejection visual feedback
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task removed from feed.'),
              backgroundColor: AppTheme.navyDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
