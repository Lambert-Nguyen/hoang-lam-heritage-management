import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoang_lam_app/screens/auth/login_screen.dart';
import 'package:hoang_lam_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('LoginScreen', () {
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
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('vi'),
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('displays hotel name and login form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check hotel name is displayed
      expect(find.text('Hoàng Lâm Heritage Suites'), findsOneWidget);

      // Check login form elements
      expect(find.text('Tên đăng nhập'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('shows validation error for empty username', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap login button without entering anything
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      // Check validation error is shown
      expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter username but no password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập').first,
        'testuser',
      );
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      // Check validation error is shown
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('shows validation error for short password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter username and short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập').first,
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu').first,
        '123',
      );
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      // Check validation error is shown
      expect(find.textContaining('ít nhất'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially password is obscured
      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mật khẩu').first,
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Now password should be visible
      final passwordFieldAfter = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Mật khẩu').first,
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldAfter.obscureText, isFalse);
    });

    testWidgets('shows forgot password snackbar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap forgot password
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      // Check snackbar is shown
      expect(find.text('Vui lòng liên hệ quản trị viên để đặt lại mật khẩu'),
          findsOneWidget);
    });

    testWidgets('displays version info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check version info is displayed
      expect(find.textContaining('Phiên bản'), findsOneWidget);
    });
  });
}
