import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_subscriptions_screen.dart';

class _ExamTopic {
  final IconData icon;
  final Color color;
  const _ExamTopic(this.icon, this.color);
}

/// Maps a category name to a visual icon+color.
/// Keyword matching — falls back to a generic icon.
_ExamTopic _topicForName(String name) {
  final n = name.toLowerCase();

  // ── Specific Swedish exam names ───────────────────────────────────────────
  // Motorcykel
  if (n.contains('motorcykel') || n.contains('motorcycle') || n.contains('moped')) {
    return const _ExamTopic(Icons.two_wheeler_rounded,      Color(0xFFE67E22));
  }
  // YKB Buss / buss
  if (n.contains('buss') || n.contains('bus')) {
    return const _ExamTopic(Icons.directions_bus_rounded,   Color(0xFF2779BC));
  }
  // YKB Lastbil / lastbil / truck
  if (n.contains('lastbil') || n.contains('truck') || n.contains('ykb')) {
    return const _ExamTopic(Icons.local_shipping_rounded,   Color(0xFF8E44AD));
  }
  // Gods åkeri — cargo haulage business
  if (n.contains('åkeri') || n.contains('gods') || n.contains('cargo') || n.contains('haulage')) {
    return const _ExamTopic(Icons.business_center_rounded,  Color(0xFF16A085));
  }
  // Vägmärkestest — road signs test
  if (n.contains('vägmärke') || n.contains('road sign') || n.contains('traffic sign') || n.contains('skylt')) {
    return const _ExamTopic(Icons.signpost_rounded,         Color(0xFFE74C3C));
  }
  // B-körkort / car licence
  if (n.contains('körkort') || n.contains('b-kör') || n.contains('licence') || n.contains('license')) {
    return const _ExamTopic(Icons.directions_car_rounded,   Color(0xFF00A86B));
  }

  // ── Generic fallbacks ─────────────────────────────────────────────────────
  if (n.contains('taxi')) {
    return const _ExamTopic(Icons.local_taxi_rounded,       Color(0xFFF39C12));
  }
  if (n.contains('teori') || n.contains('theory') || n.contains('rule') || n.contains('regel')) {
    return const _ExamTopic(Icons.menu_book_rounded,        Color(0xFF6B4EFF));
  }
  if (n.contains('passager') || n.contains('passenger') || n.contains('säkerhet') || n.contains('safety')) {
    return const _ExamTopic(Icons.people_rounded,           Color(0xFFE67E22));
  }
  if (n.contains('miljö') || n.contains('environment') || n.contains('eco')) {
    return const _ExamTopic(Icons.eco_rounded,              Color(0xFF27AE60));
  }
  return const _ExamTopic(Icons.quiz_rounded,               Color(0xFF546E7A));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 3; // pages 0,1,2 = questions; page 3 = recommendations

  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Categories — shown on step 0 with icons, reused for recommendations
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  // Step 0 — selected category indices
  final Set<int> _selectedIndices = {};

  // Step 1 — exam date
  DateTime? _examDeadline;
  _DateOption? _selectedDateOption;

  // Step 2 — practice days
  int _practiceDaysPerWeek = 3;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesInBackground();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoriesInBackground() async {
    try {
      final raw = await ApiService().fetchBCDAllCategories();
      if (mounted) {
        setState(() {
          _categories = raw.whereType<Map<String, dynamic>>().toList();
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _saveAndExit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (_examDeadline != null) {
        await prefs.setString('exam_deadline', _examDeadline!.toIso8601String());
      }
      await prefs.setInt('practice_days_per_week', _practiceDaysPerWeek);
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushReplacement(
        AppPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndExit();
    }
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _examDeadline = picked;
        _selectedDateOption = _DateOption.custom;
      });
    }
  }

  List<Map<String, dynamic>> get _recommendedCategories =>
      _categories.where((c) => c['is_subscribed'] != true).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onClose: _saveAndExit,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _ExamTopicsPage(
                    categories: _categories,
                    loading: _loadingCategories,
                    selectedIndices: _selectedIndices,
                    onToggle: (i) => setState(() {
                      _selectedIndices.contains(i)
                          ? _selectedIndices.remove(i)
                          : _selectedIndices.add(i);
                    }),
                    onNext: _goNext,
                  ),
                  _ExamDatePage(
                    selected: _selectedDateOption,
                    deadline: _examDeadline,
                    onSelect: (opt, date) => setState(() {
                      _selectedDateOption = opt;
                      _examDeadline = date;
                    }),
                    onCustom: _pickCustomDate,
                    onBack: _goBack,
                    onNext: _goNext,
                  ),
                  _PracticeDaysPage(
                    days: _practiceDaysPerWeek,
                    onChanged: (d) => setState(() => _practiceDaysPerWeek = d),
                    onBack: _goBack,
                    onNext: _goNext,
                  ),
                  _RecommendationsPage(
                    recommended: _recommendedCategories,
                    onSubscribe: (_) {
                      Navigator.of(context).push(
                        AppPageRoute(
                            builder: (_) => const BCDSubscriptionsScreen()),
                      );
                    },
                    onGetStarted: _saveAndExit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: currentStep < totalSteps
                ? Row(
                    children: List.generate(totalSteps, (i) {
                      final active = i == currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? primary
                              : primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  )
                : Text(
                    Translations.of(context).onb_recommendations_title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            tooltip: Translations.of(context).cancel,
          ),
        ],
      ),
    );
  }
}

// ─── Step 0: Visual exam topics (from API, mapped to icons) ──────────────────

class _ExamTopicsPage extends StatelessWidget {
  const _ExamTopicsPage({
    required this.categories,
    required this.loading,
    required this.selectedIndices,
    required this.onToggle,
    required this.onNext,
  });

  final List<Map<String, dynamic>> categories;
  final bool loading;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;
  final VoidCallback onNext;

  static const _kGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.35,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.onb_which_exams,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onb_select_all_apply,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: loading
                ? _TopicShimmer(delegate: _kGridDelegate)
                : categories.isEmpty
                    ? Center(child: Text(t.onb_no_exams))
                    : GridView.builder(
                        gridDelegate: _kGridDelegate,
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final name = categories[i]['name']?.toString() ?? '';
                          return _TopicTile(
                            name: name,
                            topic: _topicForName(name),
                            selected: selectedIndices.contains(i),
                            onTap: () => onToggle(i),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: t.onb_continue, onPressed: onNext),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.name,
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final _ExamTopic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? topic.color.withValues(alpha: isDark ? 0.25 : 0.14)
              : topic.color.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? topic.color : topic.color.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Check badge
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: topic.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                ),
              ),
            // Icon + label
            Align(
              alignment: Alignment.center,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: topic.color.withValues(alpha: selected ? 0.22 : (isDark ? 0.2 : 0.12)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(topic.icon, color: topic.color, size: 24),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? topic.color : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicShimmer extends StatelessWidget {
  const _TopicShimmer({required this.delegate});

  final SliverGridDelegate delegate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: delegate,
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Exam date ────────────────────────────────────────────────────────

enum _DateOption {
  oneWeek,
  twoWeeks,
  threeWeeks,
  oneMonth,
  twoMonths,
  threeMonths,
  custom,
}

class _ExamDatePage extends StatelessWidget {
  const _ExamDatePage({
    required this.selected,
    required this.deadline,
    required this.onSelect,
    required this.onCustom,
    required this.onBack,
    required this.onNext,
  });

  final _DateOption? selected;
  final DateTime? deadline;
  final void Function(_DateOption, DateTime) onSelect;
  final VoidCallback onCustom;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    final options = [
      _QuickOption(t.onb_1_week, _DateOption.oneWeek,
          now.add(const Duration(days: 7))),
      _QuickOption(t.onb_2_weeks, _DateOption.twoWeeks,
          now.add(const Duration(days: 14))),
      _QuickOption(t.onb_3_weeks, _DateOption.threeWeeks,
          now.add(const Duration(days: 21))),
      _QuickOption(t.onb_1_month, _DateOption.oneMonth,
          DateTime(now.year, now.month + 1, now.day)),
      _QuickOption(t.onb_2_months, _DateOption.twoMonths,
          DateTime(now.year, now.month + 2, now.day)),
      _QuickOption(t.onb_3_months, _DateOption.threeMonths,
          DateTime(now.year, now.month + 3, now.day)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.onb_exam_date_title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onb_exam_date_subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final opt in options)
                        _QuickDateTile(
                          label: opt.label,
                          isSelected: selected == opt.option,
                          onTap: () => onSelect(opt.option, opt.date),
                        ),
                      _QuickDateTile(
                        label: selected == _DateOption.custom &&
                                deadline != null
                            ? _formatDate(deadline!)
                            : t.onb_custom_date,
                        isSelected: selected == _DateOption.custom,
                        icon: Icons.calendar_month_rounded,
                        onTap: onCustom,
                      ),
                    ],
                  ),
                  if (deadline != null && selected != null) ...[
                    const SizedBox(height: 24),
                    _DeadlinePreview(deadline: deadline!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NavButtons(
            onBack: onBack,
            onNext: deadline != null ? onNext : null,
            nextLabel: t.onb_continue,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _QuickOption {
  final String label;
  final _DateOption option;
  final DateTime date;
  const _QuickOption(this.label, this.option, this.date);
}

class _QuickDateTile extends StatelessWidget {
  const _QuickDateTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlinePreview extends StatelessWidget {
  const _DeadlinePreview({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deadline.day}/${deadline.month}/${deadline.year}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                Translations.of(context).dash_days_remaining(n: daysLeft),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Practice days ────────────────────────────────────────────────────

class _PracticeDaysPage extends StatelessWidget {
  const _PracticeDaysPage({
    required this.days,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  final int days;
  final ValueChanged<int> onChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.onb_practice_days_title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onb_practice_days_subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = i + 1;
              final selected = d == days;
              return GestureDetector(
                onTap: () => onChanged(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? primary : theme.dividerColor,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$d',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
              child: Text(t.onb_days_week_label(n: days)),
            ),
          ),
          const Spacer(),
          _NavButtons(
            onBack: onBack,
            onNext: onNext,
            nextLabel: t.onb_continue,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Step 3: Recommendations ──────────────────────────────────────────────────

class _RecommendationsPage extends StatelessWidget {
  const _RecommendationsPage({
    required this.recommended,
    required this.onSubscribe,
    required this.onGetStarted,
  });

  final List<Map<String, dynamic>> recommended;
  final ValueChanged<Map<String, dynamic>> onSubscribe;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.onb_recommendations_title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onb_recommendations_subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: recommended.isEmpty
                ? Center(
                    child: Text(
                      t.onb_no_exams,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: recommended.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final cat = recommended[i];
                      final name = cat['name']?.toString() ?? '';
                      return _RecommendationCard(
                        name: name,
                        onSubscribe: () => onSubscribe(cat),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: t.onb_get_started, onPressed: onGetStarted),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.name,
    required this.onSubscribe,
  });

  final String name;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onSubscribe,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              Translations.of(context).onb_subscribe,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared button widgets ────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NextButton(label: nextLabel, onPressed: onNext),
        ),
      ],
    );
  }
}
