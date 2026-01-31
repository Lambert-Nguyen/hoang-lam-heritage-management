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
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final prefix = isNegative ? '-' : '';
    
    if (absAmount >= 1000000000) {
      return '$prefix${(absAmount / 1000000000).toStringAsFixed(1)}B';
    } else if (absAmount >= 1000000) {
      return '$prefix${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      return '$prefix${(absAmount / 1000).toStringAsFixed(0)}K';
    }
    return '$prefix${_numberFormat.format(absAmount)}';
  }

  /// Format number with thousand separators
  static String formatNumber(num amount) {
    return _numberFormat.format(amount);
  }

  /// Parse formatted string to number
  /// 
  /// Supports both VND (e.g., "1.000.000đ" or "1,000,000đ") 
  /// and USD (e.g., "$1,234.56") formats
  static num? parse(String value) {
    try {
      // Remove currency symbols and spaces
      String cleaned = value
          .replaceAll('₫', '')
          .replaceAll('\$', '')
          .replaceAll(' ', '')
          .trim();
      
      // Detect format: if it has commas as thousand separators and dots as decimal
      // (USD style: 1,234.56) vs VND style (1.234.567 or 1,234,567)
      final hasDecimalDot = cleaned.contains('.') && 
          cleaned.indexOf('.') > cleaned.length - 4 &&
          !cleaned.substring(cleaned.indexOf('.')).contains(',');
      
      if (hasDecimalDot) {
        // USD format: remove thousand separators (commas), keep decimal dot
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // VND format: remove all separators (dots and commas)
        cleaned = cleaned.replaceAll(',', '').replaceAll('.', '');
      }
      
      return num.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
