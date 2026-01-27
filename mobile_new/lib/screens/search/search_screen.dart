import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../managers/tasks_provider.dart';
import '../../data_types/task.dart';
import '../../managers/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _maxDistance = 50;

  final List<String> _categories = [
    'All',
    'Development',
    'Design',
    'Writing',
    'Marketing',
    'Photography',
    'Video Editing',
    'Translation',
    'Data Entry',
    'Virtual Assistant',
    'Other',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Price: Low to High',
    'Price: High to Low',
    'Distance',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final tasks = ref.watch(tasksProvider);
    final filteredTasks = _filterTasks(tasks);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search tasks, skills, or keywords...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters bar
          if (_hasActiveFilters()) _buildActiveFilters(),

          // Results
          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task, currentUser?.role == 'worker');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.grey50,
      child: Row(
        children: [
          Text(
            'Filters:',
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCategory != 'All')
                    _buildFilterChip(_selectedCategory, () {
                      setState(() => _selectedCategory = 'All');
                    }),
                  if (_priceRange.start > 0 || _priceRange.end < 5000)
                    _buildFilterChip(
                      '₹${_priceRange.start.toInt()}-₹${_priceRange.end.toInt()}',
                      () {
                        setState(() => _priceRange = const RangeValues(0, 5000));
                      },
                    ),
                  if (_selectedSort != 'Newest')
                    _buildFilterChip(_selectedSort, () {
                      setState(() => _selectedSort = 'Newest');
                    }),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: AppTheme.caption.copyWith(color: AppTheme.superLikeBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: AppTheme.caption),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppTheme.superLikeBlue.withOpacity(0.1),
        labelStyle: TextStyle(color: AppTheme.superLikeBlue),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Start searching for tasks' : 'No tasks found',
            style: AppTheme.heading2.copyWith(color: AppTheme.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Use the search bar above to find tasks that match your skills'
                : 'Try adjusting your filters or search terms',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isWorker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to task details
        },
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
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.taskStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task.taskStatus),
                      style: AppTheme.caption.copyWith(
                        color: _getStatusColor(task.taskStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: AppTheme.likeGreen),
                  Text(
                    task.budget.toStringAsFixed(0),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.likeGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: AppTheme.grey500),
                  Expanded(
                    child: Text(
                      task.location ?? 'Remote',
                      style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.bidsCount != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: AppTheme.superLikeBlue),
                    Text(
                      '${task.bidsCount} bids',
                      style: AppTheme.caption.copyWith(color: AppTheme.superLikeBlue),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatTimeAgo(task.createdAt),
                    style: AppTheme.caption.copyWith(color: AppTheme.grey500),
                  ),
                  const Spacer(),
                  if (isWorker && task.taskStatus == TaskStatus.open)
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to bid screen
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Bid Now'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filters',
                    style: AppTheme.heading2,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category
              Text(
                'Category',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                      setState(() {});
                    },
                    backgroundColor: AppTheme.grey100,
                    selectedColor: AppTheme.superLikeBlue.withOpacity(0.1),
                    checkmarkColor: AppTheme.superLikeBlue,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Price Range
              Text(
                'Budget Range',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 5000,
                divisions: 50,
                labels: RangeLabels(
                  '₹${_priceRange.start.toInt()}',
                  '₹${_priceRange.end.toInt()}',
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                  setState(() {});
                },
                activeColor: AppTheme.superLikeBlue,
              ),

              const SizedBox(height: 24),

              // Sort By
              Text(
                'Sort By',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sortOptions.map((sort) {
                  final isSelected = _selectedSort == sort;
                  return FilterChip(
                    label: Text(sort),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedSort = selected ? sort : 'Newest';
                      });
                      setState(() {});
                    },
                    backgroundColor: AppTheme.grey100,
                    selectedColor: AppTheme.superLikeBlue.withOpacity(0.1),
                    checkmarkColor: AppTheme.superLikeBlue,
                  );
                }).toList(),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Task> _filterTasks(TasksState tasksState) {
    final tasks = tasksState.tasks;
    return tasks.where((task) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDescription = task.description.toLowerCase().contains(query);
        final matchesCategory = task.category?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDescription && !matchesCategory) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All' && task.category != _selectedCategory) {
        return false;
      }

      // Price range filter
      if (task.budget < _priceRange.start || task.budget > _priceRange.end) {
        return false;
      }

      return true;
    }).toList()
      ..sort(_getSortComparator());
  }

  Comparator<Task> _getSortComparator() {
    switch (_selectedSort) {
      case 'Newest':
        return (a, b) => b.createdAt.compareTo(a.createdAt);
      case 'Oldest':
        return (a, b) => a.createdAt.compareTo(b.createdAt);
      case 'Price: Low to High':
        return (a, b) => a.budget.compareTo(b.budget);
      case 'Price: High to Low':
        return (a, b) => b.budget.compareTo(a.budget);
      case 'Distance':
        // TODO: Implement distance sorting based on user location
        return (a, b) => a.createdAt.compareTo(b.createdAt);
      default:
        return (a, b) => b.createdAt.compareTo(a.createdAt);
    }
  }

  bool _hasActiveFilters() {
    return _selectedCategory != 'All' ||
           _priceRange.start > 0 ||
           _priceRange.end < 5000 ||
           _selectedSort != 'Newest';
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _priceRange = const RangeValues(0, 5000);
      _selectedSort = 'Newest';
    });
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return AppTheme.likeGreen;
      case TaskStatus.inProgress:
        return AppTheme.boostGold;
      case TaskStatus.completed:
        return AppTheme.superLikeBlue;
      case TaskStatus.cancelled:
        return AppTheme.nopeRed;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
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
}