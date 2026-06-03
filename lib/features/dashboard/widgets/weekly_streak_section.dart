import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import 'streak_stat_label.dart';

class WeeklyStreakSection extends StatefulWidget {
  const WeeklyStreakSection({super.key, required this.streak});

  final StreakSummary streak;

  @override
  State<WeeklyStreakSection> createState() => _WeeklyStreakSectionState();
}

class _WeeklyStreakSectionState extends State<WeeklyStreakSection> {
  late final DateTime _now;
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    final monday = DateTime(_now.year, _now.month, _now.day)
        .subtract(Duration(days: _now.weekday - 1));
    _days = List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streak;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = Translations.of(context);
    final now = _now;
    final days = _days;
    final dayLabels = [
      t.dash_day_mon,
      t.dash_day_tue,
      t.dash_day_wed,
      t.dash_day_thu,
      t.dash_day_fri,
      t.dash_day_sat,
      t.dash_day_sun,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : cs.inverseSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t.dash_streak_title.replaceAll(
                            '{n}',
                            '${streak.currentStreak}',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? cs.onSurface : cs.onInverseSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StreakStatLabel(
                        label: t.dash_streak_current,
                        value: t.dash_streak_days.replaceAll(
                          '{n}',
                          '${streak.currentStreak}',
                        ),
                        valueColor: isDark ? cs.onSurface : cs.onInverseSurface,
                        labelColor: isDark ? cs.onSurface : cs.onInverseSurface,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: cs.onSurface.withValues(alpha: 0.12),
                      ),
                      StreakStatLabel(
                        label: t.dash_streak_best,
                        value: t.dash_streak_days.replaceAll(
                          '{n}',
                          '${streak.bestStreak}',
                        ),
                        valueColor: isDark ? cs.onSurface : cs.onInverseSurface,
                        labelColor: isDark ? cs.onSurface : cs.onInverseSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RepaintBoundary(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final day = days[i];
                  final isActive = streak.isActiveDay(day);
                  final isToday = day.year == now.year &&
                      day.month == now.month &&
                      day.day == now.day;
                  final isFuture = day.isAfter(now);

                  return Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: isActive
                                  ? 30
                                  : (isToday && !isFuture ? 12 : 0),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.amber
                                    : Colors.amber.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            color: isToday
                                ? Colors.amber
                                : isDark
                                    ? cs.onSurface
                                    : cs.onInverseSurface
                                        .withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
