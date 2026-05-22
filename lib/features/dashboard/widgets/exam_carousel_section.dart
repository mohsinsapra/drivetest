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
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.onSurface.withValues(alpha: 0.12)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.06)
          : cs.onSurface.withValues(alpha: 0.03),
      child: SizedBox(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCarouselSectionState extends State<ExamCarouselSection> {
  @override
  Widget build(BuildContext context) {
    final exams = widget.provider.exams;
    final provider = widget.provider;
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
          SizedBox(
            height: _kCardHeight,
            child: ListView.builder(
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
