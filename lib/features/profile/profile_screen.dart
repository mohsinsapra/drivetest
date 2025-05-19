import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/settings/settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Profile Picture & Name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.pinkAccent,
                child: Icon(
                  LucideIcons.user,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alison Danis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'UX/UI Designer',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),

          // Menu Items
          _buildMenuTile(
            context,
            icon: Icons.person,
            iconColor: Colors.pink[100],
            title: 'Edit profile',
            onTap: () {}, // TODO: Add edit logic
          ),
          _buildMenuTile(
            context,
            icon: Icons.bar_chart,
            iconColor: Colors.purple[100],
            title: 'My stats',
            onTap: () {}, // TODO: Add stats screen
          ),
          _buildMenuTile(
            context,
            icon: Icons.settings,
            iconColor: Colors.orange[100],
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const Divider(
            thickness: 0.5,
            color: Color(0xFFE0E0E0),
          ),

          _buildMenuTile(
            context,
            icon: Icons.person_add_alt,
            iconColor: Colors.grey[300],
            title: 'Invite a friend',
            onTap: () {}, // TODO: Add invite logic
          ),
          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            iconColor: Colors.grey[300],
            title: 'Help',
            onTap: () {}, // TODO: Add help screen
          ),

          const Divider(
            thickness: 0.5,
            color: Color(0xFFE0E0E0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMenuTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.black),
    ),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
