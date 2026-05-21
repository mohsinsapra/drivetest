import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import '../models/dashboard_stats.dart';
import 'batch_row.dart';
import 'category_list_item.dart';
import 'exam_nav_helpers.dart';

class FocusCategoriesSection extends StatefulWidget {
  const FocusCategoriesSection({super.key, required this.stats});

  final ExamDashboardStats stats;

  @override
  State<FocusCategoriesSection> createState() =>
      _FocusCategoriesSectionState();
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
    if (cats != null && cats.isNotEmpty) {
      _expanded.add(cats.first.node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    if (stats.categoryStats != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: stats.categoryStats!.asMap().entries.map((entry) {
            final cat = entry.value;
            final isExpanded = _expanded.contains(cat.node.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CategoryListItem(
                cat: cat,
                icon: categoryIcon(cat.node.name),
                color: categoryColor(cat.node.name),
                isExpanded: isExpanded,
                onToggle: () => setState(() {
                  if (isExpanded) {
                    _expanded.remove(cat.node.id);
                  } else {
                    _expanded.add(cat.node.id);
                  }
                }),
                stats: stats,
              ),
            );
          }).toList(),
        ),
      );
    }

    // 2-layer exam: show batches directly using precomputed sortedAttempts.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: stats.allBatchStats
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < stats.allBatchStats.length - 1 ? 8 : 0,
                  ),
                  child: BatchRow(
                    batch: e.value,
                    exam: stats.exam,
                    batchAttempts: e.value.sortedAttempts,
                    onTap: stats.exam.isBcd
                        ? () => launchBatch(
                            context, stats.exam, e.value.node, null)
                        : null,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
