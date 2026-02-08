import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data_types/payment.dart';
import '../../managers/payment_manager.dart';
import '../../managers/auth_provider.dart';

class PaymentApprovalDialog extends ConsumerStatefulWidget {
  final String demandId;
  final String taskId;
  final String workerId;
  final String workerName;
  final double requestedAmount;
  final String reason;

  const PaymentApprovalDialog({
    super.key,
    required this.demandId,
    required this.taskId,
    required this.workerId,
    required this.workerName,
    required this.requestedAmount,
    required this.reason,
  });

  @override
  ConsumerState<PaymentApprovalDialog> createState() => _PaymentApprovalDialogState();
}

class _PaymentApprovalDialogState extends ConsumerState<PaymentApprovalDialog> {
  bool _isProcessing = false;

  Future<void> _approvePayment() async {
    setState(() => _isProcessing = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final paymentManager = ref.read(paymentManagerProvider(context));

      // Create payment object
      final payment = await paymentManager.createInstantPayment(
        taskId: widget.taskId,
        clientId: currentUser.id,
        workerId: widget.workerId,
        amount: widget.requestedAmount,
        paymentMethod: PaymentMethod.upi, // Default to UPI
      );

      // Accept the demand
      await paymentManager.acceptPaymentDemand(widget.demandId, payment);

      // Process the payment
      await paymentManager.processPayment(
        payment,
        currentUser.email ?? '',
        '', // Phone number would come from user profile
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectPayment() async {
    try {
      final paymentManager = ref.read(paymentManagerProvider(context));
      await paymentManager.rejectPaymentDemand(widget.demandId);

      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformFee = widget.requestedAmount * 0.05;
    final totalAmount = widget.requestedAmount + platformFee;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Request',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Worker: ${widget.workerName}',
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requested Amount: ₹${widget.requestedAmount.toStringAsFixed(0)}',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform Fee (5%): ₹${platformFee.toStringAsFixed(0)}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ₹${totalAmount.toStringAsFixed(0)}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.reason,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey700),
            ),
            const SizedBox(height: 24),
            Text(
              'By approving this payment, ₹${widget.requestedAmount.toStringAsFixed(0)} will be transferred to the worker immediately.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : _rejectPayment,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _approvePayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Pay Now',
                            style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
