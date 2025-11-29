import 'package:flutter/material.dart';
import 'package:sage/screens/home_screen.dart';
import 'package:sage/services/local_auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final LocalAuthService _authService = LocalAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuthEnabled = _authService.isAuthEnabled();
    bool authenticated = !isAuthEnabled; // Skip if auth is not enabled

    if (isAuthEnabled) {
      final hasBiometrics = await _authService.hasBiometrics();
      if (hasBiometrics) {
        authenticated = await _authService.authenticate();
      }
    }

    // If authenticated (or auth is disabled), go to the app
    if (mounted && authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
    // You could add an 'else' here to close the app or show an error
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while checking
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
