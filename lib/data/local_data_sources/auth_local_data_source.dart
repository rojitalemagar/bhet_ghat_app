import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Local data source for authentication using Hive
abstract class AuthLocalDataSource {
  /// Initialize Hive boxes
  Future<void> init();

  /// Save user to local storage
  Future<void> saveUser(UserModel user);

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);

  /// Get all users (for debugging purposes)
  Future<List<UserModel>> getAllUsers();
}

/// Implementation of AuthLocalDataSource using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _usersBoxName = AppConstants.usersBoxName;
  late Box<UserModel> _usersBox;

  @override
  Future<void> init() async {
    _usersBox = await Hive.openBox<UserModel>(_usersBoxName);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _usersBox.put(user.email, user);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    return _usersBox.get(email);
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    return _usersBox.containsKey(email);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return _usersBox.values.toList();
  }
}