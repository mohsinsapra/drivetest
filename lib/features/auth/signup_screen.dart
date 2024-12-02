import 'dart:convert'; // For json.decode
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Map<String, String> _serverErrors = {};

  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      // Form is invalid, do not proceed
      return;
    }

    setState(() {
      _isLoading = true;
      _serverErrors.clear(); // Clear previous errors
    });

    try {
      final response = await _apiService.signup(
        _emailController.text,
        _usernameController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201) {
        // Signup successful
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please login.')),
        );
        Navigator.pop(context);
      } else {
        // Signup failed
        if (!mounted) return;

        // Parse server errors
        final errors = _parseErrors(response.body);

        setState(() {
          _serverErrors = errors;
        });

        // Show a general error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Signup failed. Please correct the errors.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Handle exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, String> _parseErrors(String responseBody) {
    final Map<String, dynamic> errorData = json.decode(responseBody);

    final Map<String, String> errors = {};

    errorData.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        errors[key] = value.first;
      } else if (value is String) {
        errors[key] = value;
      }
    });

    return errors;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (value.length < 4) {
      return 'Username must be at least 4 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          // To prevent overflow when keyboard appears
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey, // Assign the GlobalKey
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: _serverErrors['username'],
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _serverErrors['email'],
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _serverErrors['password'],
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signup,
                            child: const Text('Sign Up'),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
