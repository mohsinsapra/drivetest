// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

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
    final bool hasData = _previousAttempts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // Add your notification logic here
              },
            ),
          ),
          if (hasData)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDeleteAllTests,
            ),
        ],
      ),
      body: hasData
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _previousAttempts.length,
                itemBuilder: (context, index) {
                  final attempt = _previousAttempts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AttemptDetailScreen(attempt: attempt),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Icon(
                              attempt.hasPassed
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: attempt.hasPassed
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attempt on ${attempt.dateTime.toLocal().toString().split('.')[0]}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Score: ${attempt.score.toStringAsFixed(1)}%, '
                                  'Passed: ${attempt.hasPassed ? 'Yes' : 'No'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Lottie.asset(
                          'assets/animations/no_attempts.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "No attempts yet!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Once you complete a quiz, your results will show up here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to quiz list or start quiz
                        Provider.of<MainScreenProvider>(context, listen: false)
                            .setIndex(1);
                      },
                      child: const Text(
                        'Take Your First Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
