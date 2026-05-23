import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../models/dashboard_stats.dart';
import 'streak_stat_label.dart';

class WeeklyStreakSection extends StatelessWidget {
  const WeeklyStreakSection({super.key, required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = Translations.of(context);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : cs.inverseSurface,
          borderRadius: BorderRadius.circular(28),
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
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.dash_streak_title.replaceAll(
                            '{n}',
                            '${streak.currentStreak}',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? cs.onSurface : cs.onInverseSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(width: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = days[i];
                final isActive = streak.isActiveDay(day);
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                final isFuture = day.isAfter(now);

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height:
                                isActive ? 40 : (isToday && !isFuture ? 18 : 0),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.amber
                                  : Colors.amber.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          color: isToday
                              ? Colors.amber
                              : isDark
                                  ? cs.onSurface
                                  : cs.onInverseSurface.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
