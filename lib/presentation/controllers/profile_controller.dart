import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/utils/api_service.dart';

/// Controller for profile-related operations
class ProfileController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _profileImageUrl;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get profileImageUrl => _profileImageUrl;

  /// Upload profile image to server
  Future<String> uploadProfileImage(File imageFile, {String? userEmail}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _apiService.uploadImage(
        imageFile,
        userEmail: userEmail,
      );
      _profileImageUrl = url;
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get profile image URL
  Future<String?> getProfileImageUrl(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _apiService.getImageUrl(userId);
      _profileImageUrl = url;
      _isLoading = false;
      notifyListeners();
      return url;
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
