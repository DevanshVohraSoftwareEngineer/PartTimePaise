import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'auth_provider.dart';

class MealRecord {
  final String id;
  final String item;
  final String calories;
  final String date;
  final File? imageFile;
  final Map<String, dynamic> fullResults;

  MealRecord({
    required this.id,
    required this.item,
    required this.calories,
    required this.date,
    this.imageFile,
    required this.fullResults,
  });
}

class MealHistoryNotifier extends StateNotifier<List<MealRecord>> {
  MealHistoryNotifier() : super([]);

  void addRecord(Map<String, dynamic> results, File? image) {
    final newRecord = MealRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      item: results['item'] ?? 'Unknown Meal',
      calories: (results['calories'] ?? 0).toString(),
      date: DateTime.now().toString(),
      imageFile: image,
      fullResults: results,
    );
    state = [newRecord, ...state];
    
    // Limit to last 10 scans for performance in demo
    if (state.length > 10) {
      state = state.sublist(0, 10);
    }
  }

  void clearHistory() {
    state = [];
  }
}

final mealHistoryProvider = StateNotifierProvider<MealHistoryNotifier, List<MealRecord>>((ref) {
  // Watch the user ID. If the user changes (login/logout), 
  // this provider will naturally dispose and re-initialize its state,
  // ensuring that one user's scan history never leaks to another.
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  
  // Dummy check to satisfy lint while ensuring reactivity
  if (userId == null) return MealHistoryNotifier();
  
  return MealHistoryNotifier();
});
