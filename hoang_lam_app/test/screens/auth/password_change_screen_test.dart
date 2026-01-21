import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoang_lam_app/screens/auth/password_change_screen.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('PasswordChangeScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const PasswordChangeScreen(),
        ),
      );
    }

    testWidgets('displays password change form elements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check page title in AppBar
      expect(find.text('Đổi mật khẩu'), findsWidgets);

      // Check form field labels
      expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
    });

    testWidgets('displays password requirement info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check info message about password requirements
      expect(find.textContaining('ít nhất'), findsOneWidget);
    });

    testWidgets('has three password visibility toggle buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all visibility toggle buttons (3 password fields)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButtons, findsNWidgets(3));
    });

    testWidgets('toggles password visibility when icon tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all fields show visibility_outlined icon
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap first visibility toggle (old password)
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButtons.first);
      await tester.pumpAndSettle();

      // Now one field shows visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    });

    testWidgets('has submit and cancel buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find submit button
      expect(find.text('Đổi mật khẩu'), findsWidgets);

      // Find cancel button
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays info icon with password hint', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find info icon
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
