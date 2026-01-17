import 'package:flutter/material.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

/// Controller for authentication operations
class AuthController extends ChangeNotifier {
  final SignUpUseCase _signUpUseCase;
  final LoginUseCase _loginUseCase;

  AuthController({
    required SignUpUseCase signUpUseCase,
    required LoginUseCase loginUseCase,
  })  : _signUpUseCase = signUpUseCase,
        _loginUseCase = loginUseCase;

  bool _isLoading = false;
  String? _errorMessage;

  /// Whether an authentication operation is in progress
  bool get isLoading => _isLoading;

  /// Error message from the last operation
  String? get errorMessage => _errorMessage;

  /// Sign up a new user
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _signUpUseCase(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Login with email and password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginUseCase(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}