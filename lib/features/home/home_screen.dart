// history_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/utils/calculate_stats.dart';
import 'package:taxi_exam_app/core/widgets/attempt_entry_card.dart';
import 'package:taxi_exam_app/core/widgets/attempt_group_card.dart';
import 'package:taxi_exam_app/core/widgets/attempt_spark_widget.dart';
import 'package:taxi_exam_app/core/widgets/attempt_tabs_widget.dart';
import 'package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart';

import 'package:taxi_exam_app/core/widgets/user_header_widget.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TestAttempt> _previousAttempts = [];
  List<TestAttempt> _pausedAttempts = [];
  Map<String, dynamic> _stats = {};
  int selectedTabIndex = 0;
  late final VoidCallback _tabListener;
  // Saved reference so dispose() can safely remove the listener without context
  MainScreenProvider? _mainScreenProvider;

  List<String> get licenceNames =>
      _stats['licenceWithCategories']?.keys.toList() ?? [];

  String get selectedLicence =>
      licenceNames.isNotEmpty ? licenceNames[selectedTabIndex] : '';

  @override
  void initState() {
    super.initState();
    _loadPreviousAttempts();
    _tabListener = () {
      if (_mainScreenProvider?.currentIndex == 0 && mounted) {
        _loadPreviousAttempts();
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mainScreenProvider = Provider.of<MainScreenProvider>(context, listen: false);
      _mainScreenProvider!.addListener(_tabListener);
    });
  }

  @override
  void dispose() {
    _mainScreenProvider?.removeListener(_tabListener);
    super.dispose();
  }

  void _loadPreviousAttempts() async {
    final box = await Hive.openBox<TestAttempt>('testAttempts');
    _refreshFromBox(box);
    _syncFromBackend(box); // background — no await
  }

  void _refreshFromBox(Box<TestAttempt> box) {
    if (!mounted) return;
    final all = box.values.toList().cast<TestAttempt>();
    setState(() {
      _pausedAttempts = all.where((a) => a.isPaused).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _previousAttempts = all.where((a) => a.isCompleted).toList();
      _stats = calculateStats(_previousAttempts);
    });
  }

  Future<void> _syncFromBackend(Box<TestAttempt> box) async {
    final apiService = ApiService();
    final remoteList = await apiService.fetchTestAttempts();
    bool changed = false;
    for (final data in remoteList) {
      final id = data['attempt_id'] as String? ?? '';
      if (id.isEmpty || box.containsKey(id)) continue;

      // For paused tests, fetch the exact questions from the backend
      // so the user can resume on this device too
      List<Question> questions = const [];
      if ((data['status'] as String? ?? '') == 'paused') {
        questions = await apiService.fetchQuestionsForAttempt(id);
      }

      final attempt = apiService.testAttemptFromJson(data, questions: questions);
      if (attempt != null) {
        await box.put(id, attempt);
        changed = true;
      }
    }
    if (changed) _refreshFromBox(box);
  }

  Future<void> _deleteAllTests() async {
    final box = await Hive.openBox<TestAttempt>('testAttempts');
    await box.clear();
    setState(() {
      _previousAttempts.clear();
      _pausedAttempts.clear();
    });
    showAppSnackBar('All tests have been deleted.');
    // Remove from backend (fire-and-forget — local is already cleared above)
    ApiService().deleteAllTestAttempts();
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

  void _confirmDeletePausedTest(TestAttempt attempt) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Progress'),
          content: const Text(
              'Are you sure you want to delete this saved test? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Remove from UI immediately
                setState(() => _pausedAttempts.removeWhere((a) => a.testId == attempt.testId));
                // Remove from local Hive
                final box = await Hive.openBox<TestAttempt>('testAttempts');
                await box.delete(attempt.testId);
                // Remove from backend
                ApiService().deleteTestAttempt(attempt.testId);
              },
            ),
          ],
        );
      },
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

  Widget _buildPausedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'In Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ..._pausedAttempts.map((attempt) => _PausedTestCard(
              attempt: attempt,
              canResume: attempt.questions.isNotEmpty,
              onResume: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Testscreen(
                      questions: attempt.questions,
                      instantMarking: true,
                      licenceId: attempt.licenceId ?? '',
                      categoryId: attempt.categoryId ?? '',
                      licenceName: attempt.licenceName ?? '',
                      categoryName: attempt.categoryName ?? '',
                      initialQuestionIndex: attempt.currentQuestionIndex,
                      userSelections: attempt.userSelections,
                      resumeTestId: attempt.testId,
                    ),
                  ),
                );
                _loadPreviousAttempts();
              },
              onDelete: () => _confirmDeletePausedTest(attempt),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _previousAttempts.isNotEmpty;
    final Map<String, Map<String, int>> licenceWithCategories =
        Map<String, Map<String, int>>.from(
            _stats['licenceWithCategories'] ?? {});
    List<String> licenceNames = licenceWithCategories.keys.toList();

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
              onPressed: () {},
            ),
          ),
          if (hasData)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDeleteAllTests,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Always-visible: In Progress tests ─────────────────
              if (_pausedAttempts.isNotEmpty) _buildPausedSection(),

              // ── Completed attempts dashboard ───────────────────────
              if (hasData) ...[
                UserHeaderWidget(
                    overallPercentage: _stats['averageScore'] ?? 0),
                const SizedBox(height: 24),
                AttemptTabsWidget(
                  tabNames: licenceNames,
                  selectedIndex: selectedTabIndex,
                  onTabChanged: (i) => setState(() => selectedTabIndex = i),
                ),
                const SizedBox(height: 16),
                AttemptGroupCard(
                  licence: selectedLicence,
                  status:
                      (_stats['licenceCounts'][selectedLicence] ?? 0) >= 3
                          ? "Promoted"
                          : "In Progress",
                  dateRange: _buildDateRange(selectedLicence),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Today',
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
                            const Text('This month',
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
                const SizedBox(height: 8),
                if (_stats['licenceWithCategories'] != null &&
                    _stats['licenceWithCategories'][selectedLicence] != null)
                  CategoryPieChart(
                    data: Map<String, int>.from(
                      _stats['licenceWithCategories'][selectedLicence],
                    ),
                  ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Previous Attempts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
              ] else if (_pausedAttempts.isEmpty) ...[
                // Truly nothing yet — no paused, no completed
                Center(
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
                          'No attempts yet!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Once you complete a quiz, your results will show up here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<MainScreenProvider>(context,
                                    listen: false)
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedTestCard extends StatelessWidget {
  final TestAttempt attempt;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final bool canResume;

  const _PausedTestCard({
    required this.attempt,
    required this.onResume,
    required this.onDelete,
    this.canResume = true,
  });

  @override
  Widget build(BuildContext context) {
    final answered = attempt.userSelections.length;
    final total = attempt.questions.length;
    final progress = total > 0 ? answered / total : 0.0;
    final dt = attempt.dateTime;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade50,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Paused',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${attempt.categoryName ?? 'Unknown'} — ${attempt.licenceName ?? ''}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '$dateStr  •  Q${attempt.currentQuestionIndex + 1} of $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$answered / $total answered',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canResume ? onResume : null,
                icon: Icon(
                  canResume ? Icons.play_arrow : Icons.device_unknown,
                  size: 18,
                ),
                label: Text(canResume ? 'Resume Test' : 'Resume on original device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canResume ? Colors.orange : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
