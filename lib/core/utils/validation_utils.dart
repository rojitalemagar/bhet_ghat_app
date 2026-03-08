import '../constants/app_constants.dart';

/// Validation utilities for user input
class ValidationUtils {
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(normalizeEmail(email));
  }

  /// Validate password strength (minimum 6 characters)
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  /// Validate name (not empty and trimmed)
  static bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }

  /// Get email validation error message
  static String? getEmailError(String email) {
    if (email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    if (!isValidEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Get password validation error message
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (!isValidPassword(password)) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }
    return null;
  }

  /// Get name validation error message
  static String? getNameError(String name) {
    if (name.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  static String? getBioError(String bio) {
    final trimmedBio = bio.trim();
    if (trimmedBio.isEmpty) {
      return 'Bio cannot be empty';
    }
    if (trimmedBio.length < 10) {
      return 'Bio should be at least 10 characters';
    }
    return null;
  }
}
