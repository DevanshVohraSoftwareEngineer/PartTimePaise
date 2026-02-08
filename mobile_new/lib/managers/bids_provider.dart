import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_types/bid.dart';
import '../services/supabase_service.dart';

// Bids state for a specific task
class TaskBidsState {
  final List<Bid> bids;
  final bool isLoading;
  final String? error;

  const TaskBidsState({
    this.bids = const [],
    this.isLoading = false,
    this.error,
  });

  TaskBidsState copyWith({
    List<Bid>? bids,
    bool? isLoading,
    String? error,
  }) {
    return TaskBidsState(
      bids: bids ?? this.bids,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TaskBidsNotifier extends StateNotifier<TaskBidsState> {
  final SupabaseService _supabaseService;
  final String _taskId;

  TaskBidsNotifier(this._supabaseService, this._taskId) : super(const TaskBidsState()) {
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    state = state.copyWith(isLoading: true);
    _supabaseService.getBidsStream(_taskId).listen((data) {
      final bids = data.map((json) => Bid.fromJson(json)).toList();
      state = state.copyWith(
        bids: bids,
        isLoading: false,
      );
    }, onError: (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    });
  }

  Future<void> submitBid({required double amount, required String message}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabaseService.submitBid(_taskId, amount, message);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<String?> acceptBid(String bidId, Bid bid) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // 1. Update Bid Status
      await _supabaseService.updateBidStatus(bidId, 'accepted');
      
      // 2. Update Task Status & Assign Worker
      await _supabaseService.updateTask(_taskId, {
        'status': 'assigned',
        'worker_id': bid.workerId,
      });

      // 3. Create a match record (Milan logic)
      String? matchId;
      try {
        matchId = await _supabaseService.createMatch(_taskId, bid.workerId);
      } catch (e) {
        print('Warning: Match record creation failed: $e');
      }

      state = state.copyWith(isLoading: false);
      return matchId;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> rejectBid(String bidId) async {
    try {
      await _supabaseService.updateBidStatus(bidId, 'rejected');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // DEBUG: Mock 10 candidates for "reality check"
  void mockApplicants() {
    final List<String> names = [
      "Aarav Sharma", "Priya Patel", "Ishaan Gupta", "Ananya Reddy", 
      "Vihaan Varma", "Sanya Malhotra", "Kabir Singh", "Myra Kapoor",
      "Arjun Nair", "Zoya Khan"
    ];
    
    final List<String> messages = [
      "I can do this quickly! I live just 500m away.",
      "Available now and have prior experience in this.",
      "I'm a student at IIT and looking for quick tasks.",
      "Reliable and punctual. Let's get this done.",
      "Can help with this right away. Please accept!",
      "I have my own tools and can start in 10 mins.",
      "Expert at this category. Check my ratings!",
      "I'm free for the next 4 hours. Happy to help.",
      "Prompt and professional service guaranteed.",
      "Local resident, familiar with the area. I can help!"
    ];

    final mockBids = List.generate(names.length, (index) {
      final id = 'mock-bid-${index + 1}';
      return Bid(
        id: id,
        taskId: _taskId,
        workerId: 'mock-worker-${index + 1}',
        workerName: names[index],
        amount: 200.0 + (index * 25.0),
        message: messages[index],
        status: 'pending',
        createdAt: DateTime.now().subtract(Duration(minutes: index * 5)),
        workerFaceUrl: 'https://i.pravatar.cc/150?u=worker$index', // Diverse faces
        workerIdCardUrl: 'https://placehold.co/600x400/blue/white?text=COLLEGE+ID+CARD+${index+1}', // Fake ID
      );
    });

    state = state.copyWith(bids: [...mockBids, ...state.bids]);
  }
}

// Provider for bids on a specific task
final bidsProvider = StateNotifierProvider.family<TaskBidsNotifier, TaskBidsState, String>(
  (ref, taskId) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    return TaskBidsNotifier(supabaseService, taskId);
  },
);

// My bids provider (for workers to see their submitted bids)
class MyBidsState {
  final List<Bid> bids;
  final bool isLoading;
  final String? error;

  const MyBidsState({
    this.bids = const [],
    this.isLoading = false,
    this.error,
  });

  MyBidsState copyWith({
    List<Bid>? bids,
    bool? isLoading,
    String? error,
  }) {
    return MyBidsState(
      bids: bids ?? this.bids,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyBidsNotifier extends StateNotifier<MyBidsState> {
  final SupabaseService _supabaseService;

  MyBidsNotifier(this._supabaseService) : super(const MyBidsState()) {
    loadMyBids();
  }

  Future<void> loadMyBids() async {
    state = state.copyWith(isLoading: true);
    try {
      // Load current user's bids from Supabase
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myBidsProvider = StateNotifierProvider<MyBidsNotifier, MyBidsState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MyBidsNotifier(supabaseService);
});