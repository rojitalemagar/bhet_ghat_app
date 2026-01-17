import 'package:uuid/uuid.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local_data_sources/auth_local_data_source.dart';
import '../remote_data_sources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository using both local and remote data sources
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final Uuid _uuid;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Try remote API first
      final userModel = await remoteDataSource.signUp(
        name: name,
        email: email,
        password: password,
      );

      // Save to local storage after successful remote signup
      await localDataSource.saveUser(userModel);
      return userModel.toEntity();
    } catch (e) {
      // Fallback to local storage if remote fails
      final isRegistered = await localDataSource.isEmailRegistered(email);
      if (isRegistered) {
        throw Exception('Email already registered');
      }

      // Create new user locally
      final userId = _uuid.v4();
      final userModel = UserModel(
        id: userId,
        name: name,
        email: email,
        password: password,
      );

      await localDataSource.saveUser(userModel);
      return userModel.toEntity();
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      // Try remote API first
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save/update to local storage after successful remote login
      await localDataSource.saveUser(userModel);
      return userModel.toEntity();
    } catch (e) {
      // Fallback to local storage if remote fails
      final userModel = await localDataSource.getUserByEmail(email);

      if (userModel == null) {
        throw Exception('User not found');
      }

      if (userModel.password != password) {
        throw Exception('Invalid password');
      }

      return userModel.toEntity();
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check remote first
      return await remoteDataSource.isEmailRegistered(email);
    } catch (e) {
      // Fall back to local check
      return await localDataSource.isEmailRegistered(email);
    }
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    final userModel = await localDataSource.getUserByEmail(email);
    return userModel?.toEntity();
  }
}