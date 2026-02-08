import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../data_types/earnings.dart';

final workerEarningsProvider = FutureProvider<WorkerEarningsSummary>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getWorkerEarningsSummary();
});

final todayEarningsProvider = FutureProvider<double>((ref) async {
  final summary = await ref.watch(workerEarningsProvider.future);
  final today = DateTime.now();
  
  return summary.taskEarnings
      .where((te) => 
        te.completedAt.year == today.year && 
        te.completedAt.month == today.month && 
        te.completedAt.day == today.day)
      .fold<double>(0.0, (sum, te) => sum + te.totalTaskEarnings);
});
