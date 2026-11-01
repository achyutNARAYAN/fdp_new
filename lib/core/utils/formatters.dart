import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as integer currency e.g. ₹480
  static String formatCurrency(double amount) {
    if (amount % 1 == 0) {
      return _currencyFormat.format(amount);
    }
    return _currencyDecimalFormat.format(amount);
  }

  /// Format seconds into mm:ss e.g. 180 -> "03:00"
  static String formatCountdown(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Clean Indian phone number input (removes spaces, +91, leading 0)
  static String cleanIndianPhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.startsWith('0') && cleaned.length > 10) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Validate Indian 10-digit mobile number
  static bool isValidIndianPhone(String phone) {
    final cleaned = cleanIndianPhone(phone);
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Format date readable
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Format short date e.g. "Today, 4:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }
}

