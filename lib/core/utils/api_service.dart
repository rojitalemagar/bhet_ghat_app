import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Service for API communication including image uploads and auth utilities.
class ApiService {
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static List<String> get _candidateBaseUrls {
    if (_definedBaseUrl.trim().isNotEmpty) {
      return <String>[_definedBaseUrl.trim()];
    }

    if (Platform.isAndroid) {
      return <String>[
        'http://10.0.2.2:3000/api',
        'http://127.0.0.1:3000/api',
        'http://localhost:3000/api',
      ];
    }

    return <String>['http://localhost:3000/api', 'http://127.0.0.1:3000/api'];
  }

  static String get _baseUrl {
    return _candidateBaseUrls.first;
  }

  Future<String> uploadImage(File imageFile, {String? userEmail}) async {
    final fileExt = imageFile.path.split('.').last.toLowerCase();
    String? lastError;

    for (final baseUrl in _candidateBaseUrls) {
      try {
        var uploadUri = Uri.parse('$baseUrl${ApiConstants.uploadImageEndpoint}');
        if (userEmail != null && userEmail.trim().isNotEmpty) {
          uploadUri = uploadUri.replace(
            queryParameters: {'email': userEmail.trim()},
          );
        }

        final request = http.MultipartRequest('POST', uploadUri);
        request.files.add(
          http.MultipartFile(
            'image',
            imageFile.readAsBytes().asStream(),
            imageFile.lengthSync(),
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.$fileExt',
          ),
        );

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw SocketException(
            'Image upload timeout - server not responding',
          ),
        );

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data['imageUrl'] ?? data['data']?['imageUrl'];
          if (data['success'] == true && imageUrl != null) {
            return imageUrl;
          }
          throw Exception(data['message'] ?? 'Failed to upload image');
        }

        if (response.statusCode == 400) {
          throw Exception('Invalid file type or size');
        }

        if (response.statusCode == 413) {
          throw Exception('File size too large (max 5MB)');
        }

        if (response.statusCode == 500) {
          try {
            final errorData = jsonDecode(response.body);
            throw Exception(
              'Server error: ${errorData['message'] ?? 'Unknown error'}',
            );
          } catch (_) {
            throw Exception('Server error: ${response.body}');
          }
        }

        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      } on SocketException catch (e) {
        lastError = 'Socket on $baseUrl: ${e.message}';
      } catch (e) {
        // If server responds with a non-network error, return immediately.
        final message = e.toString().replaceFirst('Exception: ', '');
        if (!message.toLowerCase().contains('socket') &&
            !message.toLowerCase().contains('timeout')) {
          throw Exception('Upload error: $message');
        }
        lastError = '$message (baseUrl: $baseUrl)';
      }
    }

    throw SocketException(
      'Network error while uploading image. Tried: ${_candidateBaseUrls.join(', ')}. Last error: ${lastError ?? 'unknown'}. '
      'If you are on a real phone, run with --dart-define=API_BASE_URL=http://<YOUR-PC-IP>:3000/api',
    );
  }

  Future<String?> getImageUrl(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/user/$userId/image'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get image URL: $e');
    }
  }

  Future<File> downloadImage(String imageUrl, String fileName) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }

      throw Exception('Failed to download image: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConstants.forgotPasswordEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return;
      }

      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to request password reset');
    } on FormatException {
      throw Exception('Invalid server response');
    } catch (e) {
      throw Exception('Password reset request failed: $e');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConstants.resetPasswordEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'token': token.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return;
      }

      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to reset password');
    } on FormatException {
      throw Exception('Invalid server response');
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String email) async {
    try {
      final normalizedEmail = Uri.encodeComponent(email.trim().toLowerCase());
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl${ApiConstants.authUserEndpoint}/$normalizedEmail',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Invalid profile data');
      }

      throw Exception(body['message'] ?? 'Failed to fetch profile');
    } on FormatException {
      throw Exception('Invalid server response');
    } catch (e) {
      throw Exception('Profile fetch failed: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String email,
    required String name,
    required String bio,
    required String gender,
    required List<String> interests,
    required List<String> profileImageUrls,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl${ApiConstants.userProfileEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'name': name.trim(),
              'bio': bio.trim(),
              'gender': gender.trim().toLowerCase(),
              'interests': interests,
              'profileImages': profileImageUrls,
              'profileImage': profileImageUrls.isNotEmpty
                  ? profileImageUrls.first
                  : null,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Invalid profile data');
      }

      throw Exception(body['message'] ?? 'Failed to update profile');
    } on FormatException {
      throw Exception('Invalid server response');
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
}
