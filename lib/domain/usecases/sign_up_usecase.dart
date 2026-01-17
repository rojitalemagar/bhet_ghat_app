import '../../core/utils/validation_utils.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user sign up
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  /// Execute sign up operation
  /// Validates input and creates new user account
  Future<User> call({
    required String name,
    required String email,
    required String password,
  }) async {
    // Basic validation
    final nameError = ValidationUtils.getNameError(name);
    if (nameError != null) {
      throw Exception(nameError);
    }

    final emailError = ValidationUtils.getEmailError(email);
    if (emailError != null) {
      throw Exception(emailError);
    }

    final passwordError = ValidationUtils.getPasswordError(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // Check if email is already registered
    final isRegistered = await repository.isEmailRegistered(email);
    if (isRegistered) {
      throw Exception('Email already registered');
    }

    // Sign up user
    return await repository.signUp(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}