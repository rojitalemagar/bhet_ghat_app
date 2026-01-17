import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/hive_adapters/user_model_adapter.dart';
import '../../data/local_data_sources/auth_local_data_source.dart';
import '../../data/remote_data_sources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static late AuthRepository _authRepository;
  static late SignUpUseCase _signUpUseCase;
  static late LoginUseCase _loginUseCase;
  static late AuthLocalDataSource _authLocalDataSource;
  static late AuthRemoteDataSource _authRemoteDataSource;

  /// Initialize all dependencies
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(UserModelAdapter());

    // Initialize local data source
    _authLocalDataSource = AuthLocalDataSourceImpl();
    await _authLocalDataSource.init();

    // Initialize remote data source
    _authRemoteDataSource = AuthRemoteDataSourceImpl();

    // Initialize repository with both local and remote data sources
    _authRepository = AuthRepositoryImpl(
      localDataSource: _authLocalDataSource,
      remoteDataSource: _authRemoteDataSource,
      uuid: const Uuid(),
    );

    // Initialize use cases
    _signUpUseCase = SignUpUseCase(_authRepository);
    _loginUseCase = LoginUseCase(_authRepository);
  }

  /// Get authentication repository
  static AuthRepository get authRepository => _authRepository;

  /// Get sign up use case
  static SignUpUseCase get signUpUseCase => _signUpUseCase;

  /// Get login use case
  static LoginUseCase get loginUseCase => _loginUseCase;

  /// Get local data source
  static AuthLocalDataSource get authLocalDataSource => _authLocalDataSource;

  /// Get remote data source
  static AuthRemoteDataSource get authRemoteDataSource => _authRemoteDataSource;
}