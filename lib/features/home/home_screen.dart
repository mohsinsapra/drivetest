// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/utils/calculate_stats.dart';
import 'package:taxi_exam_app/core/widgets/attempt_entry_card.dart';
import 'package:taxi_exam_app/core/widgets/attempt_group_card.dart';
import 'package:taxi_exam_app/core/widgets/attempt_spark_widget.dart';
import 'package:taxi_exam_app/core/widgets/attempt_tabs_widget.dart';
import 'package:taxi_exam_app/core/widgets/attempt_timeline_chart.dart';
import 'package:taxi_exam_app/core/widgets/category_bar_chart_widget.dart';
import 'package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart';

import 'package:taxi_exam_app/core/widgets/user_header_widget.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TestAttempt> _previousAttempts = [];
  Map<String, dynamic> _stats = {};
  int selectedTabIndex = 0;

  List<String> get licenceNames =>
      _stats['licenceWithCategories']?.keys.toList() ?? [];

  String get selectedLicence =>
      licenceNames.isNotEmpty ? licenceNames[selectedTabIndex] : '';
  @override
  void initState() {
    super.initState();
    _loadPreviousAttempts();
  }

  void _loadPreviousAttempts() async {
    var box = await Hive.openBox<TestAttempt>('testAttempts');

    setState(() {
      _previousAttempts = box.values.toList().cast<TestAttempt>();
      _stats = calculateStats(_previousAttempts);
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

  String _buildDateRange(String licence) {
    final attempts = _previousAttempts
        .where((a) => a.licenceName == licence)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (attempts.isEmpty) return '';

    final start = attempts.first.dateTime;
    final end = attempts.last.dateTime;
    return "${start.day}/${start.month} to ${end.day}/${end.month}";
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

  Map<String, int> getDailyAttemptCounts(List<TestAttempt> attempts) {
    final now = DateTime.now();
    final Map<String, int> result = {};

    for (int i = 6; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = "${date.day}/${date.month}";
      final count = attempts
          .where((a) =>
              a.dateTime.year == date.year &&
              a.dateTime.month == date.month &&
              a.dateTime.day == date.day)
          .length;
      result[key] = count;
    }

    return result;
  }

  Map<String, int> getMonthlyAttemptCounts(List<TestAttempt> attempts) {
    final now = DateTime.now();
    final Map<String, int> result = {};

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = "${date.month}/${date.year}";
      final count = attempts
          .where((a) =>
              a.dateTime.year == date.year && a.dateTime.month == date.month)
          .length;
      result[key] = count;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _previousAttempts.isNotEmpty;
    final Map<String, Map<String, int>> licenceWithCategories =
        Map<String, Map<String, int>>.from(
            _stats['licenceWithCategories'] ?? {});
    List<String> licenceNames = licenceWithCategories.keys.toList();

    // Filter attempts for today and this month

    final dailyCounts = getDailyAttemptCounts(
      _previousAttempts.where((a) => a.licenceName == selectedLicence).toList(),
    );

    final monthlyCounts = getMonthlyAttemptCounts(
      _previousAttempts.where((a) => a.licenceName == selectedLicence).toList(),
    );

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 User Header with overall average score
                    UserHeaderWidget(
                        overallPercentage: _stats['averageScore'] ?? 0),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text("Today",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                AttemptCountLineGraph(
                                    data: dailyCounts,
                                    lineColor: Colors.redAccent),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text("This month",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                AttemptCountLineGraph(
                                    data: monthlyCounts,
                                    lineColor: Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Tabs for each licence type
                    AttemptTabsWidget(
                      tabNames: licenceNames,
                      selectedIndex: selectedTabIndex,
                      onTabChanged: (i) => setState(() => selectedTabIndex = i),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Group card for selected licence
                    AttemptGroupCard(
                      licence: selectedLicence,
                      status:
                          (_stats['licenceCounts'][selectedLicence] ?? 0) >= 3
                              ? "Promoted"
                              : "In Progress",
                      dateRange: _buildDateRange(selectedLicence),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Attempts List filtered by selected licence
                    ..._previousAttempts
                        .where((a) => a.licenceName == selectedLicence)
                        .map((attempt) => GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttemptDetailScreen(attempt: attempt),
                                  ),
                                );
                              },
                              child: AttemptEntryCard(attempt: attempt),
                            )),

                    const SizedBox(height: 16),

                    // 🔹 Optional charts if needed

                    if (_stats['licenceWithCategories'] != null &&
                        _stats['licenceWithCategories'][selectedLicence] !=
                            null)
                      CategoryPieChart(
                        data: Map<String, int>.from(
                          _stats['licenceWithCategories'][selectedLicence],
                        ),
                      ),
                  ],
                ),
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
