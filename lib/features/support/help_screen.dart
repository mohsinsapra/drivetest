import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  String _userId = 'Not available';
  String _username = 'Not available';
  String _userEmail = 'Not available';
  Map<String, dynamic>? _userMap;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user');

    if (storedUser != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(storedUser);
        setState(() {
          _userMap = userMap;
          // Try multiple possible field names for user ID
          _userId = (userMap['id'] ??
                     userMap['user_id'] ??
                     userMap['pk'] ??
                     userMap['userId'] ??
                     'Not available').toString();
          _username = userMap['username']?.toString() ?? 'Not available';
          _userEmail = userMap['email']?.toString() ?? 'Not available';
        });

        // Debug print to see what fields are actually available
        debugPrint('User data fields: ${userMap.keys.join(', ')}');
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare email details
      final String email = 'mohsin.sapra@gmail.com';
      final String subject = Uri.encodeComponent('Taxi Exam App - ${_subjectController.text.trim()}');
      final String body = Uri.encodeComponent(
        'Hello Support Team,\n\n'
        'I am writing to request assistance with the following issue:\n\n'
        'ISSUE DETAILS\n\n'
        'Subject: ${_subjectController.text.trim()}\n\n'
        'Description:\n'
        '${_descriptionController.text.trim()}\n\n\n'
        'USER INFORMATION\n\n'
        'User ID: $_userId\n'
        'Username: $_username\n'
        'Email: $_userEmail\n\n\n'
        'ADDITIONAL INFORMATION\n\n'
        'Please add any additional details below:\n\n'
        'Device Type: \n'
        'App Version: \n'
        'When did this occur: \n'
        'Steps to reproduce: \n\n\n'
        'Thank you for your assistance!\n\n'
        'Best regards,\n'
        '$_username\n\n'
        'This email was generated from the Taxi Exam App',
      );

      final Uri emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (!mounted) return;

        // Show success message and navigate back
        showAppSnackBar('Opening email app...');
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        showAppSnackBar('Could not open email app. Please email mohsin.sapra@gmail.com directly.');
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (!mounted) return;
      showAppSnackBar('Error opening email app. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.blue,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tell us about your issue and we\'ll get back to you soon.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Info Display
                  if (_userMap != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Information',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(context, 'Username', _username),
                          _buildInfoRow(context, 'Email', _userEmail),
                          _buildInfoRow(context, 'User ID', _userId),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Subject Field
                  const Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Login issue, Bug report, Feature request',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Description Field
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Please describe your issue in detail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your issue';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide more details (at least 10 characters)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact Info
                  Center(
                    child: Text(
                      'Or email us directly at mohsin.sapra@gmail.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
