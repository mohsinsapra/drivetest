import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/services/version_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTimed = false;
  bool isInstantMarking = false;
  bool includeSavedQuestions = false;
  int numberOfQuestions = 10;
  int maxQuestions = 1000;
  VersionInfo? _versionInfo;

  final TextEditingController _numberOfQuestionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final versionInfo = await VersionService.getVersionInfo();
      setState(() {
        _versionInfo = versionInfo;
      });
    } catch (e) {
      debugPrint('Failed to load version info: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTimed = prefs.getBool('isTimed') ?? false;
      isInstantMarking = prefs.getBool('isInstantMarking') ?? false;
      includeSavedQuestions = prefs.getBool('includeSavedQuestions') ?? false;
      numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 10;
      _numberOfQuestionsController.text = numberOfQuestions.toString();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTimed', isTimed);
    await prefs.setBool('isInstantMarking', isInstantMarking);
    await prefs.setBool('includeSavedQuestions', includeSavedQuestions);
    await prefs.setInt('numberOfQuestions', numberOfQuestions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Settings')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    SwitchListTile(
                      title: const Text('Timed Test'),
                      subtitle: const Text('Enable a time limit for the test'),
                      value: isTimed,
                      onChanged: (value) {
                        setState(() {
                          isTimed = value;
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Instant Marking'),
                      subtitle:
                          const Text('Show correct answer after each question'),
                      value: isInstantMarking,
                      onChanged: (value) {
                        setState(() {
                          isInstantMarking = value;
                        });
                      },
                    ),
                    const Divider(),
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
                            },
                          ),
                          Row(
                            children: [
                              const Expanded(
                                  child: Text('Enter number of questions:')),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _numberOfQuestionsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      hintText: 'e.g. 10'),
                                  onChanged: (value) {
                                    final int? newValue = int.tryParse(value);
                                    if (newValue != null &&
                                        newValue > 0 &&
                                        newValue <= maxQuestions) {
                                      setState(() {
                                        numberOfQuestions = newValue;
                                      });
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
                    SwitchListTile(
                      title: const Text('Include Saved Questions'),
                      subtitle:
                          const Text('Include questions you previously saved'),
                      value: includeSavedQuestions,
                      onChanged: (value) {
                        setState(() {
                          includeSavedQuestions = value;
                        });
                      },
                    ),
                    const Divider(height: 32),
                    if (_versionInfo != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Version Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildVersionInfoRow(
                              'App Version',
                              'v${_versionInfo!.appVersion} (${_versionInfo!.buildNumber})',
                            ),
                            if (_versionInfo!.hasGitInfo) ...[
                              const SizedBox(height: 8),
                              _buildVersionInfoRow(
                                'Commit',
                                _versionInfo!.shortHash,
                              ),
                              const SizedBox(height: 8),
                              _buildVersionInfoRow(
                                'Branch',
                                _versionInfo!.branch,
                              ),
                              const SizedBox(height: 8),
                              _buildVersionInfoRow(
                                'Last Update',
                                _versionInfo!.commitMessage,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              _buildVersionInfoRow(
                                'Date',
                                _versionInfo!.commitDate,
                                fontSize: 12,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  label: const Text('Save'),
                  onPressed: () async {
                    await _savePreferences();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfoRow(
    String label,
    String value, {
    int maxLines = 1,
    double fontSize = 14,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
