import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/service_locator.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/dating_controller.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _uriSub;
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks!.getInitialLink();
      _handleDeepLink(initialUri);
    } catch (_) {
      // no-op
    }

    _uriSub = _appLinks!.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {
        // no-op
      },
    );
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) {
      return;
    }

    final hasResetRoute =
        uri.host == 'reset-password' || uri.path.contains('reset-password');
    if (!hasResetRoute) {
      return;
    }

    final token = uri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      navigator.pushNamed(
        AppConstants.resetPasswordRoute,
        arguments: token.trim(),
      );
    });
  }

  @override
  void dispose() {
    _uriSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            signUpUseCase: ServiceLocator.signUpUseCase,
            loginUseCase: ServiceLocator.loginUseCase,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DatingController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'BhetGhat',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              AppConstants.onboardingRoute: (_) => const OnboardingScreen(),
              AppConstants.loginRoute: (_) => const LoginScreen(),
              AppConstants.registerRoute: (_) => const RegisterScreen(),
              AppConstants.dashboardRoute: (_) => const DashboardScreen(),
              AppConstants.homeRoute: (_) => const HomeScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppConstants.resetPasswordRoute) {
                final tokenArg = settings.arguments;
                final initialToken = tokenArg is String ? tokenArg : null;
                return MaterialPageRoute(
                  builder: (_) =>
                      ResetPasswordScreen(initialToken: initialToken),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/bhetghat_logo.png',
                  width: isMobile ? 100 : 150,
                  height: isMobile ? 100 : 150,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: isMobile ? 30 : 50),
                Text(
                  'Welcome to BhetGhat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 30),
                Text(
                  'You are successfully logged in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: isMobile ? 40 : 60),
                SizedBox(
                  width: double.infinity,
                  height: isMobile ? 48 : 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
