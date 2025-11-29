import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage/providers/theme_provider.dart';
import 'package:sage/screens/data_management_page.dart';
import 'package:sage/screens/settings_currency_page.dart';
import 'package:sage/screens/settings_security_page.dart';
import 'package:sage/main.dart'; // Import for color palette
import 'package:sage/utils/transitions.dart';

// --- NEW: Colors from HTML mockup ---
const Color _textDark = Color(0xFF212121);
const Color _textLight = Color(0xFF757575);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
// --- End New Colors ---

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightGrey,
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 15),
          _buildSettingsCard(
            context,
            title: 'Account Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account Settings page coming soon!')),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Notifications',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications page coming soon!')),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Privacy Policy',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy page coming soon!')),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'About App',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About App page coming soon!')),
              );
            },
          ),
          // --- Re-adding your original settings items ---
          const SizedBox(height: 20),
           const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 15),
          _buildSettingsCard(
            context,
            title: 'Security (App Lock)',
            onTap: () {
              Navigator.of(context).push(SlideRightRoute(
                page: const SettingsSecurityPage(),
              ));
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Theme',
            onTap: () {
              _showThemeDialog(context);
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Currency',
            onTap: () {
              Navigator.of(context).push(SlideRightRoute(
                page: const SettingsCurrencyPage(),
              ));
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Data Management',
            onTap: () {
              Navigator.push(
                context,
                SlideRightRoute(page: const DataManagementPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- NEW: Reusable Settings Card ---
  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: _bgWhite,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: _textLight,
          size: 16,
        ),
      ),
    );
  }

  // --- Your existing theme dialog logic is 100% preserved ---
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map((themeMode) {
                  return ListTile(
                    title: Text(themeMode.name[0].toUpperCase() +
                        themeMode.name.substring(1)),
                    onTap: () {
                      provider.setTheme(themeMode);
                      Navigator.of(context).pop();
                    },
                    trailing: provider.themeMode == themeMode
                        ? const Icon(Icons.check, color: foxOrange)
                        : null,
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}