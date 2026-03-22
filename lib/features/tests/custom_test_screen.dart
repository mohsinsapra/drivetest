import 'dart:async'; // Import for TimeoutException
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class CreateCustomTestScreen extends StatefulWidget {
  final String categoryName;
  final String licenceId;
  final String categoryId;

  const CreateCustomTestScreen({
    super.key,
    required this.categoryName,
    required this.licenceId,
    required this.categoryId,
  });

  @override
  State<CreateCustomTestScreen> createState() => _CreateCustomTestScreenState();
}

class _CreateCustomTestScreenState extends State<CreateCustomTestScreen>
    with WidgetsBindingObserver {
  bool isTimed = false;
  bool isInstantMarking = true;
  int numberOfQuestions = 10;
  int timerMinutes = 10;
  bool includeSavedQuestions = false;
  bool randomize = true;
  bool shuffleOnDevice = false;
  final ApiService _apiService = ApiService();

  late TextEditingController _numberOfQuestionsController;
  late TextEditingController _timerMinutesController;

  bool _isLoadingDialogDisplayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _numberOfQuestionsController =
        TextEditingController(text: numberOfQuestions.toString());
    _timerMinutesController =
        TextEditingController(text: timerMinutes.toString());
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTimed = prefs.getBool('isTimed') ?? false;
      isInstantMarking = prefs.getBool('isInstantMarking') ?? true;
      includeSavedQuestions = prefs.getBool('includeSavedQuestions') ?? false;
      numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 10;
      timerMinutes = prefs.getInt('timerMinutes') ?? numberOfQuestions;
      randomize = prefs.getBool('randomize') ?? true;
      shuffleOnDevice = prefs.getBool('shuffleOnDevice') ?? false;
      _numberOfQuestionsController.text = numberOfQuestions.toString();
      _timerMinutesController.text = timerMinutes.toString();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTimed', isTimed);
    await prefs.setBool('isInstantMarking', isInstantMarking);
    await prefs.setBool('includeSavedQuestions', includeSavedQuestions);
    await prefs.setInt('numberOfQuestions', numberOfQuestions);
    await prefs.setInt('timerMinutes', timerMinutes);
    await prefs.setBool('randomize', randomize);
    await prefs.setBool('shuffleOnDevice', shuffleOnDevice);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _numberOfQuestionsController.dispose();
    _timerMinutesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
    }
  }

  void _onStartTest() async {
    _isLoadingDialogDisplayed = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    List<Question>? fetchedQuestions;

    try {
      if (includeSavedQuestions) {
        // Fetch all questions and filter to saved ones
        final allQuestions = await _apiService
            .fetchQuestions(
              widget.licenceId,
              widget.categoryId,
              pageSize: 5000,
              randomize: randomize,
            )
            .timeout(const Duration(seconds: 30));

        final savedIds = await SavedQuestionsService.getSavedIds();

        if (savedIds.isEmpty) {
          if (_isLoadingDialogDisplayed && mounted) {
            Navigator.pop(context);
            _isLoadingDialogDisplayed = false;
          }
          showAppSnackBar(
              'No saved questions found. Save questions during a test first.');
          return;
        }

        final saved =
            allQuestions.where((q) => savedIds.contains(q.questionId)).toList();

        if (saved.isEmpty) {
          if (_isLoadingDialogDisplayed && mounted) {
            Navigator.pop(context);
            _isLoadingDialogDisplayed = false;
          }
          showAppSnackBar(
              'None of your saved questions are in this category.');
          return;
        }

        fetchedQuestions = saved.length > numberOfQuestions
            ? saved.sublist(0, numberOfQuestions)
            : saved;
      } else {
        fetchedQuestions = await _apiService
            .fetchQuestions(
              widget.licenceId,
              widget.categoryId,
              pageSize: numberOfQuestions,
              randomize: randomize,
            )
            .timeout(const Duration(seconds: 15));
      }

      if (fetchedQuestions.isEmpty) {
        if (_isLoadingDialogDisplayed && mounted) {
          Navigator.pop(context);
          _isLoadingDialogDisplayed = false;
        }
        showAppSnackBar('No questions available.');
        return;
      }

      // Shuffle on device after fetching (independent of backend randomization)
      if (shuffleOnDevice) {
        fetchedQuestions.shuffle(Random());
      }
    } on TimeoutException catch (_) {
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
      showAppSnackBar('Request timed out. Please try again.');
      return;
    } catch (e) {
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
      showAppSnackBar('Failed to start test. Please try again.');
      return;
    } finally {
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Testscreen(
              questions: fetchedQuestions!,
              instantMarking: isInstantMarking,
              licenceId: widget.licenceId,
              categoryId: widget.categoryId,
              categoryName: widget.categoryName,
              isTimed: isTimed,
              timeLimitMinutes: timerMinutes,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const int maxQuestions = 1000;
    const int maxTimerMinutes = 180;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName),
        actions: [
          TextButton(
            onPressed: _onStartTest,
            child: const Text(
              'Start Test',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ── Timed Test ────────────────────────────────────────────
            SwitchListTile(
              title: const Text('Timed Test'),
              subtitle: const Text('Enable a time limit for the test'),
              value: isTimed,
              onChanged: (value) {
                setState(() {
                  isTimed = value;
                  if (value && timerMinutes <= 0) {
                    timerMinutes = numberOfQuestions;
                    _timerMinutesController.text = timerMinutes.toString();
                  }
                });
                _savePreferences();
              },
            ),
            if (isTimed) ...[
              ListTile(
                title: const Text('Time Limit (minutes)'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: timerMinutes.toDouble().clamp(1, maxTimerMinutes.toDouble()),
                      min: 1,
                      max: maxTimerMinutes.toDouble(),
                      divisions: maxTimerMinutes - 1,
                      label: '$timerMinutes min',
                      onChanged: (value) {
                        setState(() {
                          timerMinutes = value.toInt();
                          _timerMinutesController.text =
                              timerMinutes.toString();
                        });
                        _savePreferences();
                      },
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('Enter minutes:')),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _timerMinutesController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: 'e.g. 10'),
                            onChanged: (value) {
                              final int? v = int.tryParse(value);
                              if (v != null &&
                                  v > 0 &&
                                  v <= maxTimerMinutes) {
                                setState(() => timerMinutes = v);
                                _savePreferences();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),

            // ── Instant Marking ───────────────────────────────────────
            SwitchListTile(
              title: const Text('Instant Marking'),
              subtitle: const Text('Show correct answer after each question'),
              value: isInstantMarking,
              onChanged: (value) {
                setState(() => isInstantMarking = value);
                _savePreferences();
              },
            ),
            const Divider(),

            // ── Randomize Questions (backend) ─────────────────────────
            SwitchListTile(
              title: const Text('New Random Questions'),
              subtitle: const Text(
                  'Get a fresh set of different questions every time you start a test'),
              value: randomize,
              onChanged: (value) {
                setState(() => randomize = value);
                _savePreferences();
              },
            ),
            const Divider(),

            // ── Shuffle on Device (frontend) ──────────────────────────
            SwitchListTile(
              title: const Text('Mix Up Question Order'),
              subtitle: const Text(
                  'Keep the same questions but show them in a different order each time'),
              value: shuffleOnDevice,
              onChanged: (value) {
                setState(() => shuffleOnDevice = value);
                _savePreferences();
              },
            ),
            const Divider(),

            // ── Number of Questions ───────────────────────────────────
            ListTile(
              title: const Text('Number of Questions'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: numberOfQuestions.toDouble(),
                    min: 1,
                    max: maxQuestions.toDouble(),
                    divisions: maxQuestions - 1,
                    label: '$numberOfQuestions',
                    onChanged: (value) {
                      setState(() {
                        numberOfQuestions = value.toInt();
                        _numberOfQuestionsController.text =
                            numberOfQuestions.toString();
                      });
                      _savePreferences();
                    },
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Enter number of questions:'),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _numberOfQuestionsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 10',
                          ),
                          onChanged: (value) {
                            final int? newValue = int.tryParse(value);
                            if (newValue != null &&
                                newValue > 0 &&
                                newValue <= maxQuestions) {
                              setState(() => numberOfQuestions = newValue);
                              _savePreferences();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // ── Include Saved Questions ───────────────────────────────
            SwitchListTile(
              title: const Text('Include Saved Questions'),
              subtitle: const Text(
                  'Use only questions you bookmarked during tests'),
              value: includeSavedQuestions,
              onChanged: (value) {
                setState(() => includeSavedQuestions = value);
                _savePreferences();
              },
            ),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onStartTest,
              child: const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }
}
