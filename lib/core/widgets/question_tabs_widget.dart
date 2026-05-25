import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';

class QuestionTabsWidget extends StatefulWidget {
  final List<QuestionTab> tabs;

  const QuestionTabsWidget({super.key, required this.tabs});

  @override
  State<QuestionTabsWidget> createState() => _QuestionTabsWidgetState();
}

class _QuestionTabsWidgetState extends State<QuestionTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabs.length > 1)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: colorScheme.primary,
            tabs: widget.tabs
                .map((tab) => Tab(text: tab.title.isNotEmpty ? tab.title : t.question_tab_label))
                .toList(),
          ),
        SizedBox(
          height: 260,
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map(_buildTabContent).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(QuestionTab tab) {
    final images = tab.images;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    if (images.length == 1) {
      return _buildImage(images.first);
    }
    return PageView(
      children: images.map(_buildImage).toList(),
    );
  }

  Widget _buildImage(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => showImageViewer(context, url),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(child: AppLoadingIndicator()),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
