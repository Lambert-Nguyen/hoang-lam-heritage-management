import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:hoang_lam_app/widgets/finance/currency_selector.dart';

void main() {
  Widget buildTestWidget({
    String selectedCurrency = 'VND',
    ValueChanged<String>? onChanged,
    List<CurrencyOption>? currencies,
    String? labelText,
    bool enabled = true,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: Center(
          child: CurrencySelector(
            selectedCurrency: selectedCurrency,
            onChanged: onChanged,
            currencies: currencies ?? supportedCurrencies,
            labelText: labelText,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('CurrencyOption', () {
    test('displayName returns code with name', () {
      const option = CurrencyOption(
        code: 'VND',
        name: 'Vietnamese Dong',
        symbol: '₫',
      );
      expect(option.displayName, 'VND - Vietnamese Dong');
    });

    test('equality based on code', () {
      const option1 = CurrencyOption(
        code: 'VND',
        name: 'Vietnamese Dong',
        symbol: '₫',
      );
      const option2 = CurrencyOption(
        code: 'VND',
        name: 'Different Name',
        symbol: 'd',
      );
      const option3 = CurrencyOption(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
      );

      expect(option1, equals(option2));
      expect(option1, isNot(equals(option3)));
    });

    test('hashCode based on code', () {
      const option1 = CurrencyOption(
        code: 'VND',
        name: 'Vietnamese Dong',
        symbol: '₫',
      );
      const option2 = CurrencyOption(
        code: 'VND',
        name: 'Different Name',
        symbol: 'd',
      );

      expect(option1.hashCode, equals(option2.hashCode));
    });
  });

  group('supportedCurrencies', () {
    test('contains VND as first currency', () {
      expect(supportedCurrencies.first.code, 'VND');
    });

    test('contains common currencies', () {
      final codes = supportedCurrencies.map((c) => c.code).toList();
      expect(codes, contains('VND'));
      expect(codes, contains('USD'));
      expect(codes, contains('EUR'));
      expect(codes, contains('CNY'));
    });

    test('has correct symbol for VND', () {
      final vnd = supportedCurrencies.firstWhere((c) => c.code == 'VND');
      expect(vnd.symbol, '₫');
    });

    test('has correct symbol for USD', () {
      final usd = supportedCurrencies.firstWhere((c) => c.code == 'USD');
      expect(usd.symbol, '\$');
    });
  });

  group('CurrencySelector', () {
    testWidgets('displays selected currency', (tester) async {
      await tester.pumpWidget(buildTestWidget(selectedCurrency: 'VND'));
      await tester.pumpAndSettle();

      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('displays default label', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Loại tiền'), findsOneWidget);
    });

    testWidgets('displays custom label when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(labelText: 'Select Currency'));
      await tester.pumpAndSettle();

      expect(find.text('Select Currency'), findsOneWidget);
    });

    testWidgets('calls onChanged when selecting a different currency', (
      tester,
    ) async {
      String? selectedValue;

      await tester.pumpWidget(
        buildTestWidget(
          selectedCurrency: 'VND',
          onChanged: (value) => selectedValue = value,
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select USD
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'USD');
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        buildTestWidget(
          selectedCurrency: 'VND',
          onChanged: (value) => selectedValue = value,
          enabled: false,
        ),
      );
      await tester.pumpAndSettle();

      // Try to tap dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // USD option should not appear
      expect(find.text('USD'), findsNothing);
      expect(selectedValue, isNull);
    });

    testWidgets('displays currency symbol in dropdown items', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check for symbol container
      expect(find.text('₫'), findsWidgets); // VND symbol
    });

    testWidgets('works with custom currency list', (tester) async {
      const customCurrencies = [
        CurrencyOption(code: 'AAA', name: 'Test A', symbol: 'A'),
        CurrencyOption(code: 'BBB', name: 'Test B', symbol: 'B'),
      ];

      await tester.pumpWidget(
        buildTestWidget(selectedCurrency: 'AAA', currencies: customCurrencies),
      );
      await tester.pumpAndSettle();

      expect(find.text('AAA'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('BBB'), findsOneWidget);
    });
  });

  group('CompactCurrencySelector', () {
    Widget buildCompactTestWidget({
      String selectedCurrency = 'VND',
      ValueChanged<String>? onChanged,
      bool enabled = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400, // Provide enough width to avoid overflow
              child: CompactCurrencySelector(
                selectedCurrency: selectedCurrency,
                onChanged: onChanged,
                enabled: enabled,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays selected currency code', (tester) async {
      await tester.pumpWidget(buildCompactTestWidget(selectedCurrency: 'VND'));
      await tester.pumpAndSettle();

      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('displays different currency when selected', (tester) async {
      await tester.pumpWidget(buildCompactTestWidget(selectedCurrency: 'USD'));
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('renders PopupMenuButton widget', (tester) async {
      await tester.pumpWidget(
        buildCompactTestWidget(selectedCurrency: 'VND', onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('displays dropdown arrow', (tester) async {
      await tester.pumpWidget(
        buildCompactTestWidget(
          selectedCurrency: 'VND',
          onChanged: (_) {},
          enabled: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });
  });

  group('ExchangeRateDisplay', () {
    Widget buildExchangeRateTestWidget({
      required String fromCurrency,
      required String toCurrency,
      required double rate,
      DateTime? date,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExchangeRateDisplay(
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              rate: rate,
              date: date,
            ),
          ),
        ),
      );
    }

    testWidgets('displays exchange rate', (tester) async {
      await tester.pumpWidget(
        buildExchangeRateTestWidget(
          fromCurrency: 'USD',
          toCurrency: 'VND',
          rate: 24500,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 USD'), findsOneWidget);
      expect(find.textContaining('VND'), findsWidgets);
    });

    testWidgets('displays formatted rate', (tester) async {
      await tester.pumpWidget(
        buildExchangeRateTestWidget(
          fromCurrency: 'EUR',
          toCurrency: 'VND',
          rate: 26000,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('26,000'), findsOneWidget);
    });

    testWidgets('displays currency exchange icon', (tester) async {
      await tester.pumpWidget(
        buildExchangeRateTestWidget(
          fromCurrency: 'USD',
          toCurrency: 'VND',
          rate: 24500,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.currency_exchange), findsOneWidget);
    });
  });

  group('ConvertedAmountDisplay', () {
    Widget buildConvertedAmountTestWidget({
      required double originalAmount,
      required String fromCurrency,
      required double convertedAmount,
      required String toCurrency,
      double? rate,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: Center(
            child: ConvertedAmountDisplay(
              originalAmount: originalAmount,
              fromCurrency: fromCurrency,
              convertedAmount: convertedAmount,
              toCurrency: toCurrency,
              rate: rate,
            ),
          ),
        ),
      );
    }

    testWidgets('displays converted amount', (tester) async {
      await tester.pumpWidget(
        buildConvertedAmountTestWidget(
          originalAmount: 100,
          fromCurrency: 'USD',
          convertedAmount: 2450000,
          toCurrency: 'VND',
        ),
      );
      await tester.pumpAndSettle();

      // Should show 2,450,000
      expect(find.textContaining('2,450,000'), findsOneWidget);
    });

    testWidgets('displays original amount', (tester) async {
      await tester.pumpWidget(
        buildConvertedAmountTestWidget(
          originalAmount: 100,
          fromCurrency: 'USD',
          convertedAmount: 2450000,
          toCurrency: 'VND',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('displays currency labels', (tester) async {
      await tester.pumpWidget(
        buildConvertedAmountTestWidget(
          originalAmount: 50,
          fromCurrency: 'EUR',
          convertedAmount: 1300000,
          toCurrency: 'VND',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('VND'), findsOneWidget);
    });

    testWidgets('displays rate when provided', (tester) async {
      await tester.pumpWidget(
        buildConvertedAmountTestWidget(
          originalAmount: 100,
          fromCurrency: 'USD',
          convertedAmount: 2450000,
          toCurrency: 'VND',
          rate: 24500,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tỷ giá:'), findsOneWidget);
    });
  });
}
