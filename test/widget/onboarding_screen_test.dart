import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhet_ghat_app/presentation/screens/onboarding_screen.dart';

import '../test_helpers.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      routes: {'/login': (_) => const TestPage('Login Page')},
      home: const OnboardingScreen(),
    );
  }

  group('OnboardingScreen widget tests', () {
    testWidgets('shows the first onboarding page by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      expect(find.text('Namaste, Welcome to BhetGhat!'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('next button advances to second page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Meet & Chat'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('back button returns to previous page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Namaste, Welcome to BhetGhat!'), findsOneWidget);
    });

    testWidgets('get started navigates to login on last page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildScreen());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
