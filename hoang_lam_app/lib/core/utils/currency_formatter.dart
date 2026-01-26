import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// Currency formatting utilities
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: AppConstants.vndDecimalPlaces,
  );

  static final _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: AppConstants.usdDecimalPlaces,
  );

  static final _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Format amount as VND
  static String formatVND(num amount) {
    return _vndFormat.format(amount);
  }

  /// Format amount as USD
  static String formatUSD(num amount) {
    return _usdFormat.format(amount);
  }

  /// Format amount with currency code
  static String format(num amount, {String currency = 'VND'}) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return formatUSD(amount);
      case 'VND':
      default:
        return formatVND(amount);
    }
  }

  /// Format as compact (e.g., 1.2M, 500K)
  static String formatCompact(num amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return _numberFormat.format(amount);
  }

  /// Format number with thousand separators
  static String formatNumber(num amount) {
    return _numberFormat.format(amount);
  }

  /// Parse formatted string to number
  static num? parse(String value) {
    try {
      // Remove currency symbols and spaces
      final cleaned = value
          .replaceAll('₫', '')
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .replaceAll('.', '')
          .replaceAll(' ', '')
          .trim();
      return num.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
