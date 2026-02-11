import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import '../data_types/task.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// Tasks state
class TasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final SupabaseService _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _tasksSubscription;

  TasksNotifier(this._supabaseService) : super(const TasksState()) {
    _initializeRealTimeUpdates();
  }

  void _initializeRealTimeUpdates() {
    if (state.tasks.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    // ✨ Magic: Allotment Heartbeat (Ensures no gig gets stuck)
    _triggerAllotmentHeartbeat();

    // Listen to tasks table for real-time updates
    _tasksSubscription = _supabaseService.getTasksStream().listen(
      (data) {
        _handleTaskData(data);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString(), isLoading: false);
      },
    );
  }

  void _handleTaskData(List<Map<String, dynamic>> data) {
    final tasks = data.map((json) => Task.fromJson(json)).toList();
    
    // Deduplication (Enforce uniqueness by ID) AND Expiration Filter
    final uniqueTasks = <String, Task>{};
    for (var task in tasks) {
      if (!task.isExpired) {
        uniqueTasks[task.id] = task;
      }
    }
    
    // Smooth transition: No flickers when data arrives
    state = state.copyWith(
      tasks: uniqueTasks.values.toList(), 
      isLoading: false
    );
  }

  Future<void> _triggerAllotmentHeartbeat() async {
    try {
      // Calls the Postgres function to clear stale alerts and escalate dispatch
      await _supabaseService.client.rpc('expire_stale_gig_requests');
    } catch (e) {
      print('Heartbeat error: $e'); // Silent fail is fine for heartbeat
    }
  }

  Future<void> loadTasks({bool refresh = false}) async {
    if (state.tasks.isEmpty || refresh) {
      state = state.copyWith(isLoading: state.tasks.isEmpty);
    }
    try {
      final data = await _supabaseService.client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      _handleTaskData(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadTask(String taskId) async {
    try {
      final data = await _supabaseService.client
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();
      
      final task = Task.fromJson(data);
      
      // Update local state if task exists in list, or add it
      final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex >= 0) {
        final updatedTasks = List<Task>.from(state.tasks);
        updatedTasks[taskIndex] = task;
        state = state.copyWith(tasks: updatedTasks);
      } else {
        state = state.copyWith(tasks: [task, ...state.tasks]);
      }
    } catch (e) {
      // Handle error cleanly
      print('Error loading task: $e');
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> createTask(Map<String, dynamic> data, {File? verificationImage}) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // ✨ Magic: Optimistic UI - Create temporary task object
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempTask = Task.fromJson({
      ...data,
      'id': tempId,
      'client_id': userId,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Add locally
    state = state.copyWith(tasks: [tempTask, ...state.tasks]);

    try {
      await _supabaseService.createTask(data, verificationImage: verificationImage);
      // Real-time stream will replace tempTask with the actual one from DB
    } catch (e) {
      // Rollback
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != tempId).toList(),
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  // Local state operations for immediate UI feedback
  void addTaskLocally(Task task) {
    state = state.copyWith(tasks: [task, ...state.tasks]);
  }

  void addTask(Task task) {
    addTaskLocally(task);
  }

  void removeTask(String taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabaseService.updateTask(taskId, data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabaseService.deleteTask(taskId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return TasksNotifier(supabaseService);
});

final myTasksProvider = StateNotifierProvider<MyTasksNotifier, MyTasksState>((ref) {
  final user = ref.watch(currentUserProvider);
  return MyTasksNotifier(ref.read(supabaseServiceProvider), user?.id);
});

class MyTasksNotifier extends StateNotifier<MyTasksState> {
  final SupabaseService _supabaseService;
  final String? _userId;
  StreamSubscription<List<Map<String, dynamic>>>? _myTasksSubscription;

  MyTasksNotifier(this._supabaseService, this._userId) : super(const MyTasksState()) {
    if (_userId != null) {
      _initializeMyTasksListener();
    }
  }

  void _initializeMyTasksListener() {
    if (state.tasks.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    // Listen to current user's tasks
    _myTasksSubscription = _supabaseService.getTasksStream().listen(
      (data) {
        _handleMyTaskData(data);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString(), isLoading: false);
      },
    );
  }

  void _handleMyTaskData(List<Map<String, dynamic>> data) {
    // Filter locally for current user and check for expiration
    final myTasks = data
        .where((json) => json['client_id'] == _userId)
        .map((json) => Task.fromJson(json))
        .where((task) => !task.isExpired)
        .toList();
    state = state.copyWith(tasks: myTasks, isLoading: false);
  }
  
  @override
  void dispose() {
    _myTasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadMyTasks() async {
    if (_userId == null) return;
    
    // Only show loader if we have no data yet
    if (state.tasks.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    try {
      final data = await _supabaseService.client
          .from('tasks')
          .select()
          .eq('client_id', _userId ?? '')
          .order('created_at', ascending: false);
      _handleMyTaskData(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// My Tasks State
class MyTasksState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const MyTasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  MyTasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return MyTasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Applied Tasks State (Tasks I want to do)
final appliedTasksProvider = StateNotifierProvider<AppliedTasksNotifier, TasksState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AppliedTasksNotifier(supabaseService);
});

class AppliedTasksNotifier extends StateNotifier<TasksState> {
  final SupabaseService _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _swipesSubscription;

  AppliedTasksNotifier(this._supabaseService) : super(const TasksState()) {
    _initializeAppliedTasksListener();
  }

  void _initializeAppliedTasksListener() {
    if (state.tasks.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    // Listen to swipes where user_id = me AND direction = right
    _swipesSubscription = _supabaseService.getMyAppliedSwipesStream().listen(
      (swipesData) {
         _handleSwipesData(swipesData);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString(), isLoading: false);
      },
    );
  }

  Future<void> _handleSwipesData(List<Map<String, dynamic>> swipesData) async {
    if (swipesData.isEmpty) {
      state = state.copyWith(tasks: [], isLoading: false);
      return;
    }

    final taskIds = swipesData.map((s) => s['task_id'] as String).toList();
    
    try {
      // 2. Fetch the actual tasks for these IDs
      // Note: 'in' filter is limited to ~10-20 items in URL params sometimes, but basic postgrest is fine.
      // If list is huge, might need pagination or batching. For now, simple 'in'.
      final tasksData = await _supabaseService.client
          .from('tasks')
          .select()
          .filter('id', 'in', '(${taskIds.join(',')})')
          .order('created_at', ascending: false);
      
      final tasks = (tasksData as List)
          .map((json) => Task.fromJson(json))
          .where((task) => !task.isExpired)
          .toList();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      // If fetch fails (maybe network), keep loading off but show error
      state = state.copyWith(error: 'Failed to load applied tasks: $e', isLoading: false);
    }
  }

  @override
  void dispose() {
    _swipesSubscription?.cancel();
    super.dispose();
  }
}

// Global Swiped Task IDs (Both directions) for filtering
final swipedTaskIdsProvider = StateNotifierProvider<SwipedTasksNotifier, Set<String>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SwipedTasksNotifier(supabaseService);
});

class SwipedTasksNotifier extends StateNotifier<Set<String>> {
  final SupabaseService _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _swipesSubscription;

  SwipedTasksNotifier(this._supabaseService) : super({}) {
    _initializeSwipesListener();
  }

  void _initializeSwipesListener() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // Listen to ALL swipes by this user (including debug users)
    _swipesSubscription = _supabaseService.client
        .from('swipes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
      (data) {
        final ids = data.map((s) => s['task_id'] as String).toSet();
        state = ids;
      },
      onError: (e) {
        print('SwipedTasks error: $e');
      }
    );
  }

  void addSwipedIdLocally(String taskId) {
    state = {...state, taskId};
  }

  @override
  void dispose() {
    _swipesSubscription?.cancel();
    super.dispose();
  }
}
