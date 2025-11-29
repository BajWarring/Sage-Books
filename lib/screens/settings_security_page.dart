import 'package:flutter/material.dart';
import 'package:sage/services/local_auth_service.dart';

class SettingsSecurityPage extends StatefulWidget {
  const SettingsSecurityPage({super.key});

  @override
  State<SettingsSecurityPage> createState() => _SettingsSecurityPageState();
}

class _SettingsSecurityPageState extends State<SettingsSecurityPage> {
  final LocalAuthService _authService = LocalAuthService();
  bool _isAuthEnabled = false;
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasBiometrics = await _authService.hasBiometrics();
    setState(() {
      _hasBiometrics = hasBiometrics;
      _isAuthEnabled = _authService.isAuthEnabled();
    });
  }

  Future<void> _toggleAuth(bool value) async {
    // Try to authenticate before *enabling*
    if (value == true) {
      bool authenticated = await _authService.authenticate();
      if (!mounted) return;
      if (!authenticated) {
        // User failed auth, don't enable the toggle
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication failed. Could not enable.')),
        );
        return;
      }
    }

    await _authService.setAuthEnabled(value);
    setState(() {
      _isAuthEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: _hasBiometrics
                ? const Text('Use fingerprint, face, or screen lock to unlock app')
                : const Text('No authentication methods available on this device'),
            value: _isAuthEnabled,
            // Only allow toggling if biometrics are available
            onChanged: _hasBiometrics ? _toggleAuth : null,
          ),
        ],
      ),
    );
  }
}
