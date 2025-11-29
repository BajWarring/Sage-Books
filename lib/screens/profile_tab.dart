import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sage/services/auth_service.dart';

// Using your specific Fox Orange theme colors
const Color _primaryOrange = Color(0xFFF15A24);
const Color _textDark = Color(0xFF2C2C2C);
const Color _textMedium = Color(0xFF6E6E6E);
const Color _bgLightGrey = Color(0xFFFFF3EC);
const Color _bgWhite = Color(0xFFFFFFFF);

class ProfileTab extends StatefulWidget {
  final VoidCallback onBackTapped;

  const ProfileTab({super.key, required this.onBackTapped});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLightGrey,
      appBar: _buildAppBar(context),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // LOGGED IN UI
            return _buildLoggedInView(snapshot.data!);
          } else {
            // GUEST UI
            return _buildLoggedOutView();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _primaryOrange,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBackTapped,
      ),
      title: const Text(
        'My Profile',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

    Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Not Signed In',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to backup your cashbooks to the cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMedium),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // --- FIX: Capture Result ---
                  final user = await _authService.signInWithGoogle();
                  if (user == null) {
                     // Show error if sign in failed
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sign In Failed. Check SHA-1 & Google-Services.json'),
                            backgroundColor: Colors.red,
                          )
                        );
                     }
                  }
                },
                icon: const Icon(Icons.login, color: _primaryOrange),
                label: const Text('Sign in with Google', style: TextStyle(color: _textDark)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bgWhite,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoggedInView(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryOrange, width: 3),
              image: DecorationImage(
                image: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : const AssetImage('assets/logo.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.displayName ?? 'Sage User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark),
          ),
          Text(
            user.email ?? '',
            style: const TextStyle(fontSize: 14, color: _textMedium),
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            onPressed: () async {
              await _authService.signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
