import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data_types/payment.dart';
import '../services/supabase_service.dart';

class PaymentManager {
  final SupabaseService _supabaseService;
  late Razorpay _razorpay;
  final BuildContext context;

  PaymentManager(this._supabaseService, this.context) {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    // razorpay event handlers...
  }

  void dispose() {
    _razorpay.clear();
  }

  // Payment processing logic using Supabase...
  Future<Payment> createInstantPayment({
    required String taskId,
    required String clientId,
    required String workerId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    return Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      clientId: clientId,
      workerId: workerId,
      amount: amount,
      platformFee: amount * 0.05,
      totalAmount: amount * 1.05,
      paymentMethod: paymentMethod,
      paymentType: PaymentType.instant,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Future<void> processPayment(Payment payment, String email, String contact) async {
    // Razorpay logic
  }

  Future<void> createPaymentDemand({
    required String taskId,
    required String workerId,
    required String clientId,
    required double amount,
    required String reason,
  }) async {
    // Create demand
  }

  Future<void> acceptPaymentDemand(String demandId, Payment payment) async {
    // Accept demand logic
  }

  Future<void> rejectPaymentDemand(String demandId) async {
    // Reject demand logic
  }
}

// Provider for PaymentManager
final paymentManagerProvider = Provider.family<PaymentManager, BuildContext>((ref, context) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PaymentManager(supabaseService, context);
});

// Payment state management
class PaymentState {
  final List<Payment> payments;
  final List<PaymentDemand> demands;
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.payments = const [],
    this.demands = const [],
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<Payment>? payments,
    List<PaymentDemand>? demands,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      demands: demands ?? this.demands,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final SupabaseService _supabaseService;

  PaymentNotifier(this._supabaseService) : super(const PaymentState());

  Future<void> loadPayments() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabaseService.client
          .from('payments')
          .select()
          .or('client_id.eq.$userId,worker_id.eq.$userId')
          .order('created_at', ascending: false);
      
      final payments = (response as List).map((json) => Payment.fromJson(json)).toList();
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createPaymentDemand({
    required String taskId,
    required String workerId,
    required String clientId,
    required double amount,
    required String reason,
  }) async {
    // Logic to create demand in Supabase
  }

  Future<void> acceptPaymentDemand(String demandId, Payment payment) async {
    // Accept demand logic
  }

  Future<void> rejectPaymentDemand(String demandId) async {
    // Reject demand logic
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return PaymentNotifier(supabaseService);
});