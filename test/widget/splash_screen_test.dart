import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhet_ghat_app/presentation/screens/splash_screen.dart';

import '../test_helpers.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      routes: {'/onboarding': (_) => const TestPage('Onboarding Page')},
      home: const SplashScreen(),
    );
  }

  group('SplashScreen widget tests', () {
    testWidgets('renders branding and loading indicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      expect(find.text('BhetGhat'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to onboarding after delay', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Onboarding Page'), findsOneWidget);
    });
  });
}
