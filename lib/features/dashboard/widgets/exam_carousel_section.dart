import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/bcd/bcd_traffic_signs_screen.dart';
import 'package:taxi_exam_app/features/profile/providers/profile_provider.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';
import 'exam_card.dart';
import 'free_bcd_hub_card.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * _kViewportFraction;
        final height = cardWidth * 756 / 1654;
        return Shimmer.fromColors(
          baseColor: isDark
              ? cs.onSurface.withValues(alpha: 0.12)
              : cs.onSurface.withValues(alpha: 0.08),
          highlightColor: isDark
              ? cs.onSurface.withValues(alpha: 0.06)
              : cs.onSurface.withValues(alpha: 0.03),
          child: SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: _kLeftPad),
              itemCount: _count,
              separatorBuilder: (_, __) => const SizedBox(width: _kCardSpacing),
              itemBuilder: (_, __) => SizedBox(
                width: cardWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Maximum width of the carousel container — prevents over-stretching on tablets/web.
const double _kCarouselMaxWidth = 580;
// Each card occupies this fraction of the viewport so adjacent cards peek.
const double _kViewportFraction = 0.84;
// Side cards shrink to this scale; centre card is always 1.0.
const double _kSideScale = 0.86;

class _ExamCarouselSectionState extends State<ExamCarouselSection> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _kViewportFraction)
      ..addListener(() {
        setState(() => _currentPage = _pageController.page ?? 0);
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final statsCache = provider.statsCache;
    final exams = List.of(provider.exams);

    // Find the "active" exam: the one with the most recent attempt.
    SubscribedExam? activeExam;
    DateTime? latestDate;
    for (final e in exams) {
      final d = statsCache[e.id]?.lastAttemptDate;
      if (d != null && (latestDate == null || d.isAfter(latestDate))) {
        latestDate = d;
        activeExam = e;
      }
    }

    final activeId = activeExam?.id;
    exams.sort((a, b) {
      if (activeId != null) {
        if (a.id == activeId) return -1;
        if (b.id == activeId) return 1;
      }
      final attA = statsCache[a.id]?.totalAttempts ?? 0;
      final attB = statsCache[b.id]?.totalAttempts ?? 0;
      return attB.compareTo(attA);
    });
    final t = Translations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                const FreeBcdHubCard(),
                const SizedBox(height: 12),
                FreeVagmarkesCard(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const BCDTrafficSignsScreen()),
                  ),
                ),
                if (!ProfileProvider().isGuest) ...[
                  const SizedBox(height: 12),
                  SubscribeCtaCard(onSubscribe: widget.onSubscribe),
                ],
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kCarouselMaxWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Derive height from the centre card's width so the image
                  // aspect ratio (1654 × 756) is always respected.
                  final centerCardWidth =
                      constraints.maxWidth * _kViewportFraction;
                  final carouselHeight = centerCardWidth * 756 / 1654;
                  return SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      clipBehavior: Clip.none,
                      itemCount: exams.length,
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        context
                            .read<DashboardProvider>()
                            .selectExam(exams[index]);
                      },
                      itemBuilder: (context, i) {
                        final rawDistance = (_currentPage - i).abs();
                        final distance = rawDistance.clamp(0.0, 1.0);
                        final scale = _kSideScale +
                            (1.0 - _kSideScale) * (1.0 - distance);
                        final opacity = (1.4 - rawDistance).clamp(0.0, 1.0);
                        final exam = exams[i];
                        final isSelected = exam.id == provider.selectedExam?.id;
                        final bcdId = int.tryParse(exam.id);
                        final endDate = bcdId != null
                            ? BcdCache.instance.endDateFor(bcdId)
                            : null;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            context.read<DashboardProvider>().selectExam(exam);
                          },
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: _kLeftPad / 2),
                                child: ExamCard(
                                  exam: exam,
                                  isActive: isSelected,
                                  endDate: endDate,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
