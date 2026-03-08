import 'package:flutter_test/flutter_test.dart';
import 'package:bhet_ghat_app/domain/entities/user.dart';
import 'package:bhet_ghat_app/domain/usecases/login_usecase.dart';
import 'package:bhet_ghat_app/domain/usecases/sign_up_usecase.dart';

import '../test_helpers.dart';

void main() {
  group('LoginUseCase', () {
    test('throws when email is empty', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      expect(
        () => useCase(email: '', password: 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when email format is invalid', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      expect(
        () => useCase(email: 'invalid-email', password: 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when password is empty', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      expect(
        () => useCase(email: 'user@example.com', password: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('normalizes email before calling repository', () async {
      final expectedUser = User(
        id: '1',
        name: 'User',
        email: 'user@example.com',
        password: 'password123',
      );
      final repository = FakeAuthRepository(
        loginHandler: ({required email, required password}) async =>
            expectedUser,
      );
      final useCase = LoginUseCase(repository);

      await useCase(email: 'User@Example.com', password: 'password123');

      expect(repository.lastLoginEmail, 'user@example.com');
      expect(repository.lastLoginPassword, 'password123');
    });

    test('returns user from repository on success', () async {
      final expectedUser = User(
        id: '2',
        name: 'Jane',
        email: 'jane@example.com',
        password: 'password123',
      );
      final repository = FakeAuthRepository(
        loginHandler: ({required email, required password}) async =>
            expectedUser,
      );
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'jane@example.com',
        password: 'password123',
      );

      expect(result, expectedUser);
    });
  });

  group('SignUpUseCase', () {
    test('throws when name is empty', () async {
      final repository = FakeAuthRepository();
      final useCase = SignUpUseCase(repository);

      expect(
        () => useCase(
          name: '   ',
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when email is invalid', () async {
      final repository = FakeAuthRepository();
      final useCase = SignUpUseCase(repository);

      expect(
        () => useCase(name: 'User', email: 'invalid', password: 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when password is too short', () async {
      final repository = FakeAuthRepository();
      final useCase = SignUpUseCase(repository);

      expect(
        () => useCase(name: 'User', email: 'user@example.com', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when email is already registered', () async {
      final repository = FakeAuthRepository(
        isEmailRegisteredHandler: (_) async => true,
      );
      final useCase = SignUpUseCase(repository);

      expect(
        () => useCase(
          name: 'User',
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(isA<Exception>()),
      );
      expect(repository.lastCheckedEmail, 'user@example.com');
    });

    test('trims and normalizes input before calling repository', () async {
      final expectedUser = User(
        id: '3',
        name: 'User Name',
        email: 'user@example.com',
        password: 'password123',
      );
      final repository = FakeAuthRepository(
        isEmailRegisteredHandler: (_) async => false,
        signUpHandler:
            ({required name, required email, required password}) async {
              return expectedUser;
            },
      );
      final useCase = SignUpUseCase(repository);

      final result = await useCase(
        name: ' User Name ',
        email: 'User@Example.com',
        password: 'password123',
      );

      expect(result, expectedUser);
      expect(repository.lastSignUpName, 'User Name');
      expect(repository.lastSignUpEmail, 'user@example.com');
      expect(repository.lastSignUpPassword, 'password123');
    });
  });
}
