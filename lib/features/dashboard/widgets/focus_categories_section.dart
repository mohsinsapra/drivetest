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
    if (cats != null && cats.isNotEmpty) {
      _expanded.add(cats.first.node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.stats.categoryStats!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: cats.asMap().entries.map((entry) {
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
              stats: widget.stats,
            ),
          );
        }).toList(),
      ),
    );
  }
}
