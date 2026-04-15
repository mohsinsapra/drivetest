import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../models/dashboard_stats.dart';

class WeeklyStreakCard extends StatelessWidget {
  const WeeklyStreakCard({super.key, required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final today = DateTime.now();
    final monday =
        DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: today.weekday - 1));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top streak numbers
          Row(
            children: [
              _StreakStat(
                value: '${streak.currentStreak}',
                label: t.dash_streak_current,
                icon: '🔥',
                primary: true,
              ),
              const SizedBox(width: 16),
              _StreakStat(
                value: '${streak.bestStreak}',
                label: t.dash_streak_best,
                icon: '🏆',
              ),
              const Spacer(),
              // Weekly goal progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${streak.thisWeekActiveDayCount}/${streak.weeklyGoal}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    t.dash_streak_weekly_goal,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (streak.thisWeekActiveDayCount /
                                streak.weeklyGoal)
                            .clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: cs.onSurface.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day-of-week calendar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              final isActive = streak.isActiveDay(day);
              final isToday = _isSameDay(day, today);
              final isFuture = day.isAfter(today);
              final dayLabel = _dayLabel(day.weekday, t);

              return _DayDot(
                label: dayLabel,
                isActive: isActive,
                isToday: isToday,
                isFuture: isFuture,
              );
            }),
          ),
          const SizedBox(height: 12),

          // Insight message
          _StreakInsight(streak: streak),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(int weekday, Translations t) {
    switch (weekday) {
      case 1: return t.dash_day_mon;
      case 2: return t.dash_day_tue;
      case 3: return t.dash_day_wed;
      case 4: return t.dash_day_thu;
      case 5: return t.dash_day_fri;
      case 6: return t.dash_day_sat;
      case 7: return t.dash_day_sun;
      default: return '';
    }
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.value,
    required this.label,
    required this.icon,
    this.primary = false,
  });
  final String value;
  final String label;
  final String icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: primary ? cs.primary : null,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
  });
  final String label;
  final bool isActive;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color dotColor;
    if (isFuture) {
      dotColor = cs.onSurface.withOpacity(0.12);
    } else if (isActive) {
      dotColor = cs.primary;
    } else {
      dotColor = cs.onSurface.withOpacity(0.18);
    }

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isToday
                    ? cs.primary
                    : cs.onSurface.withOpacity(0.5),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: isToday
                ? Border.all(color: cs.primary, width: 2)
                : null,
          ),
          child: isActive
              ? Icon(Icons.check_rounded,
                  size: 14, color: cs.onPrimary)
              : null,
        ),
      ],
    );
  }
}

class _StreakInsight extends StatelessWidget {
  const _StreakInsight({required this.streak});
  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final message = _insightMessage(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _insightMessage(Translations t) {
    final curr = streak.currentStreak;
    final goal = streak.weeklyGoal;
    final done = streak.thisWeekActiveDayCount;
    if (curr == 0) return t.dash_streak_msg_none;
    if (curr >= 7) return t.dash_streak_msg_amazing.replaceAll('{n}', '$curr');
    if (done >= goal) return t.dash_streak_msg_goal;
    final left = goal - done;
    if (left == 1) {
      return t.dash_streak_msg_progress_one.replaceAll('{n}', '$curr');
    }
    return t.dash_streak_msg_progress_other
        .replaceAll('{n}', '$curr')
        .replaceAll('{left}', '$left');
  }
}
