import 'package:flutter/material.dart';

/// Common currencies for the hotel
const List<CurrencyOption> supportedCurrencies = [
  CurrencyOption(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
  CurrencyOption(code: 'USD', name: 'US Dollar', symbol: '\$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  CurrencyOption(code: 'KRW', name: 'Korean Won', symbol: '₩'),
  CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyOption(code: 'THB', name: 'Thai Baht', symbol: '฿'),
  CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
];

/// Represents a currency option
class CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });

  String get displayName => '$code - $name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyOption && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// A dropdown selector for currencies
class CurrencySelector extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String>? onChanged;
  final List<CurrencyOption> currencies;
  final String? labelText;
  final bool enabled;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    this.onChanged,
    this.currencies = supportedCurrencies,
    this.labelText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<String>(
      value: selectedCurrency,
      decoration: InputDecoration(
        labelText: labelText ?? 'Loại tiền',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency.code,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(currency.code),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? (value) {
        if (value != null && onChanged != null) {
          onChanged!(value);
        }
      } : null,
    );
  }
}

/// A compact currency selector (icon only)
class CompactCurrencySelector extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String>? onChanged;
  final List<CurrencyOption> currencies;
  final bool enabled;

  const CompactCurrencySelector({
    super.key,
    required this.selectedCurrency,
    this.onChanged,
    this.currencies = supportedCurrencies,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = currencies.firstWhere(
      (c) => c.code == selectedCurrency,
      orElse: () => currencies.first,
    );

    return PopupMenuButton<String>(
      enabled: enabled,
      initialValue: selectedCurrency,
      onSelected: onChanged,
      itemBuilder: (context) => currencies.map((currency) {
        return PopupMenuItem<String>(
          value: currency.code,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: currency.code == selectedCurrency
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    color: currency.code == selectedCurrency
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(currency.displayName),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.code,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays an exchange rate
class ExchangeRateDisplay extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime? date;

  const ExchangeRateDisplay({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 $fromCurrency = ${_formatRate(rate)} $toCurrency',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (date != null)
                  Text(
                    'Cập nhật: ${_formatDate(date!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRate(double rate) {
    if (rate >= 1000) {
      return rate.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
    }
    return rate.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Displays a converted amount
class ConvertedAmountDisplay extends StatelessWidget {
  final double originalAmount;
  final String fromCurrency;
  final double convertedAmount;
  final String toCurrency;
  final double? rate;

  const ConvertedAmountDisplay({
    super.key,
    required this.originalAmount,
    required this.fromCurrency,
    required this.convertedAmount,
    required this.toCurrency,
    this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatAmount(originalAmount),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                fromCurrency,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(convertedAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                toCurrency,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (rate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tỷ giá: ${_formatRate(rate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatRate(double rate) {
    if (rate >= 1000) {
      return rate.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
    }
    return rate.toStringAsFixed(4);
  }
}
