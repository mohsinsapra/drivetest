// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TestAttempt> _previousAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousAttempts();
  }

  void _loadPreviousAttempts() async {
    var box = await Hive.openBox<TestAttempt>('testAttempts');

    setState(() {
      _previousAttempts = box.values.toList().cast<TestAttempt>();
    });
  }

  Future<void> _deleteAllTests() async {
    var box = await Hive.openBox<TestAttempt>('testAttempts');
    await box.clear(); // This deletes all entries in the box
    await box.close();

    // Optionally, update the UI or notify the user
    setState(() {
      _previousAttempts.clear();
    });

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All tests have been deleted.')),
    );
  }

  void _confirmDeleteAllTests() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Tests'),
          content: const Text(
              'Are you sure you want to delete all test attempts? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _deleteAllTests(); // Call the method to delete all tests
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_previousAttempts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Previous Tests'),
        ),
        body: const Center(
          child: Text('No previous attempts found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteAllTests,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _previousAttempts.length,
        itemBuilder: (context, index) {
          final attempt = _previousAttempts[index];
          return ListTile(
            title: Text(
              'Attempt on ${attempt.dateTime.toLocal().toString().split('.')[0]}',
            ),
            subtitle: Text(
                'Score: ${attempt.score.toStringAsFixed(1)}%, Passed: ${attempt.hasPassed ? 'Yes' : 'No'}'),
            onTap: () {
              // Navigate to AttemptDetailScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttemptDetailScreen(attempt: attempt),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
