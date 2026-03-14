String formatPrice(num value, {int fractionDigits = 0}) {
  return '₹${value.toStringAsFixed(fractionDigits)}';
}
