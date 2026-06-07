import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_exam_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_category_mistakes_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

/// One entry in the Smart Learning exam list.
class SmartExamEntry {
  final int testBcdId;
  final String testName;
  final String categoryName;
  final int parentCategoryBcdId;
  final int questionCount;
  final int passScore;
  final int timeLimit;
  final List<int> chunkSizes;

  const SmartExamEntry({
    required this.testBcdId,
    required this.testName,
    required this.categoryName,
    required this.parentCategoryBcdId,
    required this.questionCount,
    required this.passScore,
    required this.timeLimit,
    required this.chunkSizes,
  });
}

/// Smart Learning entry screen.
///
/// [examBcdId] scopes the screen to one exam (the user's active exam).
/// When null, all BCD categories are shown (fallback).
///
/// [categoryFilter] is set internally when drilling into a sub-category.
class SmartLearningScreen extends StatefulWidget {
  final int? examBcdId;
  final String? categoryFilter;
  // Pre-loaded from parent to avoid redundant Hive reads on drill-down.
  final Map<int, int>? initialPassedCounts;
  final Map<int, DateTime>? initialActivityDates;

  const SmartLearningScreen({
    super.key,
    this.examBcdId,
    this.categoryFilter,
    this.initialPassedCounts,
    this.initialActivityDates,
  });

  @override
  State<SmartLearningScreen> createState() => _SmartLearningScreenState();
}

class _SmartLearningScreenState extends State<SmartLearningScreen> {
  final _svc = SmartProgressService();
  List<SmartExamEntry> _allEntries = [];
  Map<int, int> _passedCounts = {}; // testBcdId → chunks passed
  Map<int, DateTime> _lastActivityDates =
      {}; // testBcdId → most recent completedAt
  int _categoryWeakCount = 0;

  @override
  void initState() {
    super.initState();
    _allEntries = _buildEntries();
    if (widget.initialPassedCounts != null) {
      _passedCounts = widget.initialPassedCounts!;
      _lastActivityDates = widget.initialActivityDates ?? {};
      _loadWeakCount();
    } else {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final chunkCounts = {
      for (final e in _allEntries) e.testBcdId: e.chunkSizes.length,
    };
    // Single Hive box open for both pass counts + activity dates.
    final progress = await _svc.batchProgress(chunkCounts);
    // Weak count uses its own box — run concurrently with nothing else pending.
    final weakCount = await _svc.weakQuestionCountForTests(
        _filteredEntries.map((e) => e.testBcdId).toList());
    if (!mounted) return;
    setState(() {
      _passedCounts = progress.passedCounts;
      _lastActivityDates = progress.activityDates;
      _categoryWeakCount = weakCount;
    });
  }

  Future<void> _loadWeakCount() async {
    final weakCount = await _svc.weakQuestionCountForTests(
        _filteredEntries.map((e) => e.testBcdId).toList());
    if (!mounted) return;
    setState(() => _categoryWeakCount = weakCount);
  }

  Future<void> _load() async {
    _allEntries = _buildEntries();
    await _loadProgress();
  }

  List<SmartExamEntry> _buildEntries() {
    final entries = <SmartExamEntry>[];
    final cache = BcdCache.instance;

    // Show all top-level categories (free + paid), scoped to examBcdId when set.
    // Subcategory names are intentionally not used as category labels — the
    // top-level category name is shown so the list matches the Licences screen.
    var allCats = List<Map<String, dynamic>>.from(cache.categories);

    if (widget.examBcdId != null) {
      allCats = allCats.where((c) => c['bcd_id'] == widget.examBcdId).toList();
    }

    for (final cat in allCats) {
      final catId = cat['bcd_id'] as int;
      final catName = stripAppSuffix(cat['name']?.toString() ?? '');
      final hasSubs = cat['has_children'] == true;

      if (hasSubs) {
        for (final sub in cache.subcategoriesOf(catId)) {
          final subId = sub['bcd_id'] as int;
          for (final test in cache.testsOf(subId)) {
            final entry = _entryFromTest(test, catName, subId);
            if (entry != null) entries.add(entry);
          }
        }
      } else {
        for (final test in cache.testsOf(catId)) {
          final entry = _entryFromTest(test, catName, catId);
          if (entry != null) entries.add(entry);
        }
      }
    }
    return entries;
  }

  SmartExamEntry? _entryFromTest(
      Map<String, dynamic> test, String catName, int catId) {
    final qc = test['question_count'] as int? ?? 0;
    if (qc == 0) return null;
    final sizes = SmartUtils.computeSmartSizes(qc);
    return SmartExamEntry(
      testBcdId: test['bcd_id'] as int,
      testName: stripAppSuffix(test['name']?.toString() ?? ''),
      categoryName: catName,
      parentCategoryBcdId: catId,
      questionCount: qc,
      passScore: test['pass_score'] as int? ?? 0,
      timeLimit: test['time_limit'] as int? ?? 0,
      chunkSizes: sizes,
    );
  }

  // ── Derived state ──────────────────────────────────────────────────────────

  List<SmartExamEntry> get _filteredEntries {
    final base = widget.categoryFilter == null
        ? _allEntries
        : _allEntries
            .where((e) => e.categoryName == widget.categoryFilter)
            .toList();
    return _sortedEntries(base);
  }

  /// Sort entries by most recent activity (newest first), untouched last.
  /// Ties fall back to test name so order is deterministic.
  List<SmartExamEntry> _sortedEntries(List<SmartExamEntry> entries) {
    return [...entries]..sort((a, b) {
        final dateA = _lastActivityDates[a.testBcdId];
        final dateB = _lastActivityDates[b.testBcdId];
        if (dateA == null && dateB == null) {
          return a.testName.compareTo(b.testName);
        }
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        final cmp = dateB.compareTo(dateA);
        return cmp != 0 ? cmp : a.testName.compareTo(b.testName);
      });
  }

  List<String> get _distinctCategories =>
      _allEntries.map((e) => e.categoryName).toSet().toList();

  /// category name → true when the category has no subscription product (free).
  Map<String, bool> get _categoryIsFree {
    final result = <String, bool>{};
    for (final cat in BcdCache.instance.categories) {
      final name = stripAppSuffix(cat['name']?.toString() ?? '');
      result[name] = cat['subscription_product'] == null;
    }
    return result;
  }

  /// Categories sorted by most recent activity, untouched last.
  /// Untouched categories follow the licences-screen convention: subscribed
  /// first, then alphabetical.
  List<String> get _sortedCategories {
    final cache = BcdCache.instance;

    // Map category name → is_subscribed (from the top-level category entry).
    final subscribedByName = <String, bool>{};
    for (final cat in cache.categories) {
      final name = stripAppSuffix(cat['name']?.toString() ?? '');
      subscribedByName[name] = cat['is_subscribed'] == true;
    }

    DateTime? latestFor(String catName) => _allEntries
        .where((e) => e.categoryName == catName)
        .map((e) => _lastActivityDates[e.testBcdId])
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (best, d) => best == null || d.isAfter(best) ? d : best);

    return [..._distinctCategories]..sort((a, b) {
        final dateA = latestFor(a);
        final dateB = latestFor(b);
        if (dateA == null && dateB == null) {
          // Subscribed first, then alphabetical — mirrors sortSubscribedCategoriesFirst.
          final aSubscribed = subscribedByName[a] ?? false;
          final bSubscribed = subscribedByName[b] ?? false;
          if (aSubscribed != bSubscribed) return aSubscribed ? -1 : 1;
          return a.compareTo(b);
        }
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        final cmp = dateB.compareTo(dateA);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
  }

  /// True when this screen should show category cards instead of test cards.
  bool get _showCategoryLevel =>
      widget.categoryFilter == null && _distinctCategories.length > 1;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    final scopeTitle = widget.categoryFilter ?? t.smart_learning_subtitle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          scopeTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _allEntries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.smart_no_exams,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _showCategoryLevel
                  ? _buildCategoryList(context)
                  : _buildTestList(context),
            ),
    );
  }

  // ── Category list ──────────────────────────────────────────────────────────

  Widget _buildCategoryList(BuildContext context) {
    final categories = _sortedCategories;
    final isFreeMap = _categoryIsFree;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: categories.asMap().entries.map((entry) {
                final catName = entry.value;
                final catEntries = _allEntries
                    .where((e) => e.categoryName == catName)
                    .toList();
                final totalChunks = catEntries.fold<int>(
                    0, (sum, e) => sum + e.chunkSizes.length);
                final passedChunks = catEntries.fold<int>(
                    0, (sum, e) => sum + (_passedCounts[e.testBcdId] ?? 0));
                final isLast = entry.key == categories.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CategoryRow(
                      name: catName,
                      isFree: isFreeMap[catName] ?? false,
                      testCount: catEntries.length,
                      passedChunks: passedChunks,
                      totalChunks: totalChunks,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => SmartLearningScreen(
                              examBcdId: widget.examBcdId,
                              categoryFilter: catName,
                              initialPassedCounts: _passedCounts,
                              initialActivityDates: _lastActivityDates,
                            ),
                          ),
                        );
                        _load();
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.onSurface.withValues(alpha: 0.07),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Test list ──────────────────────────────────────────────────────────────

  Widget _buildTestList(BuildContext context) {
    final entries = _filteredEntries;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        if (_categoryWeakCount > 0) ...[
          _CategoryMistakesCard(
            count: _categoryWeakCount,
            onTap: () async {
              await Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => SmartCategoryMistakesScreen(
                    categoryName: widget.categoryFilter ?? '',
                    entries: entries,
                  ),
                ),
              );
              _load();
            },
          ),
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: entries.asMap().entries.map((e) {
                final isLast = e.key == entries.length - 1;
                final entry = e.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ExamRow(
                      entry: entry,
                      passedCount: _passedCounts[entry.testBcdId] ?? 0,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => SmartExamScreen(entry: entry),
                          ),
                        );
                        _load();
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.onSurface.withValues(alpha: 0.07),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category row (Focus-Areas style) ─────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String name;
  final bool isFree;
  final int testCount;
  final int passedChunks;
  final int totalChunks;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.name,
    required this.isFree,
    required this.testCount,
    required this.passedChunks,
    required this.totalChunks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final color = categoryColor(name);
    final allDone = passedChunks >= totalChunks && totalChunks > 0;
    final examLabel =
        testCount == 1 ? t.smart_category_exam : t.smart_category_exams;

    final sub = allDone
        ? t.smart_category_completed(count: testCount, examLabel: examLabel)
        : passedChunks == 0
            ? t.smart_category_not_started(
                count: testCount, examLabel: examLabel)
            : t.smart_category_parts_done(
                count: testCount,
                examLabel: examLabel,
                done: passedChunks,
                total: totalChunks,
              );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon(name), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isFree) ...[
                          _FreeBadge(color: cs.primary),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(sub,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Free badge ────────────────────────────────────────────────────────────────

class _FreeBadge extends StatelessWidget {
  final Color color;
  const _FreeBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        t.bcd_free_label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Category mistakes card ────────────────────────────────────────────────────

class _CategoryMistakesCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CategoryMistakesCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final questionLabel =
        count == 1 ? t.smart_category_question : t.smart_category_questions;
    return Material(
      color: cs.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.smart_mistakes_title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.error, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        t.smart_category_mistakes_subtitle(
                          count: count,
                          questionLabel: questionLabel,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.error.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.error.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Exam row (Focus-Areas style) ──────────────────────────────────────────────

class _ExamRow extends StatelessWidget {
  final SmartExamEntry entry;
  final int passedCount;
  final VoidCallback onTap;

  const _ExamRow({
    required this.entry,
    required this.passedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = entry.chunkSizes.length;
    final allDone = passedCount >= total;
    final color =
        allDone ? Colors.green.shade600 : categoryColor(entry.testName);

    final statusLabel = allDone
        ? t.smart_full_exam_ready
        : passedCount == 0
            ? t.smart_not_started
            : t.smart_chunks_done(done: passedCount, total: total);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allDone
                      ? Icons.check_circle_rounded
                      : categoryIcon(entry.testName),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.testName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: allDone
                                ? Colors.green.shade600
                                : cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
