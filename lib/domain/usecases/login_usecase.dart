import '../../core/utils/validation_utils.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Execute login operation
  /// Validates credentials and returns user if successful
  Future<User> call({
    required String email,
    required String password,
  }) async {
    // Basic validation
    final emailError = ValidationUtils.getEmailError(email);
    if (emailError != null) {
      throw Exception(emailError);
    }

    if (password.isEmpty) {
      throw Exception('Password cannot be empty');
    }

    // Attempt login
    return await repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}