/// API endpoints and constants
class ApiConstants {
  // Base URL - Change this to your actual API
  // NOTE: Do NOT include trailing slash!
  // For Android Emulator: Use 10.0.2.2 (special IP to reach host machine)
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator

  // Other options:
  // static const String baseUrl = 'http://localhost:3000/api'; // Only for Windows/Web
  // static const String baseUrl = 'http://192.168.1.100:3000/api'; // Real device on same network
  // static const String baseUrl = 'https://your-api.com/api'; // Production

  // Authentication endpoints
  static const String signUpEndpoint = '/auth/signup';
  static const String loginEndpoint = '/auth/login';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String logoutEndpoint = '/auth/logout';

  // Timeout in seconds
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
