import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/widgets/app_shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'bcd_text_utils.dart';

// ── List screen ────────────────────────────────────────────────────────────────

class BCDTrafficSignsScreen extends StatefulWidget {
  const BCDTrafficSignsScreen({super.key});

  @override
  State<BCDTrafficSignsScreen> createState() => _BCDTrafficSignsScreenState();
}

class _BCDTrafficSignsScreenState extends State<BCDTrafficSignsScreen> {
  final _provider = BcdProvider();
  final _scrollController = ScrollController();
  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;
  String _search = '';
  Timer? _refreshTimer;

  static const _autoRefreshInterval = Duration(hours: 1);

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _provider.signs;
    final q = _search.toLowerCase();
    return _provider.signs.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final content = (s['content'] ?? '').toString().toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (AppStorage.allowScreenshots()) {
      _noScreenshot?.screenshotOn();
    } else {
      _noScreenshot?.screenshotOff();
    }
    _provider.addListener(_onProviderChange);
    _load();
    _refreshTimer = Timer.periodic(
        _autoRefreshInterval, (_) => _provider.refreshTrafficSignsSilently());
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      await _provider.loadTrafficSigns();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_traffic_signs,
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(Translations.of(context).bcd_traffic_signs),
        elevation: 0,
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: _provider.loadTrafficSigns,
        controller: _scrollController,
        slivers: [
          // Search bar scrolls with the list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: Translations.of(context).bcd_search_signs,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          if (_provider.signsLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _Shimmer(),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  Translations.of(context).bcd_no_signs,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              sliver: SliverList.builder(
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => RepaintBoundary(
                  child: _SignGroupCard(
                    sign: filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => _SignGroupDetailScreen(
                          group: filtered[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Group card ─────────────────────────────────────────────────────────────────

class _SignGroupCard extends StatefulWidget {
  final dynamic sign;
  final VoidCallback onTap;
  const _SignGroupCard({required this.sign, required this.onTap});

  @override
  State<_SignGroupCard> createState() => _SignGroupCardState();
}

class _SignGroupCardState extends State<_SignGroupCard> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final onTap = widget.onTap;
    final cs = Theme.of(context).colorScheme;
    final title = cleanBcdText(sign['title']?.toString() ?? '');
    final content = cleanBcdText(sign['content']?.toString() ?? '');
    final images = (sign['images'] as List<dynamic>? ?? []);
    final children = (sign['children'] as List<dynamic>? ?? []);
    final signCount = children.isNotEmpty ? children.length : images.length;

    // Collect up to 3 preview image URLs
    final previewUrls = <String>[];
    for (final img in images.take(3)) {
      final fn = img['file_name']?.toString() ?? '';
      if (fn.isNotEmpty) previewUrls.add(BcdProvider().mediaUrl(fn));
    }
    if (previewUrls.isEmpty) {
      for (final child in children.take(3)) {
        final childImgs = (child['images'] as List<dynamic>? ?? []);
        if (childImgs.isNotEmpty) {
          final fn = childImgs.first['file_name']?.toString() ?? '';
          if (fn.isNotEmpty) previewUrls.add(BcdProvider().mediaUrl(fn));
        }
      }
    }

    // All preview URLs for the group (used to open the full-screen viewer)
    final allPreviewUrls = <String>[];
    for (final img in images) {
      final fn = img['file_name']?.toString() ?? '';
      if (fn.isNotEmpty) allPreviewUrls.add(BcdProvider().mediaUrl(fn));
    }
    if (allPreviewUrls.isEmpty) {
      for (final child in children) {
        for (final img in (child['images'] as List<dynamic>? ?? [])) {
          final fn = img['file_name']?.toString() ?? '';
          if (fn.isNotEmpty) allPreviewUrls.add(BcdProvider().mediaUrl(fn));
        }
      }
    }

    Widget imageArea;
    if (previewUrls.isEmpty) {
      imageArea = Container(
        height: 120,
        width: double.infinity,
        color: Theme.of(context).cardColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imageOff,
                size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(Translations.of(context).bcd_no_image,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      );
    } else if (previewUrls.length == 1) {
      imageArea = GestureDetector(
        onTap: allPreviewUrls.isNotEmpty
            ? () => showImageViewer(context, allPreviewUrls, titles: [title])
            : null,
        child: Container(
          width: double.infinity,
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(24),
          child: CachedNetworkImage(
            imageUrl: previewUrls[0],
            fit: BoxFit.contain,
            memCacheHeight: 360,
            errorWidget: (_, __, ___) => Icon(LucideIcons.imageOff,
                size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          ),
        ),
      );
    } else {
      imageArea = GestureDetector(
        onTap: allPreviewUrls.isNotEmpty
            ? () => showImageViewer(context, allPreviewUrls,
                initialIndex: _currentPage,
                titles: List.filled(allPreviewUrls.length, title))
            : null,
        child: _ImageSlider(
          urls: previewUrls,
          controller: _pageController,
          currentPage: _currentPage,
          onPageChanged: (i) => setState(() => _currentPage = i),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area — outer GestureDetector opens viewer; inner PageView handles swipe
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imageArea,
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.07)),
          // Text content — tap navigates into the group
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content.length > 110
                          ? '${content.substring(0, 110)}…'
                          : content,
                      style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          height: 1.45),
                    ),
                  ],
                  if (signCount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.alertTriangle,
                            size: 13,
                            color: cs.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(width: 5),
                        Text(
                          '$signCount ${Translations.of(context).bcd_signs_count_label}',
                          style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Translations.of(context).bcd_view,
                                  style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 3),
                              Icon(LucideIcons.chevronRight,
                                  size: 13, color: cs.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern image slider with dots
class _ImageSlider extends StatelessWidget {
  final List<String> urls;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  const _ImageSlider({
    required this.urls,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 180,
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: PageView.builder(
                controller: controller,
                itemCount: urls.length,
                onPageChanged: onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: urls[i],
                  fit: BoxFit.contain,
                  memCacheHeight: 360,
                  errorWidget: (_, __, ___) => Icon(LucideIcons.image,
                      size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                ),
              )),
        ),
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(urls.length, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      active ? cs.primary : cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Detail screen ──────────────────────────────────────────────────────────────

class _SignGroupDetailScreen extends StatefulWidget {
  final dynamic group;
  const _SignGroupDetailScreen({required this.group});

  @override
  State<_SignGroupDetailScreen> createState() => _SignGroupDetailScreenState();
}

class _SignGroupDetailScreenState extends State<_SignGroupDetailScreen> {
  late final List<dynamic> _slides;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final children = (widget.group['children'] as List<dynamic>? ?? []);
    _slides = children.isNotEmpty ? children : [widget.group];
  }

  int get _total => _slides.length;
  dynamic get _current => _slides[_index];

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < _total - 1) setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final groupTitle = cleanBcdText(widget.group['title']?.toString() ?? '');
    final title = cleanBcdText(_current['title']?.toString() ?? '');
    final content = cleanBcdText(_current['content']?.toString() ?? '');
    final images = (_current['images'] as List<dynamic>? ?? []);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -200) _next();
          if (d.primaryVelocity! > 200) _prev();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupTitle,
                  style: GoogleFonts.lexend(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              if (_total > 1)
                Text('${_index + 1} / $_total',
                    style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                        fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Progress bar
            if (_total > 1)
              LinearProgressIndicator(
                value: (_index + 1) / _total,
                minHeight: 2,
                backgroundColor: Theme.of(context).dividerColor,
                color: Theme.of(context).colorScheme.primary,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign code / title card
                    if (title.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(title,
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ),
                    const SizedBox(height: 12),
                    // Image viewer card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _NavArrow(
                            icon: LucideIcons.chevronLeft,
                            enabled: _index > 0,
                            onTap: _prev,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 230,
                              child: images.isEmpty
                                  ? Center(
                                      child: Icon(LucideIcons.alertTriangle,
                                          size: 64,
                                          color: Colors.grey.shade300))
                                  : _SignImageViewer(images: images),
                            ),
                          ),
                          _NavArrow(
                            icon: LucideIcons.chevronRight,
                            enabled: _index < _total - 1,
                            onTap: _next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description card
                    if (content.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(content,
                            style: GoogleFonts.lexend(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.75),
                                height: 1.6)),
                      ),
                    const SizedBox(height: 24),
                    // Prev / Next buttons at bottom
                    if (_total > 1)
                      Row(
                        children: [
                          Expanded(
                            child: _BottomNavButton(
                              label: Translations.of(context).bcd_previous,
                              icon: LucideIcons.chevronLeft,
                              enabled: _index > 0,
                              onTap: _prev,
                              isLeading: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BottomNavButton(
                              label: Translations.of(context).bcd_next,
                              icon: LucideIcons.chevronRight,
                              enabled: _index < _total - 1,
                              onTap: _next,
                              isLeading: false,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Icon(icon,
            size: 22,
            color: enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.15)),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLeading;
  const _BottomNavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor =
        isLeading ? cs.onSurface.withValues(alpha: 0.7) : cs.primary;
    final disabledColor = cs.onSurface.withValues(alpha: 0.25);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).cardColor
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLeading
              ? [
                  Icon(icon,
                      size: 16, color: enabled ? activeColor : disabledColor),
                  const SizedBox(width: 6),
                  Text(label,
                      style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: enabled ? activeColor : disabledColor)),
                ]
              : [
                  Text(label,
                      style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: enabled ? activeColor : disabledColor)),
                  const SizedBox(width: 6),
                  Icon(icon,
                      size: 16, color: enabled ? activeColor : disabledColor),
                ],
        ),
      ),
    );
  }
}

class _SignImageViewer extends StatefulWidget {
  final List<dynamic> images;
  const _SignImageViewer({required this.images});

  @override
  State<_SignImageViewer> createState() => _SignImageViewerState();
}

class _SignImageViewerState extends State<_SignImageViewer> {
  int _page = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urls = widget.images
        .map((img) =>
            ApiService().bcdMediaUrl(img['file_name']?.toString() ?? ''))
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      return Center(
          child: Icon(LucideIcons.alertTriangle,
              size: 64, color: cs.onSurface.withValues(alpha: 0.2)));
    }

    return GestureDetector(
      onTap: () => showImageViewer(context, urls, initialIndex: _page),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.all(20),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Icon(LucideIcons.image,
                    size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
              ),
            ),
          ),
          // Tap-to-expand hint + page dots
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (urls.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(urls.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.maximize2,
                        size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 4),
                    Text(
                      Translations.of(context).bcd_tap_to_zoom,
                      style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
