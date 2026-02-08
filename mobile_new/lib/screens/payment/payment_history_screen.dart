import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../managers/payment_manager.dart';
import '../../managers/auth_provider.dart';
import '../../data_types/payment.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref.read(paymentProvider.notifier).loadPayments();
    }
  }

  String _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return '🟢 Completed';
      case PaymentStatus.pending:
        return '🟡 Pending';
      case PaymentStatus.processing:
        return '🔵 Processing';
      case PaymentStatus.failed:
        return '🔴 Failed';
      case PaymentStatus.cancelled:
        return '⚪ Cancelled';
      case PaymentStatus.refunded:
        return '🟠 Refunded';
    }
  }

  String _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return '📱';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.netbanking:
        return '🏦';
      case PaymentMethod.wallet:
        return '👛';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final currentUser = ref.read(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: paymentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentState.payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment,
                        size: 64,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history yet',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppTheme.grey600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your payment transactions will appear here',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paymentState.payments.length,
                    itemBuilder: (context, index) {
                      final payment = paymentState.payments[index];
                      final isClient = payment.clientId == currentUser?.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Task #${payment.taskId.substring(0, 8)}',
                                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(payment.status).contains('🟢')
                                          ? Colors.green.withOpacity(0.1)
                                          : _getStatusColor(payment.status).contains('🟡')
                                              ? Colors.yellow.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusColor(payment.status).substring(2),
                                      style: AppTheme.caption.copyWith(
                                        color: _getStatusColor(payment.status).contains('🟢')
                                            ? Colors.green
                                            : _getStatusColor(payment.status).contains('🟡')
                                                ? Colors.orange
                                                : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _getPaymentMethodIcon(payment.paymentMethod),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    payment.paymentMethod.name.toUpperCase(),
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    isClient ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16,
                                    color: isClient ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isClient ? 'Paid' : 'Received',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: isClient ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amount: ₹${payment.amount.toStringAsFixed(0)}',
                                        style: AppTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      if (payment.platformFee > 0)
                                        Text(
                                          'Fee: ₹${payment.platformFee.toStringAsFixed(0)}',
                                          style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                                        ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(payment.createdAt),
                                        style: AppTheme.caption,
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(payment.createdAt),
                                        style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (payment.transactionId != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Transaction ID: ${payment.transactionId}',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.grey600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                              if (payment.failureReason != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Failed: ${payment.failureReason}',
                                    style: AppTheme.caption.copyWith(color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
