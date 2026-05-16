import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/streak_notification_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/streak/streak_settings_provider.dart';

class StreakSettingsScreen extends StatefulWidget {
  const StreakSettingsScreen({super.key});

  @override
  State<StreakSettingsScreen> createState() => _StreakSettingsScreenState();
}

class _StreakSettingsScreenState extends State<StreakSettingsScreen> {
  late DateTime? _examDeadline;
  late Set<int> _selectedWeekdays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StreakSettingsProvider>();
    _examDeadline = provider.examDeadline;
    _selectedWeekdays = Set.from(provider.practiceWeekdays);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDeadline != null && _examDeadline!.isAfter(now)
          ? _examDeadline!
          : now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _examDeadline = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await StreakNotificationService.requestPermission();
      if (!mounted) return;
      await context.read<StreakSettingsProvider>().update(
            examDeadline: _examDeadline,
            practiceWeekdays: _selectedWeekdays,
          );
      if (!mounted) return;
      showAppSnackBar(t.sg_settings_saved, type: SnackBarType.success);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.sg_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
                label: t.sg_section_exam_date, icon: Icons.flag_rounded),
            const SizedBox(height: 12),
            _ExamDeadlineSection(
              examDeadline: _examDeadline,
              onCustomDate: _pickCustomDate,
              onPreset: (date) => setState(() => _examDeadline = date),
            ),
            const SizedBox(height: 32),
            _SectionLabel(
                label: t.sg_section_practice_days,
                icon: Icons.flash_on_rounded),
            const SizedBox(height: 4),
            Text(
              t.sg_practice_days_sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _WeekdayPicker(
              selected: _selectedWeekdays,
              onToggle: (day) => setState(() {
                if (_selectedWeekdays.contains(day)) {
                  if (_selectedWeekdays.length > 1) {
                    _selectedWeekdays = Set.from(_selectedWeekdays)
                      ..remove(day);
                  }
                } else {
                  _selectedWeekdays = Set.from(_selectedWeekdays)..add(day);
                }
              }),
            ),
            const SizedBox(height: 8),
            Text(
              t.sg_days_per_week.replaceAll(
                '{n}',
                '${_selectedWeekdays.length}',
              ),
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor: cs.primary.withValues(alpha: 0.3),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        t.sg_save,
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const _NotificationNote(),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

// ─── Exam deadline section ─────────────────────────────────────────────────────

class _ExamDeadlineSection extends StatelessWidget {
  const _ExamDeadlineSection({
    required this.examDeadline,
    required this.onCustomDate,
    required this.onPreset,
  });

  final DateTime? examDeadline;
  final VoidCallback onCustomDate;
  final ValueChanged<DateTime> onPreset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final presets = [
      (label: '3', date: DateTime(now.year, now.month + 3, now.day)),
      (label: '6', date: DateTime(now.year, now.month + 6, now.day)),
      (label: '12', date: DateTime(now.year, now.month + 12, now.day)),
    ];

    final isCustom = examDeadline != null &&
        !presets.any((p) => _sameDay(p.date, examDeadline!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < presets.length; i++) ...[
              Expanded(
                child: _PresetCard(
                  number: presets[i].label,
                  sub: t.sg_months,
                  selected: examDeadline != null &&
                      _sameDay(presets[i].date, examDeadline!),
                  onTap: () => onPreset(presets[i].date),
                ),
              ),
              if (i < presets.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onCustomDate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isCustom
                  ? cs.primaryContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: isCustom ? Border.all(color: cs.primary, width: 2) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: isCustom ? cs.primary : cs.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  isCustom && examDeadline != null
                      ? '${examDeadline!.day}/${examDeadline!.month}/${examDeadline!.year}'
                      : t.sg_custom_date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCustom ? cs.primary : cs.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (examDeadline != null) ...[
          const SizedBox(height: 12),
          _DeadlineBanner(deadline: examDeadline!),
        ],
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.number,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String number;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.2)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.lexend(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: selected ? cs.primary : cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: selected ? cs.primary : cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineBanner extends StatelessWidget {
  const _DeadlineBanner({required this.deadline});
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deadline.day}/${deadline.month}/${deadline.year}',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                daysLeft > 0
                    ? t.sg_days_remaining.replaceAll('{n}', '$daysLeft')
                    : t.sg_deadline_passed,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Weekday picker ────────────────────────────────────────────────────────────

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final isSelected = selected.contains(i);
          final cs = Theme.of(context).colorScheme;
          return GestureDetector(
            onTap: () => onToggle(i),
            child: Column(
              children: [
                Text(
                  _labels[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.outline,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                    border: isSelected
                        ? null
                        : Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? cs.onPrimary : cs.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Notification note ─────────────────────────────────────────────────────────

class _NotificationNote extends StatelessWidget {
  const _NotificationNote();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined,
              size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.sg_notif_note,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
