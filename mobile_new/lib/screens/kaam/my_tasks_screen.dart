import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../helpers/location_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data_types/task.dart';

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  Position? _currentPosition;
  final Set<String> _expandedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService().getCurrentLocation();
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliedTasksState = ref.watch(appliedTasksProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Re-trigger stream or just wait for realtime
          ref.invalidate(appliedTasksProvider);
        },
        child: appliedTasksState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appliedTasksState.tasks.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: appliedTasksState.tasks.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final task = appliedTasksState.tasks[index];
                      return _buildAppliedTaskBar(context, task);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/post-task');
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Task'),
      ),
    );
  }

  Widget _buildAppliedTaskBar(BuildContext context, Task task) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        Row(
                          children: [
                            if (distanceKm != null) ...[
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km away',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(task.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(task.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${task.budget.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.navyDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Client info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.grey200,
                        backgroundImage: task.clientAvatar != null 
                            ? CachedNetworkImageProvider(task.clientAvatar!) 
                            : null,
                        child: task.clientAvatar == null 
                            ? Text(task.clientName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 10)) 
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.clientName ?? 'Customer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _getBadge(task.category, Colors.blue),
                      if (task.deadline != null)
                         _getBadge(DateFormat('MMM dd').format(task.deadline!), Colors.grey),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/my-tasks/completion/${task.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('MANAGE TASK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _getBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/swipe');
            break;
          case 1:
            context.go('/matches');
            break;
          case 2:
            context.go('/post-task');
            break;
          case 3:
            context.go('/posted-tasks');
            break;
          case 4:
            // Already on my-tasks screen
            break;
          case 5:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Post Task',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Posted Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'My Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No applications found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tasks you apply for will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppTheme.superLikeBlue;
      case 'matched':
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
}
