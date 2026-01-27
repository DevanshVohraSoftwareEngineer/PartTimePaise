class FeesManager {
  static const double _minFee = 3.0;
  static const double _percentage = 0.01; // 1%

  /// Calculates the convenience fee based on the transaction amount.
  /// Rule: Max(3rs, 1% of total)
  static double calculateFee(double amount) {
    if (amount <= 0) return 0.0;
    
    final percentageFee = amount * _percentage;
    return percentageFee > _minFee ? percentageFee : _minFee;
  }

  /// Returns the total amount payable (Base Amount + Fee)
  static double calculateTotal(double amount) {
    return amount + calculateFee(amount);
  }
}
