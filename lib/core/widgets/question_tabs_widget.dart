import 'package:cached_network_image/cached_network_image.dart';
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

  /// Builds a flat list of all images across every tab, with parallel lists
  /// of per-image titles and plain-text bodies for the gallery viewer.
  _GalleryData _buildGalleryData() {
    final images = <String>[];
    final titles = <String>[];
    final texts = <String>[];

    for (final tab in widget.tabs) {
      final embedded = _extractImgSrcs(tab.text);
      final tabImages = [...tab.images, ...embedded];
      final plainText = _parseTabText(tab.text);
      final tabLabel = tab.title;

      for (final url in tabImages) {
        images.add(url);
        titles.add(tabLabel);
        texts.add(plainText);
      }
    }

    return _GalleryData(images: images, titles: titles, texts: texts);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final gallery = _buildGalleryData();

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
                .map((tab) => Tab(
                    text: tab.title.isNotEmpty
                        ? tab.title
                        : t.question_tab_label))
                .toList(),
          ),
        SizedBox(
          height: 280,
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs
                .map((tab) => _buildTabContent(tab, gallery))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(QuestionTab tab, _GalleryData gallery) {
    final embeddedImages = _extractImgSrcs(tab.text);
    final tabImages = [...tab.images, ...embeddedImages];
    final plainText = _parseTabText(tab.text);
    final hasText = plainText.isNotEmpty;
    final hasImages = tabImages.isNotEmpty;

    if (!hasText && !hasImages) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasText)
            Text(
              plainText,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          if (hasImages) ...[
            if (hasText) const SizedBox(height: 8),
            // Tapping any thumbnail opens the combined gallery (all tabs),
            // starting at the tapped image. Title + text update as you swipe.
            if (tabImages.length == 1)
              _buildImage(tabImages.first, gallery, tab)
            else
              SizedBox(
                height: 220,
                child: PageView(
                  children: tabImages
                      .map((url) => _buildImage(url, gallery, tab))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<String> _extractImgSrcs(String html) {
    final imgRegex =
        RegExp(r'''<img[^>]+src=['"]([^'"]+)['"]''', caseSensitive: false);
    return imgRegex
        .allMatches(html)
        .map((m) => m.group(1) ?? '')
        .where((src) => src.isNotEmpty)
        .toList();
  }

  String _parseTabText(String raw) {
    if (raw.trim().isEmpty) return '';
    // Replace <br> variants with newlines before stripping tags
    String text =
        raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // Strip all HTML tags (including <img>)
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Decode HTML entities
    text = _decodeEntities(text);
    // Collapse multiple blank lines / whitespace-only lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return text;
  }

  String _decodeEntities(String s) {
    s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)));
    const map = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&auml;': 'ä',
      '&Auml;': 'Ä',
      '&ouml;': 'ö',
      '&Ouml;': 'Ö',
      '&aring;': 'å',
      '&Aring;': 'Å',
      '&eacute;': 'é',
      '&egrave;': 'è',
      '&aacute;': 'á',
      '&agrave;': 'à',
      '&uuml;': 'ü',
      '&Uuml;': 'Ü',
      '&mdash;': '—',
      '&ndash;': '–',
      '&hellip;': '…',
      '&laquo;': '«',
      '&raquo;': '»',
      '&copy;': '©',
    };
    for (final e in map.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s;
  }

  Widget _buildImage(String url, _GalleryData gallery, QuestionTab tab) {
    final globalIndex = gallery.images.indexOf(url);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => showImageViewer(
          context,
          gallery.images,
          initialIndex: globalIndex < 0 ? 0 : globalIndex,
          titles:
              gallery.titles.any((t) => t.isNotEmpty) ? gallery.titles : null,
          tabTexts:
              gallery.texts.any((t) => t.isNotEmpty) ? gallery.texts : null,
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(child: AppLoadingIndicator()),
          errorWidget: (_, __, ___) => Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 32,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 6),
                  Text(
                    'Bild ej tillgänglig',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryData {
  final List<String> images;
  final List<String> titles;
  final List<String> texts;

  const _GalleryData({
    required this.images,
    required this.titles,
    required this.texts,
  });
}
