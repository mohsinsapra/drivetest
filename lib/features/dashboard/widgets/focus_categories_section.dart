import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import '../models/dashboard_stats.dart';
import 'category_list_item.dart';

/// Renders the category accordion for 3-layer exams.
/// 2-layer exams (flat batches) are handled via SliverList.builder in DashboardBody.
class FocusCategoriesSection extends StatefulWidget {
  const FocusCategoriesSection({super.key, required this.stats});

  final ExamDashboardStats stats;

  @override
  State<FocusCategoriesSection> createState() => _FocusCategoriesSectionState();
}

class _FocusCategoriesSectionState extends State<FocusCategoriesSection> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _resetExpanded(widget.stats);
  }

  @override
  void didUpdateWidget(FocusCategoriesSection old) {
    super.didUpdateWidget(old);
    if (old.stats.exam.id != widget.stats.exam.id) {
      _expanded.clear();
      _resetExpanded(widget.stats);
    }
  }

  void _resetExpanded(ExamDashboardStats stats) {
    final cats = stats.categoryStats;
    if (cats == null || cats.isEmpty) return;

    DateTime? latestDate(CategoryStats cat) => cat.batchStats
        .map((b) => b.lastAttemptDate)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (best, d) => best == null || d.isAfter(best) ? d : best);

    CategoryStats? mostRecent;
    DateTime? bestDate;
    for (final cat in cats) {
      final d = latestDate(cat);
      if (d != null && (bestDate == null || d.isAfter(bestDate))) {
        bestDate = d;
        mostRecent = cat;
      }
    }

    _expanded.add((mostRecent ?? cats.first).node.id);
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.stats.categoryStats!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (cats.length == 1) {
      final cat = cats.first;
      final isExpanded = _expanded.contains(cat.node.id);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CategoryListItem(
          cat: cat,
          icon: categoryIcon(cat.node.name),
          isExpanded: isExpanded,
          onToggle: () => setState(() {
            if (isExpanded) {
              _expanded.remove(cat.node.id);
            } else {
              _expanded.add(cat.node.id);
            }
          }),
          stats: widget.stats,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: cats.asMap().entries.map((entry) {
              final cat = entry.value;
              final isLast = entry.key == cats.length - 1;
              final isExpanded = _expanded.contains(cat.node.id);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryListItem(
                    cat: cat,
                    icon: categoryIcon(cat.node.name),
                    isExpanded: isExpanded,
                    onToggle: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(cat.node.id);
                      } else {
                        _expanded.add(cat.node.id);
                      }
                    }),
                    stats: widget.stats,
                    nested: true,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.onSurface.withValues(alpha: 0.07),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
