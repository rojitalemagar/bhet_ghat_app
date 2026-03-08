import 'package:flutter/material.dart';

import '../../core/utils/api_service.dart';
import '../../core/utils/validation_utils.dart';
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
  }) : _signUpUseCase = signUpUseCase,
       _loginUseCase = loginUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  String _bio = '';
  List<String> _interests = [];
  List<String> _profileImageUrls = [];
  final ApiService _apiService = ApiService();

  /// Whether an authentication operation is in progress
  bool get isLoading => _isLoading;

  /// Error message from the last operation
  String? get errorMessage => _errorMessage;

  /// Current authenticated user
  User? get currentUser => _currentUser;
  String get bio => _bio;
  List<String> get interests => _interests;
  List<String> get profileImageUrls => _profileImageUrls;

  /// Sign up a new user
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = ValidationUtils.normalizeEmail(email);
    final trimmedName = name.trim();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _signUpUseCase(
        name: trimmedName,
        email: normalizedEmail,
        password: password,
      );
      _currentUser = user;
      await _syncProfileFromServer(normalizedEmail);
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
  Future<User?> login({required String email, required String password}) async {
    final normalizedEmail = ValidationUtils.normalizeEmail(email);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginUseCase(
        email: normalizedEmail,
        password: password,
      );
      _currentUser = user;
      await _syncProfileFromServer(normalizedEmail);
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

  /// Update current user with new profile image
  void updateUserProfileImage(String imageUrl) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(profileImageUrl: imageUrl);
      if (imageUrl.isNotEmpty) {
        _profileImageUrls = [
          imageUrl,
          ..._profileImageUrls.where((existing) => existing != imageUrl),
        ];
      }
      notifyListeners();
    }
  }

  /// Update current user's gender
  void updateUserGender(String gender) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(gender: gender);
      notifyListeners();
    }
  }

  void updateProfileSetup({
    required String bio,
    required List<String> interests,
    required List<String> profileImageUrls,
  }) {
    _bio = bio;
    _interests = interests.toSet().toList();
    _profileImageUrls = profileImageUrls.toSet().toList();
    if (_currentUser != null && _profileImageUrls.isNotEmpty) {
      _currentUser = _currentUser!.copyWith(
        profileImageUrl: _profileImageUrls.first,
      );
    }
    notifyListeners();
  }

  Future<bool> saveProfile({
    required String name,
    required String bio,
    required String gender,
    required List<String> interests,
    required List<String> profileImageUrls,
  }) async {
    final email = _currentUser?.email;
    if (email == null || email.isEmpty) {
      _errorMessage = 'No logged in user found';
      notifyListeners();
      return false;
    }

    final normalizedInterests = interests
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.updateUserProfile(
        email: email,
        name: name,
        bio: bio,
        gender: gender,
        interests: normalizedInterests,
        profileImageUrls: profileImageUrls,
      );
      _applyProfileData(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetLink(String email) async {
    final normalizedEmail = ValidationUtils.normalizeEmail(email);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.requestPasswordReset(normalizedEmail);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(token: token, newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Logout user
  void logout() {
    _currentUser = null;
    _bio = '';
    _interests = [];
    _profileImageUrls = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Test/helper setter for injecting current user state directly.
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _syncProfileFromServer(String email) async {
    try {
      final data = await _apiService.fetchUserProfile(email);
      _applyProfileData(data);
    } catch (_) {
      // Keep auth flow resilient when the profile endpoint is unavailable.
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    final imageUrl =
        (data['imageUrl'] ?? data['profileImageUrl'] ?? '') as String? ?? '';

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        id: (data['id'] as String?) ?? _currentUser!.id,
        name: (data['name'] as String?) ?? _currentUser!.name,
        email: (data['email'] as String?) ?? _currentUser!.email,
        profileImageUrl: imageUrl.isEmpty
            ? _currentUser!.profileImageUrl
            : imageUrl,
        gender: (data['gender'] as String?) ?? _currentUser!.gender,
      );
    }

    _bio = ((data['bio'] as String?) ?? '').trim();
    _interests = ((data['interests'] as List?) ?? const [])
        .whereType<dynamic>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final profileImages = ((data['profileImages'] as List?) ?? const [])
        .whereType<dynamic>()
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (imageUrl.isNotEmpty && !profileImages.contains(imageUrl)) {
      _profileImageUrls = [imageUrl, ...profileImages];
    } else {
      _profileImageUrls = profileImages;
    }
  }
}
