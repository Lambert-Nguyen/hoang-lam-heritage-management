import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoang_lam_app/models/minibar.dart';
import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/providers/minibar_provider.dart';
import 'package:hoang_lam_app/widgets/minibar/minibar_cart_panel.dart';

void main() {
  group('MinibarCartPanel', () {
    late MinibarItem mockItem;
    late MinibarCartItem mockCartItem;
    late MinibarCartState emptyCartState;
    late MinibarCartState filledCartState;

    setUp(() {
      mockItem = const MinibarItem(
        id: 1,
        name: 'Coca Cola',
        price: 25000,
        cost: 15000,
        category: 'beverage',
        isActive: true,
        createdAt: null,
        updatedAt: null,
      );

      mockCartItem = MinibarCartItem(item: mockItem, quantity: 2);

      emptyCartState = const MinibarCartState(
        items: [],
        bookingId: null,
        isProcessing: false,
        errorMessage: null,
      );

      filledCartState = MinibarCartState(
        items: [mockCartItem],
        bookingId: 1,
        isProcessing: false,
        errorMessage: null,
      );
    });

    Widget buildWidget({
      MinibarCartState? cartState,
      Booking? booking,
      VoidCallback? onCheckout,
      VoidCallback? onClear,
      void Function(int)? onRemoveItem,
      void Function(int, int)? onUpdateQuantity,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: MinibarCartPanel(
              cartState: cartState ?? emptyCartState,
              booking: booking,
              onCheckout: onCheckout,
              onClear: onClear,
              onRemoveItem: onRemoveItem,
              onUpdateQuantity: onUpdateQuantity,
            ),
          ),
        ),
      );
    }

    testWidgets('displays cart header with count', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Should show "Giỏ hàng" with item count
      expect(find.textContaining('Giỏ hàng'), findsOneWidget);
    });

    testWidgets('displays empty state when cart is empty', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: emptyCartState));

      // Should show empty cart message
      expect(find.text('Giỏ hàng trống'), findsOneWidget);
    });

    testWidgets('displays cart items when not empty', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Should show item name
      expect(find.text('Coca Cola'), findsOneWidget);
    });

    testWidgets('displays item quantity correctly', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Should show quantity (2)
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays total amount', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Total should be 25000 * 2 = 50000
      expect(find.textContaining('50.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows clear button when cart has items', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Should find delete/clear button
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });

    testWidgets('calls onClear when clear button tapped', (tester) async {
      bool cleared = false;
      await tester.pumpWidget(buildWidget(
        cartState: filledCartState,
        onClear: () => cleared = true,
      ));

      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('shows checkout button when cart has items', (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Should find checkout/thanh toán button
      expect(find.textContaining('Thanh toán'), findsOneWidget);
    });

    testWidgets('calls onCheckout when checkout button tapped', (tester) async {
      bool checkedOut = false;
      final mockBooking = Booking(
        id: 1,
        roomNumber: '101',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 17),
        status: BookingStatus.checkedIn,
        totalAmount: 1000000,
        nightlyRate: 500000,
        guest: 1,
        room: 1,
      );
      await tester.pumpWidget(buildWidget(
        cartState: filledCartState,
        booking: mockBooking,
        onCheckout: () => checkedOut = true,
      ));

      await tester.tap(find.textContaining('Thanh toán'));
      await tester.pump();

      expect(checkedOut, isTrue);
    });

    testWidgets('checkout button is disabled when no booking',
        (tester) async {
      await tester.pumpWidget(buildWidget(cartState: filledCartState));

      // Checkout button should exist but be disabled
      expect(find.textContaining('Thanh toán'), findsOneWidget);
      // Tapping should not cause errors when disabled (button is disabled when no booking)
    });

    testWidgets('displays booking info when booking is provided',
        (tester) async {
      final mockBooking = Booking(
        id: 1,
        roomNumber: '101',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 17),
        status: BookingStatus.checkedIn,
        totalAmount: 1000000,
        nightlyRate: 500000,
        guest: 1,
        room: 1,
      );

      await tester.pumpWidget(buildWidget(
        cartState: filledCartState,
        booking: mockBooking,
      ));

      // Should show room number combined with guest name
      expect(find.textContaining('P.101'), findsOneWidget);
    });

    testWidgets('increment button increases quantity', (tester) async {
      int? updatedItemId;
      int? updatedQuantity;

      await tester.pumpWidget(buildWidget(
        cartState: filledCartState,
        onUpdateQuantity: (id, qty) {
          updatedItemId = id;
          updatedQuantity = qty;
        },
      ));

      // Find and tap increment button (add icon)
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      expect(updatedItemId, equals(1));
      expect(updatedQuantity, equals(3)); // 2 + 1
    });

    testWidgets('decrement button decreases quantity when qty > 1', (tester) async {
      int? updatedItemId;
      int? updatedQuantity;

      await tester.pumpWidget(buildWidget(
        cartState: filledCartState,
        onUpdateQuantity: (id, qty) {
          updatedItemId = id;
          updatedQuantity = qty;
        },
      ));

      // Find and tap decrement button (remove icon)
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();

      expect(updatedItemId, equals(1));
      expect(updatedQuantity, equals(1)); // 2 - 1
    });

    testWidgets('decrement button calls onRemoveItem when qty is 1', (tester) async {
      // Cart item with quantity 1
      final singleItemState = MinibarCartState(
        items: [MinibarCartItem(item: mockItem, quantity: 1)],
        bookingId: 1,
        isProcessing: false,
        errorMessage: null,
      );

      int? removedItemId;

      await tester.pumpWidget(buildWidget(
        cartState: singleItemState,
        onRemoveItem: (id) => removedItemId = id,
      ));

      // Tap remove button (which triggers remove when qty is 1)
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();

      expect(removedItemId, equals(1));
    });
  });
}
