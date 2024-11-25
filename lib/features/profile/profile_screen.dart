import 'package:flutter/material.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
              'Manage your profile and app settings.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to Profile Edit Screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(),
                    ));
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
