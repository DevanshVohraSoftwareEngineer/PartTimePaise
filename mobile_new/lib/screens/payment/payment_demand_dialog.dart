import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../managers/payment_manager.dart';
import '../../managers/auth_provider.dart';
import '../../managers/fees_manager.dart';

class PaymentDemandDialog extends ConsumerStatefulWidget {
  final String taskId;
  final String clientId;
  final double maxAmount;

  const PaymentDemandDialog({
    Key? key,
    required this.taskId,
    required this.clientId,
    required this.maxAmount,
  }) : super(key: key);

  @override
  ConsumerState<PaymentDemandDialog> createState() => _PaymentDemandDialogState();
}

class _PaymentDemandDialogState extends ConsumerState<PaymentDemandDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDemand() async {
    if (_amountController.text.isEmpty || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || amount > widget.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final paymentManager = ref.read(paymentManagerProvider(context));

      await paymentManager.createPaymentDemand(
        taskId: widget.taskId,
        workerId: currentUser.id,
        clientId: widget.clientId,
        amount: amount,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request sent to client'),
            backgroundColor: Colors.green,
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Request Payment',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Request payment from the client for your completed work.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'Enter amount (max ₹${widget.maxAmount.toStringAsFixed(0)})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              onChanged: (val) => setState(() {}),
            ),
            if (_amountController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final amt = double.tryParse(_amountController.text) ?? 0;
                final fee = FeesManager.calculateFee(amt);
                final total = FeesManager.calculateTotal(amt);
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Amount:'),
                          Text('₹${amt.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Convenience Fee:', style: TextStyle(color: AppTheme.grey600)),
                          Text('₹${fee.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.grey600)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Payable:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyMedium)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain why you\'re requesting this payment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDemand,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Request Payment',
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