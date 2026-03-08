import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhet_ghat_app/domain/entities/user.dart';
import 'package:bhet_ghat_app/domain/repositories/auth_repository.dart';
import 'package:bhet_ghat_app/domain/usecases/login_usecase.dart';
import 'package:bhet_ghat_app/domain/usecases/sign_up_usecase.dart';
import 'package:bhet_ghat_app/presentation/controllers/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginHandler,
    this.signUpHandler,
    this.isEmailRegisteredHandler,
    this.getUserByEmailHandler,
  });

  Future<User> Function({required String email, required String password})?
  loginHandler;
  Future<User> Function({
    required String name,
    required String email,
    required String password,
  })?
  signUpHandler;
  Future<bool> Function(String email)? isEmailRegisteredHandler;
  Future<User?> Function(String email)? getUserByEmailHandler;

  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastSignUpName;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastCheckedEmail;

  @override
  Future<User?> getUserByEmail(String email) async {
    return getUserByEmailHandler?.call(email);
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    lastCheckedEmail = email;
    return isEmailRegisteredHandler?.call(email) ?? false;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (loginHandler != null) {
      return loginHandler!(email: email, password: password);
    }
    throw UnimplementedError('loginHandler not configured');
  }

  @override
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    lastSignUpName = name;
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    if (signUpHandler != null) {
      return signUpHandler!(name: name, email: email, password: password);
    }
    throw UnimplementedError('signUpHandler not configured');
  }
}

class TestAuthController extends AuthController {
  TestAuthController()
    : super(
        signUpUseCase: SignUpUseCase(FakeAuthRepository()),
        loginUseCase: LoginUseCase(FakeAuthRepository()),
      );

  User? loginResponse;
  User? signUpResponse;
  bool forgotPasswordResponse = true;
  bool resetPasswordResponse = true;
  String? stubErrorMessage;
  String? capturedLoginEmail;
  String? capturedLoginPassword;
  String? capturedForgotPasswordEmail;
  String? capturedResetToken;
  String? capturedResetPassword;

  @override
  String? get errorMessage => stubErrorMessage ?? super.errorMessage;

  @override
  Future<User?> login({required String email, required String password}) async {
    capturedLoginEmail = email;
    capturedLoginPassword = password;
    return loginResponse;
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    capturedResetToken = token;
    capturedResetPassword = newPassword;
    return resetPasswordResponse;
  }

  @override
  Future<bool> sendPasswordResetLink(String email) async {
    capturedForgotPasswordEmail = email;
    return forgotPasswordResponse;
  }

  @override
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return signUpResponse;
  }
}

class TestPage extends StatelessWidget {
  const TestPage(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

void mockFlutterAssets() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const transparentImageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn0l1QAAAAASUVORK5CYII=';
  final bytes = base64Decode(transparentImageBase64);
  final imageData = ByteData.view(Uint8List.fromList(bytes).buffer);
  final emptyManifestBytes = const StandardMessageCodec().encodeMessage(
    <String, Object>{},
  )!;
  final emptyManifestData = ByteData.view(emptyManifestBytes.buffer);
  final emptyJsonData = ByteData.view(
    Uint8List.fromList(utf8.encode('[]')).buffer,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());

        if (key == 'AssetManifest.bin') {
          return emptyManifestData;
        }
        if (key == 'AssetManifest.json' || key == 'FontManifest.json') {
          return emptyJsonData;
        }

        return imageData;
      });
}
