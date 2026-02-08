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
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Razorpay: Payment Success: ${response.paymentId}');
    // Here we would confirm with Supabase via Edge Function or DB trigger
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful! Processing transaction...'), backgroundColor: Colors.green),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Razorpay: Payment Error: ${response.code} - ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💰 Razorpay: External Wallet Selected: ${response.walletName}');
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
    // Generate a unique order ref
    final orderId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final payment = Payment(
      id: orderId,
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

    // ✨ Magic: Record the pending payment in Supabase
    await _supabaseService.client.from('payments').insert({
      'id': orderId,
      'task_id': taskId,
      'client_id': clientId,
      'worker_id': workerId,
      'amount': amount,
      'platform_fee': payment.platformFee,
      'total_amount': payment.totalAmount,
      'status': 'pending',
      'payment_method': paymentMethod.toString().split('.').last,
      'type': 'instant',
    });

    return payment;
  }

  Future<void> processPayment(Payment payment, String email, String contact) async {
    final options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Use test key initially
      'amount': (payment.totalAmount * 100).toInt(), // Razorpay expects paise (INR)
      'name': 'Happle',
      'description': 'Payment for Task: ${payment.taskId.substring(0, 8)}',
      'timeout': 300, // in seconds
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Razorpay Open Error: $e');
    }
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
