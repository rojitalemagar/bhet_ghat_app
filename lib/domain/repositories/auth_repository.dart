import '../../domain/entities/user.dart';

/// Abstract repository for user authentication operations
abstract class AuthRepository {
  /// Sign up a new user
  /// Returns the created user or throws an exception
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Login with email and password
  /// Returns the user if credentials are valid, throws exception otherwise
  Future<User> login({
    required String email,
    required String password,
  });

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);

  /// Get user by email
  Future<User?> getUserByEmail(String email);
}