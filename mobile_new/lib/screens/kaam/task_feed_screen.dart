import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../data_types/task.dart';
import '../../managers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../helpers/location_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/supabase_service.dart';
import '../../widgets/task_view_track_wrapper.dart';
import '../../widgets/countdown_timer.dart';

class TaskFeedScreen extends ConsumerStatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  ConsumerState<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends ConsumerState<TaskFeedScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Warm start: only fetch if empty, otherwise real-time handles it
      if (ref.read(tasksProvider).tasks.isEmpty) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService().getCurrentLocation();
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final currentUser = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 1, // Only one tab now: Today (ASAP is strictly via alerts)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Task Feed'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'AVAILABLE TODAY'),
            ],
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/kaam/post');
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            TaskListView(isAsap: false, tasksState: tasksState, currentUser: currentUser, currentPosition: _currentPosition),
          ],
        ),
      ),
    );
  }
}

class TaskListView extends ConsumerStatefulWidget {
  final bool isAsap;
  final TasksState tasksState;
  final dynamic currentUser;
  final Position? currentPosition;

  const TaskListView({
    super.key,
    required this.isAsap,
    required this.tasksState,
    required this.currentUser,
    this.currentPosition,
  });

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedTaskIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final swipedTaskIds = ref.watch(swipedTaskIdsProvider);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final filteredTasks = widget.tasksState.tasks.where((task) {
      final isTaskAsap = task.urgency?.toLowerCase() == 'asap';
      
      // Filter by Tab
      if (widget.isAsap) {
        if (!isTaskAsap) return false;
      } else {
        // TODAY tab: Show tasks with urgency 'today' OR tasks posted today
        final isTaskToday = task.urgency?.toLowerCase() == 'today';
        final postedToday = task.createdAt.isAfter(todayStart);
        if (!isTaskToday && !postedToday) return false;
        if (isTaskAsap) return false; // Keep ASAP in its own tab
      }

      return !task.isExpired && 
             task.clientId != widget.currentUser?.id &&
             !swipedTaskIds.contains(task.id) &&
             (task.status == 'open' || task.status == 'broadcasting');
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(tasksProvider.notifier).loadTasks(refresh: true);
      },
      child: _buildContent(filteredTasks),
    );
  }

  Widget _buildContent(List<Task> filteredTasks) {
    if (widget.tasksState.isLoading && filteredTasks.isEmpty) {
      return _buildSkeletonLoader();
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
      itemCount: filteredTasks.length + (widget.tasksState.hasMore ? 1 : 0),
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
        return TaskViewTrackWrapper(
          taskId: task.id,
          child: _buildCollapsibleTaskBar(context, task, widget.currentUser?.id),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: primaryColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks will appear here in real-time',
            style: TextStyle(
              color: primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleTaskBar(BuildContext context, Task task, String? currentUserId) {
    final isExpanded = _expandedTaskIds.contains(task.id);
    final distanceKm = (widget.currentPosition != null && task.latitude != null && task.longitude != null)
        ? (Geolocator.distanceBetween(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
              task.latitude!,
              task.longitude!,
            ) / 1000)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
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
                                  color: primaryColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.urgency == 'asap' ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: task.urgency == 'asap' ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                task.urgency?.toUpperCase() ?? 'TODAY',
                                style: TextStyle(
                                  color: task.urgency == 'asap' ? Colors.red : Colors.blue,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (distanceKm != null)
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                            if (distanceKm != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('•', style: TextStyle(color: primaryColor.withOpacity(0.3))),
                              ),
                            Text(
                              '₹${task.budget.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: primaryColor.withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),
                            CountdownTimer(
                              expiresAt: task.effectiveExpiresAt,
                              textStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.withOpacity(0.8),
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
                    color: primaryColor.withOpacity(0.3),
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
                  Divider(height: 1, color: primaryColor.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  
                  // Poster Profile Snippet
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        backgroundImage: task.clientAvatar != null 
                            ? CachedNetworkImageProvider(task.clientAvatar!) 
                            : null,
                        child: task.clientAvatar == null 
                            ? Text(task.clientName?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(fontSize: 10, color: primaryColor)) 
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
                                    color: primaryColor,
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
                                    style: TextStyle(fontSize: 10, color: primaryColor.withOpacity(0.5)),
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
                      color: primaryColor.withOpacity(0.8),
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: primaryColor.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.location ?? 'See map in details',
                          style: TextStyle(color: primaryColor.withOpacity(0.5), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _getTimeAgo(task.createdAt),
                        style: TextStyle(color: primaryColor.withOpacity(0.4), fontSize: 11),
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
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            foregroundColor: primaryColor,
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
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
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
      
      // Optimistic Update: Immediately hide from feed across all screens using this provider
      ref.read(swipedTaskIdsProvider.notifier).addSwipedIdLocally(task.id);
      
      await supabaseService.createSwipe(task.id, direction);
      
      if (mounted) {
        if (direction == 'right') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Applied for ${task.title}!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
