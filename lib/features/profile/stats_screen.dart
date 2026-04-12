import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';

class StatsScreen extends StatefulWidget {
  /// Optional subtitle shown below "Statistics" in the AppBar.
  final String? subtitle;

  /// When set, only attempts with this licenceName are shown.
  /// null = show all attempts (used from profile screen).
  final String? licenceNameFilter;

  const StatsScreen({super.key, this.subtitle, this.licenceNameFilter});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<TestAttempt> _attempts = [];
  bool _isLoading = true;
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    try {
      final box = Hive.isBoxOpen('testAttempts')
          ? Hive.box<TestAttempt>('testAttempts')
          : await Hive.openBox<TestAttempt>('testAttempts');
      final filter = widget.licenceNameFilter;
      final all = box.values.where((a) {
        if (!a.isCompleted) return false;
        if (filter != null) return a.licenceName == filter;
        return true;
      }).toList();
      all.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      if (mounted) setState(() { _attempts = all; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _correctCount(TestAttempt a) {
    int count = 0;
    for (int i = 0; i < a.questions.length; i++) {
      if (a.userSelections[i] == a.questions[i].correctAnswer) count++;
    }
    return count;
  }

  String _fmtDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    final h = m ~/ 60; final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }

  String _fmtDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  int get _completedCount => _attempts.length;
  double get _passRate => _completedCount == 0 ? 0 :
      _attempts.where((a) => a.hasPassed).length / _completedCount * 100;
  double get _bestScore => _completedCount == 0 ? 0 :
      _attempts.map((a) => a.score).reduce(max);
  double get _avgScore => _completedCount == 0 ? 0 :
      _attempts.map((a) => a.score).reduce((a, b) => a + b) / _completedCount;
  int get _totalSeconds => _attempts.fold(0, (s, a) => s + (a.durationSeconds ?? 0));
  double get _latestScore => _attempts.isEmpty ? 0 : _attempts.first.score;

  // ── Per-test breakdown grouping ───────────────────────────────────────────
  Map<String, List<TestAttempt>> get _grouped {
    final map = <String, List<TestAttempt>>{};
    for (final a in _attempts) {
      final key = '${a.licenceId ?? a.licenceName ?? ''}||'
          '${a.categoryId ?? a.categoryName ?? ''}';
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  String _groupLabel(String key, List<TestAttempt> group) {
    final first = group.first;
    if ((first.categoryName ?? '').isNotEmpty) return first.categoryName!;
    if ((first.licenceName ?? '').isNotEmpty) return first.licenceName!;
    return 'Unknown';
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String key, List<TestAttempt> group) {
    final isExpanded = _expandedGroups.contains(key);
    final label = _groupLabel(key, group);
    final avgScore = group.map((a) => a.score).reduce((a, b) => a + b) / group.length;
    final bestScore = group.map((a) => a.score).reduce(max);
    final avgSeconds = group.fold(0, (s, a) => s + (a.durationSeconds ?? 0)) ~/ group.length;
    final latestPassed = group.first.hasPassed;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // ── Header row ───────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() {
              if (isExpanded) { _expandedGroups.remove(key); }
              else { _expandedGroups.add(key); }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(
                          '${group.length} ${group.length == 1 ? 'attempt' : 'attempts'} • Avg: ${avgScore.round()}%',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: latestPassed ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      latestPassed ? 'Passed' : 'Failed',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────────────────────
          if (isExpanded) ...[
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Best / Average / Avg time
                  Row(
                    children: [
                      Expanded(child: _miniStat(
                        value: '${bestScore.round()}%',
                        label: 'Best',
                        valueColor: const Color(0xFF4CAF50),
                      )),
                      Expanded(child: _miniStat(
                        value: '${avgScore.round()}%',
                        label: 'Average',
                      )),
                      Expanded(child: _miniStat(
                        value: _fmtDuration(avgSeconds),
                        label: 'Avg time',
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('ATTEMPT HISTORY',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ...group.map((a) => _attemptHistoryRow(a)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat({required String value, required String label, Color? valueColor}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _attemptHistoryRow(TestAttempt a) {
    final correct = _correctCount(a);
    final total = a.questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            a.hasPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: a.hasPassed ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$correct/$total (${a.score.round()}%)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(_fmtDate(a.dateTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(_fmtDuration(a.durationSeconds ?? 0),
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _allAttemptRow(TestAttempt a) {
    final correct = _correctCount(a);
    final total = a.questions.length;
    final testName = (a.categoryName?.isNotEmpty == true)
        ? a.categoryName!
        : (a.licenceName ?? 'Unknown');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            a.hasPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: a.hasPassed ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(testName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(_fmtDate(a.dateTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$correct/$total',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${a.score.round()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 12),
          Text(_fmtDuration(a.durationSeconds ?? 0),
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (widget.subtitle != null)
              Text(widget.subtitle!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey,
                      fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No completed tests yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAttempts,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── 2×3 stat grid ─────────────────────────────────────
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _statCard(
                            value: '$_completedCount',
                            label: 'Completed tests',
                            icon: Icons.description_outlined,
                            iconBg: Colors.blue.withValues(alpha: 0.15),
                            iconColor: const Color(0xFF1976D2),
                          ),
                          _statCard(
                            value: '${_passRate.round()}%',
                            label: 'Pass rate',
                            icon: Icons.gps_fixed,
                            iconBg: Colors.green.withValues(alpha: 0.15),
                            iconColor: const Color(0xFF388E3C),
                          ),
                          _statCard(
                            value: '${_bestScore.round()}%',
                            label: 'Best score',
                            icon: Icons.emoji_events_outlined,
                            iconBg: Colors.orange.withValues(alpha: 0.15),
                            iconColor: const Color(0xFFF57C00),
                          ),
                          _statCard(
                            value: '${_avgScore.round()}%',
                            label: 'Average score',
                            icon: Icons.trending_up,
                            iconBg: Colors.blue.withValues(alpha: 0.15),
                            iconColor: const Color(0xFF1976D2),
                          ),
                          _statCard(
                            value: _fmtDuration(_totalSeconds),
                            label: 'Total study time',
                            icon: Icons.access_time,
                            iconBg: Colors.purple.withValues(alpha: 0.15),
                            iconColor: const Color(0xFF7B1FA2),
                          ),
                          _statCard(
                            value: '${_latestScore.round()}%',
                            label: 'Latest result',
                            icon: Icons.cancel_outlined,
                            iconBg: Colors.red.withValues(alpha: 0.15),
                            iconColor: const Color(0xFFD32F2F),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Per-test breakdown ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Per-test breakdown',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),
                            ..._grouped.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildBreakdownCard(e.key, e.value),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── All attempts ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('All attempts',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),
                            ..._attempts.map(_allAttemptRow),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
