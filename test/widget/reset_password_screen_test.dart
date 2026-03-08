import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bhet_ghat_app/core/constants/app_constants.dart';
import 'package:bhet_ghat_app/presentation/controllers/auth_controller.dart';
import 'package:bhet_ghat_app/presentation/screens/reset_password_screen.dart';

import '../test_helpers.dart';

void main() {
  late TestAuthController authController;

  setUp(() {
    authController = TestAuthController();
  });

  Widget buildScreen({String? initialToken}) {
    return MaterialApp(
      builder: (context, child) => ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: child!,
      ),
      routes: {AppConstants.loginRoute: (_) => const TestPage('Login Page')},
      home: ResetPasswordScreen(initialToken: initialToken),
    );
  }

  group('ResetPasswordScreen widget tests', () {
    testWidgets('renders reset password form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('prefills reset token when initial token is provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen(initialToken: 'prefilled-token'));

      expect(find.text('prefilled-token'), findsOneWidget);
    });

    testWidgets('shows validation error when token is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pump();

      expect(find.text('Reset token is required'), findsOneWidget);
    });

    testWidgets('shows validation error when password is too short', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen(initialToken: 'token-123'));

      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error when passwords do not match', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen(initialToken: 'token-123'));

      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('navigates back to login from back button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('submits valid form and navigates to login on success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen(initialToken: 'token-123'));

      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(authController.capturedResetToken, 'token-123');
      expect(authController.capturedResetPassword, 'password123');
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
