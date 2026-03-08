import 'package:flutter_test/flutter_test.dart';
import 'package:bhet_ghat_app/domain/entities/user.dart';
import 'package:bhet_ghat_app/domain/usecases/login_usecase.dart';
import 'package:bhet_ghat_app/domain/usecases/sign_up_usecase.dart';
import 'package:bhet_ghat_app/presentation/controllers/auth_controller.dart';
import 'package:bhet_ghat_app/presentation/controllers/dating_controller.dart';
import 'package:bhet_ghat_app/presentation/controllers/theme_controller.dart';

import '../test_helpers.dart';

void main() {
  group('ThemeController', () {
    test('toggleTheme switches dark mode on', () {
      final controller = ThemeController();

      controller.toggleTheme();

      expect(controller.isDarkMode, true);
    });

    test('setTheme assigns provided value', () {
      final controller = ThemeController();

      controller.setTheme(true);
      expect(controller.isDarkMode, true);

      controller.setTheme(false);
      expect(controller.isDarkMode, false);
    });
  });

  group('DatingController', () {
    test('starts with seeded profiles matches and threads', () {
      final controller = DatingController();

      expect(controller.profiles, isNotEmpty);
      expect(controller.matches, isNotEmpty);
      expect(controller.threads, isNotEmpty);
      expect(controller.selectedThreadId, isNotNull);
    });

    test('swipeCurrentProfile with like increments liked count', () {
      final controller = DatingController();
      final initialProfiles = controller.profiles.length;
      final initialMatches = controller.matches.length;

      controller.swipeCurrentProfile(true);

      expect(controller.likedCount, 1);
      expect(controller.profiles.length, initialProfiles - 1);
      expect(controller.matches.length, initialMatches + 1);
    });

    test('swipeCurrentProfile with pass increments skipped count', () {
      final controller = DatingController();
      final initialProfiles = controller.profiles.length;

      controller.swipeCurrentProfile(false);

      expect(controller.skippedCount, 1);
      expect(controller.profiles.length, initialProfiles - 1);
    });

    test('superLikeCurrentProfile increments super liked count', () {
      final controller = DatingController();
      final initialProfiles = controller.profiles.length;

      final profile = controller.superLikeCurrentProfile();

      expect(profile, isNotNull);
      expect(controller.likedCount, 1);
      expect(controller.superLikedCount, 1);
      expect(controller.profiles.length, initialProfiles - 1);
    });

    test('selectThread marks unread messages as read', () {
      final controller = DatingController();
      final unreadThread = controller.threads.firstWhere(
        (thread) => thread.unreadCount > 0,
      );

      controller.selectThread(unreadThread.id);

      expect(controller.selectedThreadId, unreadThread.id);
      expect(controller.selectedThread?.unreadCount, 0);
    });

    test('clearSelectedThread removes active selection', () {
      final controller = DatingController();

      controller.clearSelectedThread();

      expect(controller.selectedThreadId, isNull);
      expect(controller.selectedMessages, isEmpty);
    });
  });

  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      final repository = FakeAuthRepository();
      controller = AuthController(
        signUpUseCase: SignUpUseCase(repository),
        loginUseCase: LoginUseCase(repository),
      );
      controller.setCurrentUser(
        User(
          id: '1',
          name: 'Tester',
          email: 'tester@example.com',
          password: 'password123',
        ),
      );
    });

    test('updateUserGender updates current user gender', () {
      controller.updateUserGender('female');

      expect(controller.currentUser?.gender, 'female');
    });

    test('updateUserProfileImage stores latest profile image first', () {
      controller.updateUserProfileImage('https://example.com/one.jpg');
      controller.updateUserProfileImage('https://example.com/two.jpg');

      expect(controller.profileImageUrls, [
        'https://example.com/two.jpg',
        'https://example.com/one.jpg',
      ]);
      expect(
        controller.currentUser?.profileImageUrl,
        'https://example.com/two.jpg',
      );
    });

    test('updateProfileSetup stores bio interests and image urls', () {
      controller.updateProfileSetup(
        bio: 'Loves travel and music',
        interests: const ['Travel', 'Music'],
        profileImageUrls: const ['https://example.com/profile.jpg'],
      );

      expect(controller.bio, 'Loves travel and music');
      expect(controller.interests, ['Travel', 'Music']);
      expect(controller.profileImageUrls, ['https://example.com/profile.jpg']);
      expect(
        controller.currentUser?.profileImageUrl,
        'https://example.com/profile.jpg',
      );
    });

    test('logout clears all controller state', () {
      controller.updateProfileSetup(
        bio: 'Bio',
        interests: const ['Travel'],
        profileImageUrls: const ['https://example.com/profile.jpg'],
      );

      controller.logout();

      expect(controller.currentUser, isNull);
      expect(controller.bio, isEmpty);
      expect(controller.interests, isEmpty);
      expect(controller.profileImageUrls, isEmpty);
      expect(controller.isLoading, false);
    });
  });
}
