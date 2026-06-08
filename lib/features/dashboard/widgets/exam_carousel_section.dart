import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import '../models/dashboard_stats.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';
import 'exam_card.dart';
import 'free_vagmarkes_card.dart';
import 'subscribe_cta_card.dart';

class ExamCarouselSection extends StatefulWidget {
  const ExamCarouselSection({
    super.key,
    required this.provider,
    required this.onSubscribe,
  });

  final DashboardProvider provider;
  final VoidCallback onSubscribe;

  @override
  State<ExamCarouselSection> createState() => _ExamCarouselSectionState();
}

// Image asset dimensions: 1654 × 756 — card height matches this ratio.
const double _kCardWidth = 260;
const double _kCardHeight = _kCardWidth * 756 / 1654; // ≈ 119
const double _kCardSpacing = 12;
const double _kLeftPad = 16;

class _ExamCarouselShimmer extends StatelessWidget {
  static const int _count = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fill = theme.brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : cs.surfaceContainerHighest.withValues(alpha: 0.75);
    return SizedBox(
      height: _kCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _kLeftPad),
        itemCount: _count,
        separatorBuilder: (_, __) => const SizedBox(width: _kCardSpacing),
        itemBuilder: (_, __) => SizedBox(
          width: _kCardWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCarouselSectionState extends State<ExamCarouselSection> {
  final ScrollController _scrollController = ScrollController();

  // Cached sorted list — only recomputed when exams/statsCache identity changes.
  List<SubscribedExam> _sortedExams = [];
  List<SubscribedExam>? _lastExams;
  Map<String, ExamDashboardStats>? _lastStatsCache;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _snapCardIntoView(int index) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final target = (index * (_kCardWidth + _kCardSpacing))
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<SubscribedExam> _computeSortedExams(
    List<SubscribedExam> exams,
    Map<String, ExamDashboardStats> statsCache,
  ) {
    final sorted = List.of(exams);
    SubscribedExam? activeExam;
    DateTime? latestDate;
    for (final e in sorted) {
      final d = statsCache[e.id]?.lastAttemptDate;
      if (d != null && (latestDate == null || d.isAfter(latestDate))) {
        latestDate = d;
        activeExam = e;
      }
    }
    final activeId = activeExam?.id;
    sorted.sort((a, b) {
      if (activeId != null) {
        if (a.id == activeId) return -1;
        if (b.id == activeId) return 1;
      }
      final attA = statsCache[a.id]?.totalAttempts ?? 0;
      final attB = statsCache[b.id]?.totalAttempts ?? 0;
      return attB.compareTo(attA);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final statsCache = provider.statsCache;
    final rawExams = provider.exams;

    // Only re-sort when the underlying data actually changes.
    if (!identical(_lastExams, rawExams) ||
        !identical(_lastStatsCache, statsCache)) {
      _lastExams = rawExams;
      _lastStatsCache = statsCache;
      _sortedExams = _computeSortedExams(rawExams, statsCache);
    }
    final exams = _sortedExams;
    final t = Translations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            t.dash_my_exams,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (exams.isEmpty &&
            (provider.status == DashboardStatus.loading ||
                provider.status == DashboardStatus.idle)) ...[
          _ExamCarouselShimmer(),
        ] else if (exams.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FreeVagmarkesCard(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) =>
                            const SmartLearningScreen(examBcdId: null)),
                  ),
                ),
                const SizedBox(height: 12),
                SubscribeCtaCard(onSubscribe: widget.onSubscribe),
              ],
            ),
          ),
        ] else if (exams.length == 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kLeftPad),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: AspectRatio(
                aspectRatio: 1654 / 756,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<DashboardProvider>().selectExam(exams[0]);
                  },
                  child: ExamCard(
                    exam: exams[0],
                    isActive: true,
                    endDate: () {
                      final bcdId = int.tryParse(exams[0].id);
                      return bcdId != null
                          ? BcdCache.instance.endDateFor(bcdId)
                          : null;
                    }(),
                  ),
                ),
              ),
            ),
          ),
        ] else
          SizedBox(
            height: _kCardHeight,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kLeftPad),
              itemCount: exams.length,
              itemBuilder: (context, i) {
                final exam = exams[i];
                final isSelected = exam.id == provider.selectedExam?.id;
                final bcdId = int.tryParse(exam.id);
                final endDate =
                    bcdId != null ? BcdCache.instance.endDateFor(bcdId) : null;

                return Padding(
                  padding: EdgeInsets.only(
                      right: i < exams.length - 1 ? _kCardSpacing : 0),
                  child: SizedBox(
                    width: _kCardWidth,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<DashboardProvider>().selectExam(exam);
                        if (!isSelected) _snapCardIntoView(i);
                      },
                      child: ExamCard(
                        exam: exam,
                        isActive: isSelected,
                        endDate: endDate,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
