import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

/// Shows the exam deadline set during onboarding.
/// The user can tap the edit icon to change the deadline at any time.
class ExamDeadlineCard extends StatefulWidget {
  const ExamDeadlineCard({super.key});

  @override
  State<ExamDeadlineCard> createState() => _ExamDeadlineCardState();
}

class _ExamDeadlineCardState extends State<ExamDeadlineCard> {
  DateTime? _deadline;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeadline();
  }

  Future<void> _loadDeadline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('exam_deadline');
      if (raw != null) {
        setState(() {
          _deadline = DateTime.tryParse(raw);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _editDeadline() async {
    final now = DateTime.now();
    final initial = _deadline != null && _deadline!.isAfter(now)
        ? _deadline!
        : now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );

    if (picked != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('exam_deadline', picked.toIso8601String());
      } catch (_) {}
      if (mounted) setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final t = Translations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (_deadline == null) {
      return _NoDeadlineBanner(
        label: t.dash_no_deadline,
        buttonLabel: t.dash_set_deadline,
        onTap: _editDeadline,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_deadline!.year, _deadline!.month, _deadline!.day);
    final daysLeft = target.difference(today).inDays;

    final String statusLabel;
    final Color statusColor;
    final double progress;

    if (daysLeft < 0) {
      statusLabel = t.dash_deadline_passed;
      statusColor = Colors.red;
      progress = 1.0;
    } else if (daysLeft == 0) {
      statusLabel = t.dash_deadline_today;
      statusColor = Colors.orange;
      progress = 1.0;
    } else {
      statusLabel = t.dash_days_remaining.replaceAll('{n}', '$daysLeft');
      statusColor = primary;
      // Assume a max planning horizon of 180 days for the progress bar
      const maxDays = 180;
      progress = 1.0 - (daysLeft / maxDays).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dash_exam_deadline,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}  ·  $statusLabel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editDeadline,
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    tooltip: t.dash_change_deadline,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: theme.dividerColor,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDeadlineBanner extends StatelessWidget {
  const _NoDeadlineBanner({
    required this.label,
    required this.buttonLabel,
    required this.onTap,
  });

  final String label;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.flag_outlined,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Text(
                buttonLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
