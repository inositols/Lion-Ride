import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logic/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_home.dart';
import 'screens/rider/rider_home.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'core/widgets/global_error_listener.dart';

class RootWrapper extends StatefulWidget {
  const RootWrapper({super.key});

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  bool _showSplash = true;
  bool _isFirstTime = true;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      _logger.d('Checking onboarding status...');
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;
      _logger.d('Is first time: $isFirstTime');
      setState(() {
        _isFirstTime = isFirstTime;
      });
    } catch (e) {
      _logger.e('Error checking onboarding status: $e');
      // If SharedPreferences fails, we might want to default to something safe
      setState(() {
        _isFirstTime =
            false; // Default to false to avoid getting stuck if prefs fail
      });
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      _logger.i('Finishing onboarding...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time', false);
      setState(() {
        _isFirstTime = false;
      });
      _logger.i('Onboarding finished and flag set to false.');
    } catch (e) {
      _logger.e('Error finishing onboarding: $e');
      setState(() {
        _isFirstTime = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onInitializationComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (_isFirstTime) {
      return OnboardingScreen(onFinish: _finishOnboarding);
    }

    return GlobalErrorListener(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          _logger.d('AuthBloc state in RootWrapper: $state');
          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AuthAuthenticated) {
            final user = state.user;
            _logger.i('User authenticated: ${user.name} (${user.role})');
            if (user.role == 'rider') {
              return const RiderHome();
            } else {
              return const StudentHome();
            }
          }

          _logger.w('User not authenticated, showing LoginScreen. State: $state');
          // Default to LoginScreen if Unauthenticated or Error
          return const LoginScreen();
        },
      ),
    );
  }
}
