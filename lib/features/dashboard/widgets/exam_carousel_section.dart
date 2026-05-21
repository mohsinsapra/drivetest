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
import 'exam_nav_helpers.dart';
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

class _ExamCarouselShimmer extends StatelessWidget {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCarouselSectionState extends State<ExamCarouselSection> {
  static const double _cardSpacing = 12;
  static const double _leftPad = 16;
  static const double _cardWidth = 220;

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
                    AppPageRoute(
                        builder: (_) => const BCDTrafficSignsScreen()),
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
            padding: const EdgeInsets.symmetric(horizontal: _leftPad),
            child: SizedBox(
              height: 190,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<DashboardProvider>().selectExam(exams[0]);
                },
                child: ExamCard(
                  exam: exams[0],
                  progress: provider.overviewProgress[exams[0].id] ?? 0.0,
                  isActive: true,
                  endDate: () {
                    final bcdId = int.tryParse(exams[0].id);
                    return bcdId != null
                        ? BcdCache.instance.endDateFor(bcdId)
                        : null;
                  }(),
                  onArrowTap: () => handleExamArrowTap(
                    context,
                    exams[0],
                    provider,
                  ),
                ),
              ),
            ),
          ),
        ] else
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: _leftPad),
              itemCount: exams.length,
              itemBuilder: (context, i) {
                final exam = exams[i];
                final isSelected =
                    exam.id == provider.selectedExam?.id;
                final progress =
                    provider.overviewProgress[exam.id] ?? 0.0;
                final bcdId = int.tryParse(exam.id);
                final endDate = bcdId != null
                    ? BcdCache.instance.endDateFor(bcdId)
                    : null;

                return Padding(
                  padding: EdgeInsets.only(
                      right:
                          i < exams.length - 1 ? _cardSpacing : 0),
                  child: SizedBox(
                    width: _cardWidth,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context
                            .read<DashboardProvider>()
                            .selectExam(exam);
                      },
                      child: ExamCard(
                        exam: exam,
                        progress: progress,
                        isActive: isSelected,
                        endDate: endDate,
                        onArrowTap: () => handleExamArrowTap(
                          context,
                          exam,
                          provider,
                        ),
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
