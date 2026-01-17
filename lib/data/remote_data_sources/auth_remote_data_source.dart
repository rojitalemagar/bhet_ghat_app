import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Abstract remote data source for authentication
abstract class AuthRemoteDataSource {
  /// Sign up with remote API
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Login with remote API
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);
}

/// Implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client httpClient;

  AuthRemoteDataSourceImpl({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signUpEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: ApiConstants.connectionTimeout),
        onTimeout: () => throw SocketException('Connection timeout'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Handle different API response formats
        final userData = jsonData['data'] ?? jsonData['user'] ?? jsonData;
        
        return UserModel(
          id: userData['id'] ?? '',
          name: userData['name'] ?? name,
          email: userData['email'] ?? email,
          password: password,
        );
      } else if (response.statusCode == 400) {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Email already registered');
      } else {
        throw Exception('Sign up failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: ApiConstants.connectionTimeout),
        onTimeout: () => throw SocketException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Handle different API response formats
        final userData = jsonData['data'] ?? jsonData['user'] ?? jsonData;
        
        return UserModel(
          id: userData['id'] ?? '',
          name: userData['name'] ?? 'User',
          email: userData['email'] ?? email,
          password: password,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    // This requires an endpoint on your backend
    // For now, we'll return false - adjust based on your API
    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/check-email?email=$email'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: ApiConstants.connectionTimeout),
        onTimeout: () => throw SocketException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['exists'] ?? false;
      }
      return false;
    } catch (e) {
      // If the endpoint doesn't exist, fall back to local check
      return false;
    }
  }
}
