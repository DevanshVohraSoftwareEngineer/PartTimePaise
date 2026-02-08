import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../managers/payment_manager.dart';
import '../../managers/auth_provider.dart';
import '../../data_types/payment.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final double amount;

  const PaymentScreen({super.key, this.taskId, required this.amount});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.upi;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': PaymentMethod.upi,
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'description': 'Paytm, Google Pay, PhonePe',
    },
    {
      'id': PaymentMethod.card,
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Visa, Mastercard, RuPay',
    },
    {
      'id': PaymentMethod.netbanking,
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'description': 'All major banks',
    },
    {
      'id': PaymentMethod.wallet,
      'name': 'Wallet',
      'icon': Icons.wallet,
      'description': 'Paytm, Mobikwik, Ola Money',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final platformFee = widget.amount * 0.05; // 5% platform fee
    final totalAmount = widget.amount + platformFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: _isProcessing ? null : IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isProcessing ? _buildProcessingScreen() : _buildPaymentForm(totalAmount, platformFee),
    );
  }

  Widget _buildProcessingScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.likeGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payment,
              size: 40,
              color: AppTheme.likeGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Payment...',
            style: AppTheme.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Please don\'t close this screen',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(double totalAmount, double platformFee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.grey100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Task Amount',
                      style: AppTheme.bodyMedium,
                    ),
                    Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Platform Fee (5%)',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
                    ),
                    Text(
                      '₹${platformFee.toStringAsFixed(0)}',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey600),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: AppTheme.heading2.copyWith(
                        color: AppTheme.boostGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Methods
          Text(
            'Choose Payment Method',
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 16),

          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),

          const SizedBox(height: 24),

          // Payment Form (simplified for demo)
          if (_selectedPaymentMethod == PaymentMethod.card) ...[
            Text(
              'Card Details',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
              ),
            ),
          ] else if (_selectedPaymentMethod == PaymentMethod.upi) ...[
            Text(
              'UPI ID',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'yourname@paytm',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _processPayment(totalAmount),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.likeGreen,
              ),
              child: Text(
                'Pay ₹${totalAmount.toStringAsFixed(0)}',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Security Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.likeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.likeGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: AppTheme.likeGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Payment',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.likeGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your payment information is encrypted and secure',
                        style: AppTheme.caption.copyWith(color: AppTheme.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.likeGreen : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = method['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.likeGreen.withOpacity(0.1)
                      : AppTheme.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'] as IconData,
                  color: isSelected ? AppTheme.likeGreen : AppTheme.grey600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'] as String,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.likeGreen : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method['description'] as String,
                      style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.likeGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(double totalAmount) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isProcessing = true);

    try {
      final paymentManager = ref.read(paymentManagerProvider(context));

      // Create payment object
      final payment = await paymentManager.createInstantPayment(
        taskId: widget.taskId ?? 'direct_payment',
        clientId: currentUser.id,
        workerId: 'system', // For direct payments, this might be different
        amount: widget.amount,
        paymentMethod: _selectedPaymentMethod,
      );

      // Process payment with Razorpay
      await paymentManager.processPayment(
        payment,
        currentUser.email,
        currentUser.phone ?? '',
      );

      // Payment success will be handled by the PaymentManager callbacks
      // The success dialog will be shown by the PaymentManager

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}