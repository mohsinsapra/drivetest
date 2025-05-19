import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _authError;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _authError = null; // Reset previous error
    });

    try {
      await _apiService.authenticate(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      final user = await _apiService.fetchCurrentUser();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user', jsonEncode(user));
      }
      final refreshToken = DioClient().refreshToken;
      final accessToken = DioClient().accessToken;

      if (refreshToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('accessToken', accessToken!);
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      print(e);
      setState(() {
        _authError = 'Invalid username or password';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _usernameController.text = 'admin';
    _passwordController.text = "123";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 250,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Lottie.asset(
                      'assets/animations/login.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_authError != null)
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _authError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Username field
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _authenticate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
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
